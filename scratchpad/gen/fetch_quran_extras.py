#!/usr/bin/env python3
"""Fetch the alternate scripts and extra English translations from Quran.com API v4.

Writes two files next to quran.json:

  Shared/Resources/quran-scripts.json
      {"source", "fetched", "ayat": [{"k": "1:1", "tj": text_uthmani_tajweed, "ip": text_indopak}]}
      `tj` is kept exactly as the API returns it (with <tajweed class=…> spans and
      the <span class=end>N</span> ayah marker); only runs of whitespace are collapsed.
      `ip` is kept as returned with edge whitespace trimmed.

  Shared/Resources/translations.json
      {"source", "fetched", "editions": [{"id", "name", "author", "language"}],
       "ayat": [{"k": "1:1", "t": {"85": "…", …}}]}
      Footnote markers and HTML tags are removed, entities unescaped and
      whitespace collapsed, exactly as fetch_quran.py does for Saheeh International.

Nothing here is typed by hand. Every ayah is verified against the frozen
Shared/Resources/quran.json (same 6236 keys in the same order, and the tajweed
text with its markup removed equals the Uthmani text) before anything is written.

Helpers (get, clean_translation) are copied from fetch_quran.py.
"""
import datetime
import html
import json
import os
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.request
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QURAN = ROOT / "Shared" / "Resources" / "quran.json"
OUT_SCRIPTS = ROOT / "Shared" / "Resources" / "quran-scripts.json"
OUT_TRANSLATIONS = ROOT / "Shared" / "Resources" / "translations.json"
API = "https://api.quran.com/api/v4"
PAUSE = 0.1
PER_PAGE = 50
SURAH_COUNT = 114
AYAH_COUNT = 6236

# English editions wanted, in display order, as (expected id, name fragments that
# must all appear in name+author, case-insensitively). Saheeh International (20)
# already lives in quran.json and is not fetched here.
WANTED = [
    (85, ("haleem",), "Abdul Haleem"),
    (22, ("yusuf ali",), "Yusuf Ali"),
    (19, ("pickthall",), "Pickthall"),
    (203, ("hilali", "khan"), "Hilali & Khan"),
    (84, ("taqi usmani",), "Mufti Taqi Usmani"),
    (95, ("maududi",), "Maududi, Tafhim al-Qur'an"),
    (149, ("bridges",), "Fadel Soliman, Bridges' translation"),
    (54, ("junagarhi",), "Maulana Muhammad Junagarhi (Urdu)"),
]

SUP = re.compile(r"<sup[^>]*>.*?</sup>", re.S)
TAGS = re.compile(r"<[^>]+>")
WS = re.compile(r"\s+")
END_MARK = re.compile(r"<span class=end>[^<]*</span>")
TAJWEED_CLASS = re.compile(r"<tajweed class=([^>]+)>")
# Arabic combining marks, tatweel and the small/quranic annotation letters: what is
# left after removing these is the base rasm, used to separate a genuine text
# mismatch from a different choice of glyph for the same word.
MARKS = re.compile("[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640\u08D3-\u08FF]")


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


STRAY_ANGLES = Counter()

def clean_translation(raw):
    text = SUP.sub("", raw)
    text = TAGS.sub("", text)
    text = html.unescape(text)
    # A handful of Quran.com strings carry a stray '>' from a broken tag.
    if "<" in text or ">" in text:
        STRAY_ANGLES["stray"] += 1
        text = text.replace("<", "").replace(">", "")
    return WS.sub(" ", text).strip()


def resolve_editions():
    """Match the wanted editions by name against the API's resource list."""
    resources = get(f"{API}/resources/translations")["translations"]
    english = resources
    print(f"resources/translations: {len(resources)} total")
    editions = []
    for expected_id, fragments, label in WANTED:
        hits = [r for r in english
                if all(f in (r["name"] + " " + r["author_name"]).lower() for f in fragments)]
        exact = [r for r in hits if r["id"] == expected_id]
        if exact:
            hits = exact
        if not hits:
            print(f"  MISSING {label}: no resource name/author contains {fragments}; expected id {expected_id} "
                  f"{'exists' if any(r['id'] == expected_id for r in resources) else 'is not served'} — skipped")
            continue
        if len(hits) > 1:
            raise SystemExit(f"{label}: ambiguous match {[(r['id'], r['name']) for r in hits]}")
        r = hits[0]
        note = "" if r["id"] == expected_id else f"  (expected id {expected_id}, using {r['id']} which matches the name)"
        print(f"  {r['id']:>4} {r['name']} — {r['author_name']} [{r['language_name']}]{note}")
        editions.append({"id": r["id"], "name": r["name"], "author": r["author_name"], "language": r["language_name"]})
    if not editions:
        raise SystemExit("no editions resolved")
    return editions


def fetch_chapter(n, ids):
    """One chapter: scripts and translations from the same paginated request."""
    scripts, translations = [], []
    page = 1
    while True:
        url = (f"{API}/verses/by_chapter/{n}?fields=text_uthmani_tajweed,text_indopak"
               f"&translations={','.join(str(i) for i in ids)}&per_page={PER_PAGE}&page={page}")
        data = get(url)
        for v in data["verses"]:
            key = v["verse_key"]
            surah, number = (int(x) for x in key.split(":"))
            if surah != n or number != v["verse_number"]:
                raise SystemExit(f"verse key {key} disagrees with chapter {n} / verse_number {v['verse_number']}")
            scripts.append({
                "k": key,
                "tj": WS.sub(" ", v["text_uthmani_tajweed"]).strip(),
                "ip": v["text_indopak"].strip(),
            })
            texts = {}
            for t in v.get("translations", []):
                rid = t.get("resource_id")
                if rid not in ids:
                    raise SystemExit(f"{key}: unexpected translation resource {rid}")
                if str(rid) in texts:
                    raise SystemExit(f"{key}: resource {rid} returned twice")
                texts[str(rid)] = clean_translation(t["text"])
            translations.append({"k": key, "t": texts})
        if data["pagination"]["next_page"] is None:
            break
        page = data["pagination"]["next_page"]
    return scripts, translations


def fail(msg):
    print(f"FAIL: {msg}")
    return 1


def comparable(text):
    """NFC-normalised with all whitespace removed."""
    return WS.sub("", unicodedata.normalize("NFC", text))


def tajweed_plain(tj):
    """The tajweed HTML with the end-of-ayah marker and all tags removed."""
    return html.unescape(TAGS.sub("", END_MARK.sub("", tj)))


# --- Tajweed spans over the verified Uthmani text -------------------------
#
# Quran.com's text_uthmani_tajweed is a font-specific encoding (U+0672 stands
# in for fatha+dagger alef, hamza forms are pre-composed, ZWNJ is inserted
# before waqf marks). It must never be displayed with another font, so instead
# the rule classes are projected onto our verified text_uthmani: both strings
# are reduced to their base rasm letters, which must match exactly, and each
# coloured tajweed letter colours the same-index letter (plus its marks) in the
# Uthmani text. Offsets are Unicode code points, which equal UTF-16 units here.

SKIP_BASE = set("\u0640\u200c\u200d\u0672\u06e5\u06e6\u0670\u066e")   # tatweel, ZWNJ/ZWJ, dagger-alef stand-in, small waw/ya, dotless beh seat
# In the Uthmani text a mid-word alef maqsura that only carries the dagger alef
# (سَوَّىٰهُنَّ, هَدَىٰكُمْ, مِيكَىٰلَ) is a seat, not a letter; the tajweed encoding
# drops it or writes U+066E. Remove it before comparing base letters.
SEAT_YA = re.compile("\u0649(?=[\u064B-\u065F\u0670]*\u0670[\u064B-\u065F\u06D6-\u06ED]*[\u0621-\u064A])")
ALEF_FORMS = {"\u0623": "\u0627", "\u0625": "\u0627", "\u0622": "\u0627", "\u0671": "\u0627", "\u0672": None, "\u0673": "\u0627",
              # hamza on a ya seat is precomposed (ئ) in Uthmani but ى + U+0654 in the tajweed encoding
              "\u0626": "\u0649",
              # likewise hamza on a waw seat (ؤ) versus و + U+0654
              "\u0624": "\u0648"}

def is_mark(ch):
    return unicodedata.category(ch) in ("Mn", "Mc", "Me") or ch in SKIP_BASE

def base_letters(text):
    """[(index, letter)] for the base rasm letters of `text`."""
    seats = {m.start() for m in SEAT_YA.finditer(text)}
    out = []
    for i, ch in enumerate(text):
        if ch.isspace() or is_mark(ch) or i in seats:
            continue
        if ch in ALEF_FORMS:
            mapped = ALEF_FORMS[ch]
            if mapped is None:
                continue
            ch = mapped
        if not ch.isalpha():
            continue
        out.append((i, ch))
    return out

TJ_TOKEN = re.compile(r"<tajweed class=\"?([a-z_]+)\"?>|</tajweed>|<[^>]+>")

def tajweed_chars(tj):
    """[(char, class)] for the tajweed HTML with tags resolved to per-character classes."""
    tj = END_MARK.sub("", tj)
    chars, pos, current = [], 0, None
    for m in TJ_TOKEN.finditer(tj):
        for ch in html.unescape(tj[pos:m.start()]):
            chars.append((ch, current))
        pos = m.end()
        if m.group(0).startswith("<tajweed"):
            current = m.group(1)
        elif m.group(0) == "</tajweed>":
            current = None
    for ch in html.unescape(tj[pos:]):
        chars.append((ch, current))
    return chars

def tajweed_spans(tj, uthmani):
    """(spans, error): spans are {"s","l","c"} over `uthmani`, or error text."""
    chars = tajweed_chars(tj)
    tj_text = "".join(c for c, _ in chars)
    tj_base = base_letters(tj_text)
    ut_base = base_letters(uthmani)
    if [c for _, c in tj_base] != [c for _, c in ut_base]:
        return None, (f"base letters differ: tajweed {''.join(c for _, c in tj_base)!r} vs "
                      f"uthmani {''.join(c for _, c in ut_base)!r}")
    # class per tajweed base letter
    classes = []
    for idx, _ in tj_base:
        classes.append(chars[idx][1])
    # letter i of uthmani spans from its index to just before the next base letter
    # (so its marks are included) but not across whitespace
    spans = []
    for i, ((start, _), cls) in enumerate(zip(ut_base, classes)):
        if cls is None:
            continue
        end = ut_base[i + 1][0] if i + 1 < len(ut_base) else len(uthmani)
        while end > start + 1 and uthmani[end - 1].isspace():
            end -= 1
        if spans and spans[-1]["c"] == cls and spans[-1]["s"] + spans[-1]["l"] >= start:
            spans[-1]["l"] = end - spans[-1]["s"]
        else:
            spans.append({"s": start, "l": end - start, "c": cls})
    return spans, None


def verify_scripts(canonical, scripts):
    failures = 0
    print("\n== quran-scripts verification ==")
    if len(scripts) != AYAH_COUNT:
        failures += fail(f"{len(scripts)} ayat, expected {AYAH_COUNT}")
    if [a["k"] for a in scripts] != [a["k"] for a in canonical]:
        failures += fail("keys differ from quran.json (count or order)")
    for a in scripts:
        if not a["tj"].strip():
            failures += fail(f"empty tajweed in {a['k']}")
        if not a["ip"].strip():
            failures += fail(f"empty indopak in {a['k']}")
        if "\n" in a["tj"] or "\n" in a["ip"]:
            failures += fail(f"newline inside script text of {a['k']}")
        if "<" in a["ip"] or "&" in a["ip"]:
            failures += fail(f"markup in indopak of {a['k']}: {a['ip']!r}")
    print(f"ayat: {len(scripts)}, keys identical to quran.json, no empty field")

    classes = Counter()
    for a in scripts:
        classes.update(TAJWEED_CLASS.findall(a["tj"]))
    print("tajweed classes:")
    for name, count in classes.most_common():
        print(f"  {name:<22} {count:>7}")
    end_marks = sum(1 for a in scripts if END_MARK.search(a["tj"]))
    print(f"<span class=end> markers present on {end_marks} ayat")

    uthmani = {a["k"]: a["t"] for a in canonical}
    aligned, problems = 0, []
    for a in scripts:
        spans, error = tajweed_spans(a["tj"], uthmani[a["k"]])
        if error:
            problems.append((a["k"], error))
            continue
        for sp in spans:
            if sp["s"] < 0 or sp["l"] <= 0 or sp["s"] + sp["l"] > len(uthmani[a["k"]]):
                problems.append((a["k"], f"span out of range {sp}"))
        a["tj"] = spans
        aligned += 1
    print(f"tajweed spans aligned onto text_uthmani for {aligned} of {len(scripts)} ayat")
    for key, error in problems[:8]:
        failures += fail(f"tajweed alignment {key}: {error}")
    if len(problems) > 8:
        failures += fail(f"... and {len(problems) - 8} more alignment problems")
    return failures, len(problems)


def verify_translations(canonical, editions, translations):
    failures = 0
    print("\n== translations verification ==")
    ids = [str(e["id"]) for e in editions]
    if len(translations) != AYAH_COUNT:
        failures += fail(f"{len(translations)} ayat, expected {AYAH_COUNT}")
    if [a["k"] for a in translations] != [a["k"] for a in canonical]:
        failures += fail("keys differ from quran.json (count or order)")
    for a in translations:
        if sorted(a["t"]) != sorted(ids):
            failures += fail(f"{a['k']} has editions {sorted(a['t'])}, expected {sorted(ids)}")
        for rid, text in a["t"].items():
            if not text.strip():
                failures += fail(f"empty translation {rid} in {a['k']}")
            if "<" in text or ">" in text:
                failures += fail(f"HTML remains in translation {rid} of {a['k']}: {text!r}")
            if re.search(r"&[a-zA-Z#0-9]+;", text):
                failures += fail(f"HTML entity remains in translation {rid} of {a['k']}: {text!r}")
            if "\n" in text:
                failures += fail(f"newline inside translation {rid} of {a['k']}")
    print(f"ayat: {len(translations)}, every ayah has all {len(ids)} editions, no empty text, no residual HTML")
    sample = next(a for a in translations if a["k"] == "2:255")
    for rid in ids:
        print(f"  2:255 [{rid}] {sample['t'][rid][:70]!r}")
    return failures


def write(path, payload):
    path.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    size = path.stat().st_size
    print(f"wrote {path} ({size:,} bytes, {size / 1024 / 1024:.2f} MiB)")


def main():
    canonical = json.loads(QURAN.read_text(encoding="utf-8"))["ayat"]
    if len(canonical) != AYAH_COUNT:
        raise SystemExit(f"quran.json has {len(canonical)} ayat, expected {AYAH_COUNT}")

    print("resolving editions")
    editions = resolve_editions()
    ids = [e["id"] for e in editions]

    # Optional raw cache (scratchpad only) so verification can be re-run without
    # re-fetching; the cache is the untouched API payload after cleaning.
    cache = Path(os.environ["EXTRAS_CACHE"]) if os.environ.get("EXTRAS_CACHE") else None
    if cache and cache.exists():
        raw = json.loads(cache.read_text(encoding="utf-8"))
        if raw["ids"] != ids:
            raise SystemExit(f"cache {cache} was fetched for editions {raw['ids']}, not {ids}")
        scripts, translations = raw["scripts"], raw["translations"]
        for entry in translations:
            entry["t"] = {k: clean_translation(v) for k, v in entry["t"].items()}
        print(f"loaded {len(scripts)} ayat from cache {cache}")
    else:
        scripts, translations = [], []
        for n in range(1, SURAH_COUNT + 1):
            s, t = fetch_chapter(n, ids)
            print(f"{n:>3} {len(s):>3} ayat")
            scripts.extend(s)
            translations.extend(t)
        if cache:
            cache.write_text(json.dumps({"ids": ids, "scripts": scripts, "translations": translations},
                                        ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    script_failures, glyph_diffs = verify_scripts(canonical, scripts)
    translation_failures = verify_translations(canonical, editions, translations)
    if script_failures or translation_failures:
        print(f"\n{script_failures + translation_failures} check(s) failed; nothing written")
        raise SystemExit(1)

    today = datetime.date.today().isoformat()
    print()
    write(OUT_SCRIPTS, {
        "source": ("Quran.com API v4. tj: tajweed rule classes from text_uthmani_tajweed projected onto the "
                   "verified text_uthmani of quran.json as {s: start, l: length, c: class} in code points. "
                   "ip: text_indopak verbatim."),
        "fetched": today,
        "ayat": scripts,
    })
    write(OUT_TRANSLATIONS, {
        "source": ("Quran.com API v4 translations " + ", ".join(f"{e['id']} {e['name']}" for e in editions)
                   + "; HTML footnote markers removed for display."),
        "fetched": today,
        "editions": editions,
        "ayat": translations,
    })
    if glyph_diffs:
        print(f"\nFLAG: {glyph_diffs} ayat where the tajweed text differs from text_uthmani in marks/glyphs only "
              f"(same base letters); files written, data left untouched")
    print(f"stray angle brackets removed from {STRAY_ANGLES['stray']} translation strings")
    print("all checks passed")


if __name__ == "__main__":
    main()
