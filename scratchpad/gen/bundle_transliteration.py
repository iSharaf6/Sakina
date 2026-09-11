#!/usr/bin/env python3
"""Bundle Quran Foundation word transliteration from the cached source responses.
Run fetch_mushaf_lines.py first. Never synthesize or translate Arabic locally.
"""
import json, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
by_key = {}
for page in range(1,605):
    source = json.loads((root / f'build/mushaf-source-v2/{page}.json').read_text())
    for verse in source['verses']:
        words = [w for w in verse['words'] if w['char_type_name']=='word']
        pieces = [w['transliteration']['text'] for w in words]
        assert all(isinstance(t,str) and t.strip() for t in pieces), verse['verse_key']
        text = ' '.join(pieces)
        if verse['verse_key'] in by_key: assert by_key[verse['verse_key']] == text
        by_key[verse['verse_key']] = text
expected = {a['k'] for a in json.loads((root / 'Shared/Resources/quran.json').read_text())['ayat']}
assert set(by_key) == expected
out = root / 'Sakina/Resources/quran-transliteration.json'
out.write_text(json.dumps({'source':'Quran Foundation Content API v4, word transliteration, bundled 2026-09-11','ayat':by_key},ensure_ascii=False,separators=(',',':')))
print(f'Bundled transliteration for {len(by_key)} ayat')
