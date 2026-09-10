#!/usr/bin/env python3
"""Fetch the complete Qur'an from Quran.com API v4 into Shared/Resources/quran.json.

Arabic: Uthmani script (text_uthmani). Translation: Saheeh International
(resource 20) with <sup> footnote markers stripped, HTML tags removed,
entities unescaped and whitespace collapsed, exactly as verses.json and
ruqyah.json were produced. Nothing here is typed by hand.

The script verifies the payload against the canonical structure of the
mushaf and against the already frozen Shared/Resources/verses.json, and
refuses to write the output file if any check fails.
"""
import datetime
import html
import json
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Shared" / "Resources" / "quran.json"
FROZEN = ROOT / "Shared" / "Resources" / "verses.json"
API = "https://api.quran.com/api/v4"
PAUSE = 0.1
PER_PAGE = 50
TRANSLATION_ID = 20  # Saheeh International

SURAH_COUNT = 114
AYAH_COUNT = 6236
PAGE_COUNT = 604
JUZ_COUNT = 30

SUP = re.compile(r"<sup[^>]*>.*?</sup>", re.S)
TAGS = re.compile(r"<[^>]+>")
WS = re.compile(r"\s+")


def get(url, attempts=6):
    """GET JSON with retry/backoff on 429, 5xx and network errors."""
    for attempt in range(attempts):
        try:
            req = urllib.request.Request(
                url,
                headers={"User-Agent": "yaqeen-quran-fetch/1.0", "Accept": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            time.sleep(PAUSE)
            return data
        except urllib.error.HTTPError as err:
            if err.code == 429 or 500 <= err.code < 600:
                wait = 2.0 * (attempt + 1)
                print(f"  HTTP {err.code} for {url}; retry {attempt + 1}/{attempts} in {wait:.0f}s", file=sys.stderr)
                time.sleep(wait)
                continue
            raise SystemExit(f"HTTP {err.code} for {url}: {err}")
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, ConnectionError) as err:
            wait = 2.0 * (attempt + 1)
            print(f"  retry {attempt + 1}/{attempts} for {url}: {err} (sleeping {wait:.0f}s)", file=sys.stderr)
            time.sleep(wait)
    raise SystemExit(f"gave up on {url}")


def clean_translation(raw):
    text = SUP.sub("", raw)
    text = TAGS.sub("", text)
    text = html.unescape(text)
    return WS.sub(" ", text).strip()


def fetch_chapters():
    chapters = get(f"{API}/chapters?language=en")["chapters"]
    surahs = []
    for c in chapters:
        place = c["revelation_place"]
        if place not in ("makkah", "madinah"):
            raise SystemExit(f"unexpected revelation_place {place!r} for chapter {c['id']}")
        surahs.append({
            "n": c["id"],
            "ar": c["name_arabic"],
            "en": c["name_simple"],
            "tr": c["translated_name"]["name"],
            "place": place,
            "count": c["verses_count"],
            "bismillah": bool(c["bismillah_pre"]),
        })
    return surahs


def fetch_chapter_ayat(n):
    ayat = []
    page = 1
    while True:
        url = (f"{API}/verses/by_chapter/{n}?fields=text_uthmani&translations={TRANSLATION_ID}"
               f"&per_page={PER_PAGE}&page={page}")
        data = get(url)
        for v in data["verses"]:
            key = v["verse_key"]
            surah, number = (int(x) for x in key.split(":"))
            if surah != n or number != v["verse_number"]:
                raise SystemExit(f"verse key {key} disagrees with chapter {n} / verse_number {v['verse_number']}")
            translations = [t for t in v.get("translations", []) if t.get("resource_id") == TRANSLATION_ID]
            if len(translations) != 1:
                raise SystemExit(f"expected exactly one Saheeh International text for {key}, got {len(translations)}")
            ayat.append({
                "k": key,
                "s": surah,
                "a": number,
                # Stored verbatim. The API emits a leading space on most
                # surah-opening ayat (after the basmalah); verses.json kept it,
                # so we keep it too rather than transform the Arabic.
                "t": v["text_uthmani"],
                "tr": clean_translation(translations[0]["text"]),
                "p": v["page_number"],
                "j": v["juz_number"],
            })
        if data["pagination"]["next_page"] is None:
            break
        page = data["pagination"]["next_page"]
    return ayat


def fail(msg):
    print(f"FAIL: {msg}")
    return 1


def verify(surahs, ayat):
    failures = 0
    print("\n== verification ==")

    # Chapters
    if len(surahs) != SURAH_COUNT:
        failures += fail(f"{len(surahs)} chapters, expected {SURAH_COUNT}")
    if [s["n"] for s in surahs] != list(range(1, SURAH_COUNT + 1)):
        failures += fail("chapter numbers are not 1...114 in order")
    for s in surahs:
        expected = s["n"] not in (1, 9)
        if s["bismillah"] != expected:
            failures += fail(f"bismillah_pre for surah {s['n']} is {s['bismillah']}, expected {expected}")
        for field in ("ar", "en", "tr"):
            if not s[field].strip():
                failures += fail(f"surah {s['n']} has empty {field}")
    print(f"chapters: {len(surahs)}; bismillah_pre false only for {[s['n'] for s in surahs if not s['bismillah']]}")

    # Per-chapter counts and contiguous numbering
    by_surah = {}
    for a in ayat:
        by_surah.setdefault(a["s"], []).append(a)
    for s in surahs:
        got = by_surah.get(s["n"], [])
        if len(got) != s["count"]:
            failures += fail(f"surah {s['n']} has {len(got)} ayat, verses_count says {s['count']}")
        if [a["a"] for a in got] != list(range(1, s["count"] + 1)):
            failures += fail(f"surah {s['n']} verse numbers are not contiguous 1...{s['count']}")
    if len(ayat) != AYAH_COUNT:
        failures += fail(f"{len(ayat)} ayat, expected {AYAH_COUNT}")
    print(f"ayat: {len(ayat)}")

    # Mushaf order and unique keys
    keys = [a["k"] for a in ayat]
    if len(set(keys)) != len(keys):
        failures += fail("duplicate ayah keys")
    order = [(a["s"], a["a"]) for a in ayat]
    if order != sorted(order):
        failures += fail("ayat are not in mushaf order")
    for a in ayat:
        if a["k"] != f"{a['s']}:{a['a']}":
            failures += fail(f"key {a['k']} disagrees with s/a fields")

    # Pages
    pages = [a["p"] for a in ayat]
    if any(b < a for a, b in zip(pages, pages[1:])):
        failures += fail("page numbers decrease somewhere")
    if min(pages) != 1 or max(pages) != PAGE_COUNT:
        failures += fail(f"page range {min(pages)}...{max(pages)}, expected 1...{PAGE_COUNT}")
    missing_pages = sorted(set(range(1, PAGE_COUNT + 1)) - set(pages))
    if missing_pages:
        failures += fail(f"missing pages: {missing_pages}")
    print(f"pages: {min(pages)}...{max(pages)}, {len(set(pages))} distinct, non-decreasing")

    # Juz
    juz = [a["j"] for a in ayat]
    if any(b < a for a, b in zip(juz, juz[1:])):
        failures += fail("juz numbers decrease somewhere")
    if min(juz) != 1 or max(juz) != JUZ_COUNT:
        failures += fail(f"juz range {min(juz)}...{max(juz)}, expected 1...{JUZ_COUNT}")
    missing_juz = sorted(set(range(1, JUZ_COUNT + 1)) - set(juz))
    if missing_juz:
        failures += fail(f"missing juz: {missing_juz}")
    juz_starts = {}
    for a in ayat:
        juz_starts.setdefault(a["j"], a["k"])
    if juz_starts.get(2) != "2:142":
        failures += fail(f"juz 2 starts at {juz_starts.get(2)}, expected 2:142")
    if juz_starts.get(30) != "78:1":
        failures += fail(f"juz 30 starts at {juz_starts.get(30)}, expected 78:1")
    print(f"juz: {min(juz)}...{max(juz)}, {len(set(juz))} distinct, non-decreasing; juz 2 starts {juz_starts.get(2)}, juz 30 starts {juz_starts.get(30)}")

    # Text
    for a in ayat:
        if not a["t"].strip():
            failures += fail(f"empty Arabic in {a['k']}")
        if not a["tr"].strip():
            failures += fail(f"empty translation in {a['k']}")
        if "<" in a["tr"] or ">" in a["tr"]:
            failures += fail(f"HTML remains in translation of {a['k']}: {a['tr']!r}")
        if re.search(r"&[a-zA-Z#0-9]+;", a["tr"]):
            failures += fail(f"HTML entity remains in translation of {a['k']}: {a['tr']!r}")
        if "\n" in a["t"] or "\n" in a["tr"]:
            failures += fail(f"newline inside text of {a['k']}")
    print("text: no empty Arabic/translation, no residual HTML")

    leading = [a["k"] for a in ayat if a["t"] != a["t"].lstrip()]
    trailing = [a["k"] for a in ayat if a["t"] != a["t"].rstrip()]
    print(f"leading space kept verbatim on {len(leading)} ayat "
          f"(all surah-opening: {all(k.endswith(':1') for k in leading)}); trailing whitespace on {len(trailing)}")
    if any(not k.endswith(":1") for k in leading) or trailing:
        failures += fail(f"unexpected whitespace: leading {[k for k in leading if not k.endswith(':1')]}, trailing {trailing}")

    # Known openings. The API orders combining marks canonically (shadda
    # U+0651 before fatha U+064E) while the literal check strings below carry
    # fatha before shadda; the two are canonically equivalent, so compare under
    # NFD exactly as fetch_ruqyah.py does. The Arabic itself is never normalised.
    by_key = {a["k"]: a for a in ayat}
    for key, prefix in (("1:1", "\u0628\u0650\u0633\u0652\u0645\u0650 \u0671\u0644\u0644\u064e\u0651\u0647\u0650"),
                        ("2:255", "\u0671\u0644\u0644\u064e\u0651\u0647\u064f \u0644\u064e\u0622 \u0625\u0650\u0644\u064e\u0640\u0670\u0647\u064e")):
        got = by_key.get(key, {}).get("t", "")
        if got.startswith(prefix):
            print(f"{key} starts with {prefix!r}: OK (raw bytes)")
        elif unicodedata.normalize("NFD", got).startswith(unicodedata.normalize("NFD", prefix)):
            print(f"{key} starts with {prefix!r}: OK under NFD only "
                  f"(combining-mark order differs from the check string; data left untouched)")
        else:
            failures += fail(f"{key} does not start with {prefix!r}: {got[:20]!r}")

    # Frozen verses.json: byte-for-byte on arabic and translation
    frozen = json.loads(FROZEN.read_text(encoding="utf-8"))["verses"]
    mismatches = 0
    for v in frozen:
        a = by_key.get(v["key"])
        if a is None:
            failures += fail(f"verses.json key {v['key']} is missing from the full Qur'an")
            continue
        for field, mine in (("arabic", "t"), ("translation", "tr")):
            if v[field] != a[mine]:
                mismatches += 1
                nfc_same = unicodedata.normalize("NFC", v[field]) == unicodedata.normalize("NFC", a[mine])
                nfd_same = unicodedata.normalize("NFD", v[field]) == unicodedata.normalize("NFD", a[mine])
                note = " (identical under Unicode normalisation only)" if (nfc_same or nfd_same) else ""
                failures += fail(f"{v['key']} {field} differs from verses.json{note}\n"
                                 f"    verses.json: {v[field]!r}\n"
                                 f"    quran.json : {a[mine]!r}")
    print(f"verses.json: {len(frozen)} ayat compared, {mismatches} mismatches")

    return failures


def main():
    print("fetching chapters")
    surahs = fetch_chapters()
    if len(surahs) != SURAH_COUNT:
        raise SystemExit(f"{len(surahs)} chapters returned, expected {SURAH_COUNT}")

    ayat = []
    for s in surahs:
        chapter_ayat = fetch_chapter_ayat(s["n"])
        print(f"{s['n']:>3} {s['en']:<16} {len(chapter_ayat):>3}/{s['count']:<3} ayat")
        ayat.extend(chapter_ayat)

    failures = verify(surahs, ayat)
    if failures:
        print(f"\n{failures} check(s) failed; {OUT} NOT written")
        raise SystemExit(1)

    payload = {
        "source": ("Quran.com API v4. Arabic: Uthmani script (text_uthmani). "
                   "Translation: Saheeh International (resource 20); HTML footnote markers removed for display."),
        "fetched": datetime.date.today().isoformat(),
        "surahs": surahs,
        "ayat": ayat,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    size = OUT.stat().st_size
    print(f"\nall checks passed; wrote {OUT} ({size:,} bytes, {size / 1024 / 1024:.2f} MiB)")
    print(f"1:1   -> {ayat[0]['t'][:15]!r}")
    by_key = {a["k"]: a for a in ayat}
    print(f"2:255 -> {by_key['2:255']['t'][:15]!r}")


if __name__ == "__main__":
    main()
