#!/usr/bin/env python3
"""Fetch KFGQPC's "Hafs Smart" v8 font and per-ayah data (the Complex's own
product for showing the Madani Uthmani text on phones, pre-shaped glyph codes)
from the thetruetruth/quran-data-kfgqpc mirror at a pinned commit, verify it
against quran.json, and write Shared/Resources/hafs-smart.json plus
Sakina/Resources/HafsSmart.ttf. Nothing is written unless every hard check
passes."""
import datetime, json, re, sys, urllib.request, collections
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
REPO = "thetruetruth/quran-data-kfgqpc"
COMMIT = sys.argv[1] if len(sys.argv) > 1 else "main"
BASE = f"https://raw.githubusercontent.com/{REPO}/{COMMIT}/"
OUT_JSON = ROOT / "Shared" / "Resources" / "hafs-smart.json"
OUT_FONT = ROOT / "Sakina" / "Resources" / "HafsSmart.ttf"

def get(path):
    req = urllib.request.Request(BASE + path, headers={"User-Agent": "Yaqeen build"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()

print("downloading from", BASE)
data = json.loads(get("hafs-smart/data/hafs_smart_v8.json").decode("utf-8"))
font = get("hafs-smart/font/hafssmart.8.ttf")
readme = get("hafs-smart/README.md").decode("utf-8", "replace")
rows = data if isinstance(data, list) else next(v for v in data.values() if isinstance(v, list))
version = re.search(r"Version:\s*([\d.]+)", readme); updated = re.search(r"Updated Date:\s*([\d-]+)", readme)
print("README says version", version.group(1) if version else "?", "updated", updated.group(1) if updated else "?")

ours = {a["k"]: a for a in json.loads((ROOT / "Shared/Resources/quran.json").read_text(encoding="utf-8"))["ayat"]}
failures = []
def fail(m): failures.append(m); print("FAIL:", m)

smart = {}
for r in rows:
    k = f"{int(r['sura_no'])}:{int(r['aya_no'])}"
    if k in smart: fail(f"duplicate row {k}")
    smart[k] = r
if len(rows) != 6236: fail(f"{len(rows)} rows, expected 6236")
if set(smart) != set(ours): fail("ayah keys differ from quran.json")

# font coverage: every glyph code in the text must exist in the font's cmap
try:
    from fontTools.ttLib import TTFont
    import io
    cmap = TTFont(io.BytesIO(font)).getBestCmap()
    used = {ord(ch) for r in rows for ch in r["aya_text"]}
    missing = sorted(hex(c) for c in used if c not in cmap and c not in (0x200F, 0x20))
    if missing: fail(f"glyph codes missing from the font: {missing[:10]}")
    print("font covers all", len(used), "distinct code points used")
except ImportError:
    print("fonttools unavailable; skipping cmap coverage (run with /tmp/claude-501/venv/bin/python)")

# the ayah-number glyph: last glyph of every row, consistent per number
last = collections.defaultdict(set)
for r in rows:
    t = r["aya_text"].rstrip()
    if not t: fail(f"empty text {r['sura_no']}:{r['aya_no']}"); continue
    last[int(r["aya_no"])].add(t[-1])
bad = [n for n, g in last.items() if len(g) != 1]
if bad: fail(f"ayah-number glyph inconsistent for numbers {bad[:10]}")
if len(last) != 286: fail(f"{len(last)} distinct ayah numbers, expected 286")

# structure: only RLM-prefixed private-use glyphs and spaces
odd = sorted({hex(ord(ch)) for r in rows for ch in r["aya_text"] if not (0xE000 <= ord(ch) <= 0xF8FF or ch in " ‏")})
if odd: fail(f"unexpected characters in smart text: {odd}")

# sanity against quran.json: word counts per ayah (the smart text spaces words the same way,
# apart from the 43 places the Complex joined in v8), page and juz numbers
def words(t): return len([w for w in t.replace("‏", "").split(" ") if w])
WAQF = re.compile("^[\u06D6-\u06ED\u08D6-\u08FF\u0610-\u061A]+$")   # a standalone pause-mark token is not a word
def our_words(t): return len([w for w in t.split() if not WAQF.match(w)])
wc_same = sum(1 for k, a in ours.items() if words(smart[k]["aya_text"]) - 1 == our_words(a["t"]))
wc_emlaey = sum(1 for k in ours if words(smart[k]["aya_text"]) - 1 == len(smart[k]["aya_text_emlaey"].split()))
print(f"word count matches the Complex's own plain spelling on {wc_emlaey}/6236")
page_same = sum(1 for k, a in ours.items() if int(smart[k]["page"]) == a["p"])
juz_same = sum(1 for k, a in ours.items() if int(smart[k]["jozz"]) == a["j"])
print(f"word count matches quran.json on {wc_same}/6236, page on {page_same}/6236, juz on {juz_same}/6236")
if wc_same < 6000 and wc_emlaey < 6000: fail("word counts disagree with both quran.json and the plain spelling")
if page_same < 6100: fail("too many page mismatches against quran.json")

if failures:
    print(f"\n{len(failures)} check(s) failed; nothing written"); sys.exit(1)

OUT_FONT.write_bytes(font)
payload = {
    "source": f"KFGQPC Hafs Smart v{version.group(1) if version else '8'} ({updated.group(1) if updated else 'n.d.'}): pre-shaped glyph codes for the KFGQPC Hafs Smart font, mirrored at github.com/{REPO}@{COMMIT}. Text kept verbatim.",
    "fetched": datetime.date.today().isoformat(),
    "ayat": [{"k": k, "t": smart[k]["aya_text"].rstrip(), "p": int(smart[k]["page"]), "ls": int(smart[k]["line_start"]), "le": int(smart[k]["line_end"])} for k in ours],
}
OUT_JSON.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
print("wrote", OUT_JSON, OUT_JSON.stat().st_size, "bytes and", OUT_FONT, OUT_FONT.stat().st_size, "bytes")
