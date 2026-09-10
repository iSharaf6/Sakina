#!/usr/bin/env python3
"""Bundle Quran Foundation's Madani word/line layout, with matched QPC Unicode.
No text is generated or inferred. The canonical quran.json is never modified.
Raw responses are cached outside the bundle; publication is atomic after validation.
"""
import concurrent.futures, datetime, json, pathlib, time, subprocess
ROOT = pathlib.Path(__file__).resolve().parents[2]
CACHE = ROOT / 'build/mushaf-source-v2'
OUT = ROOT / 'Sakina/Resources/mushaf-lines.json'
CACHE.mkdir(parents=True, exist_ok=True)
canonical = json.loads((ROOT / 'Shared/Resources/quran.json').read_text())
expected = {a['k']: a for a in canonical['ayat']}

def fetch(page):
    path = CACHE / f'{page}.json'
    url = f'https://api.quran.com/api/v4/verses/by_page/{page}?words=true&word_fields=text_qpc_hafs,code_v2&mushaf=1&per_page=50'
    for attempt in range(5):
        try:
            data = json.loads(path.read_text()) if path.exists() else json.loads(subprocess.check_output(["curl", "-fsSL", "--max-time", "45", url]))
            assert data['pagination']['next_page'] is None
            words = []
            for verse in data['verses']:
                key = verse['verse_key']
                assert key in expected
                for word in verse['words']:
                    assert 1 <= word['page_number'] <= 604
                    assert 1 <= word['line_number'] <= 15
                    text = word['text_qpc_hafs']
                    assert text and '<' not in text
                    words.append({'mp': word['page_number'], 'k': key, 'p': word['position'], 'l': word['line_number'],
                                  't': text, 'e': word['char_type_name'] == 'end'})
            path.write_text(json.dumps(data, ensure_ascii=False))
            return page, words
        except Exception:
            if attempt == 4: raise
            time.sleep(1 + attempt * 2)

with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    pages = dict(pool.map(fetch, range(1, 605)))
by_word = {}
for records in pages.values():
    for word in records:
        identity = (word['k'], word['p'])
        if identity in by_word: assert by_word[identity] == word
        by_word[identity] = word
pages = {p: [] for p in range(1, 605)}
for word in sorted(by_word.values(), key=lambda w: (*map(int, w['k'].split(':')), w['p'])):
    pages[word.pop('mp')].append(word)
# The API has one non-monotonic V2 marker placement: 84:21's marker is
# reported on line 13 even though its preceding words and next verse are
# on line 14. Keep the marker after its verse; no text or word order changes.
for word in pages[589]:
    if word['k'] == '84:21' and word['e']:
        assert word['l'] in (13, 14)
        word['l'] = 14
for page, words in pages.items():
    assert [w['l'] for w in words] == sorted(w['l'] for w in words), page
seen = {}
for page in range(1, 605):
    for word in pages[page]: seen.setdefault(word['k'], []).append(word)
assert set(seen) == set(expected), 'Must contain all 6236 ayat'
for key, words in seen.items():
    assert [w['p'] for w in words] == list(range(1, len(words) + 1)), key
    assert sum(w['e'] for w in words) == 1 and words[-1]['e'], key
    assert int(words[-1]['t']) == expected[key]['a'], key
payload = {'source': 'Quran Foundation Content API v4, text_qpc_hafs with page_number and line_number. Uthmanic Hafs v18 font.',
           'fetched': str(datetime.date.today()), 'pages': [pages[p] for p in range(1, 605)]}
tmp = OUT.with_suffix('.tmp')
tmp.write_text(json.dumps(payload, ensure_ascii=False, separators=(',', ':')))
tmp.replace(OUT)
print(f'Validated {len(seen)} ayat, {len(pages)} pages, {sum(map(len, pages.values()))} words/markers; {OUT.stat().st_size:,} bytes', flush=True)
