#!/usr/bin/env python3
"""Fetch the ruqyah passages from Quran.com API v4 into Shared/Resources/ruqyah.json.

Arabic: /quran/verses/uthmani (text_uthmani). Translation: Saheeh International
(resource 20) with <sup> footnote markers stripped and whitespace collapsed,
exactly as verses.json was produced. Nothing here is typed by hand.
"""
import json
import re
import unicodedata
import sys
import time
import datetime
import urllib.request
import urllib.error
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Shared" / "Resources" / "ruqyah.json"
API = "https://api.quran.com/api/v4"
PAUSE = 0.15

# (surah, from, to, id-slug, titleEnglish, titleArabic)
PASSAGES = [
    (1, 1, 7, "Al-Fatihah", "الفاتحة"),
    (2, 1, 5, "Opening of al-Baqarah", "فاتحة سورة البقرة"),
    (2, 102, 102, "The verse on magic (2:102)", "آية السحر"),
    (2, 163, 164, "Your God is one God (2:163-164)", "وإلهكم إله واحد"),
    (2, 255, 257, "The verse of the Throne and the two ayat after it", "آية الكرسي وما بعدها"),
    (2, 284, 286, "Closing of al-Baqarah", "خواتيم سورة البقرة"),
    (3, 18, 19, "Allah bears witness (3:18-19)", "شهد الله"),
    (7, 54, 56, "Your Lord is Allah (7:54-56)", "إن ربكم الله"),
    (7, 117, 122, "Musa and the magicians", "موسى والسحرة"),
    (10, 81, 82, "Yunus 81-82", "يونس ٨١–٨٢"),
    (20, 69, 69, "Ta-Ha 69", "طه ٦٩"),
    (23, 115, 118, "Did you think We created you in vain?", "أفحسبتم أنما خلقناكم عبثًا"),
    (37, 1, 10, "As-Saffat 1-10", "الصافات ١–١٠"),
    (46, 29, 32, "The jinn who listened", "الجن الذين استمعوا"),
    (55, 33, 36, "Ar-Rahman 33-36", "الرحمن ٣٣–٣٦"),
    (59, 21, 24, "Closing of al-Hashr", "خواتيم سورة الحشر"),
    (72, 1, 9, "Al-Jinn 1-9", "الجن ١–٩"),
    (112, 1, 4, "Al-Ikhlas", "الإخلاص"),
    (113, 1, 5, "Al-Falaq", "الفلق"),
    (114, 1, 6, "An-Nas", "الناس"),
]

SUP = re.compile(r"<sup[^>]*>.*?</sup>", re.S)
TAGS = re.compile(r"<[^>]+>")
WS = re.compile(r"\s+")


def get(url, attempts=5):
    for attempt in range(attempts):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "yaqeen-ruqyah-fetch/1.0", "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            time.sleep(PAUSE)
            return data
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError) as err:
            wait = 1.5 * (attempt + 1)
            print(f"  retry {attempt + 1}/{attempts} for {url}: {err} (sleeping {wait:.1f}s)", file=sys.stderr)
            time.sleep(wait)
    raise SystemExit(f"gave up on {url}")


def clean_translation(html):
    text = SUP.sub("", html)
    text = TAGS.sub("", text)
    return WS.sub(" ", text).strip()


def fetch_ayah(key):
    arabic = get(f"{API}/quran/verses/uthmani?verse_key={key}")["verses"]
    assert len(arabic) == 1 and arabic[0]["verse_key"] == key, f"unexpected uthmani payload for {key}"
    verse = get(f"{API}/verses/by_key/{key}?translations=20")["verse"]
    assert verse["verse_key"] == key
    translations = [t for t in verse["translations"] if t["resource_id"] == 20]
    assert translations, f"no Saheeh International text for {key}"
    return {
        "key": key,
        "arabic": arabic[0]["text_uthmani"].strip(),
        "translation": clean_translation(translations[0]["text"]),
    }


def main():
    chapters = {}
    passages = []
    for surah, start, end, title_en, title_ar in PASSAGES:
        if surah not in chapters:
            chapters[surah] = get(f"{API}/chapters/{surah}?language=en")["chapter"]
        chapter = chapters[surah]
        print(f"{surah}:{start}-{end} {chapter['name_simple']}")
        ayat = [fetch_ayah(f"{surah}:{n}") for n in range(start, end + 1)]
        pid = f"ruqyah-quran-{surah}-{start}" if start == end else f"ruqyah-quran-{surah}-{start}-{end}"
        passages.append({
            "id": pid,
            "surah": surah,
            "surahName": chapter["name_simple"],
            "surahNameArabic": chapter["name_arabic"],
            "from": start,
            "to": end,
            "titleEnglish": title_en,
            "titleArabic": title_ar,
            "ayat": ayat,
        })

    today = datetime.date.today().isoformat()
    payload = {
        "source": ("Quran.com API v4. Arabic: Uthmani script. Translation: Saheeh International; "
                   f"HTML footnote markers removed for display. Fetched {today}."),
        "passages": passages,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")

    print("\nkey        arabic[:12]        translation chars")
    by_key = {}
    for p in passages:
        for a in p["ayat"]:
            by_key[a["key"]] = a
            print(f"{a['key']:<10} {a['arabic'][:12]:<18} {len(a['translation'])}")
    total = sum(len(p["ayat"]) for p in passages)
    print(f"\n{len(passages)} passages, {total} ayat -> {OUT}")

    checks = {"2:255": "ٱللَّهُ لَآ إِلَـٰهَ", "1:1": "بِسْمِ ٱللَّهِ"}
    ok = True
    for key, prefix in checks.items():
        # The API orders combining marks canonically (shadda before fatha) and
        # writes alif-madda as alif + combining madda; compare under NFD.
        good = unicodedata.normalize("NFD", by_key[key]["arabic"]).startswith(unicodedata.normalize("NFD", prefix))
        ok &= good
        print(f"check {key} starts with {prefix!r}: {'OK' if good else 'FAIL'}")
    for a in by_key.values():
        if "<" in a["translation"] or not a["arabic"]:
            ok = False
            print(f"FAIL: residual markup or empty Arabic in {a['key']}")
    if not ok:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
