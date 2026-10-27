"""Sözlüğe yeni kelime ekleme: Firebase'den gelen eksik kayıtlar + sıklık listelerinin eksikleri.

Kullanım (kavaid klasöründen; make/read için GEMINI_API_KEY gerekmez, run_parts gerektirir):
    python tool/i18n/new_words.py select        # content/lang/tr/new_words_v1.jsonl
    python tool/i18n/new_words.py make          # content/batch/newwords_v1_part1.jsonl + manifest
    ..\\..\\batch\\.venv\\Scripts\\python tool/i18n/run_parts.py --lang newwords --parts 1
    python tool/i18n/new_words.py read --results content/batch/newwords_v1_results_part1.jsonl
                                                # content/lang/tr/new_entries_v1.jsonl (kaynak biçiminde) + rapor
    python tool/i18n/new_words.py merge         # SON_GUNCEL_VERITABANI_V2.json'a ekler (önce yedek alır)

select: Firebase kayıtlarından check_tr_data'nın "sözlükte zaten var" (hatalı tekrar), "emin değil" ve "kelime değil"
dediklerini atar, önerilen başlık/tür/anlam düzeltmelerini uygular, hatalı örnekleri çıkarır. Sıklık listelerinden
(freq_missing_subs/wiki) sözlükte hiçbir biçimi olmayan ve ilk --max-rank içinde geçen lemmaları alır.
make/read: gemini-3.8-flash kaydı tamamlar. Firebase kaydında yalnız harf-i cerler, boş çoğul ve 2'ye tamamlanacak
örnekler modelden alınır; sıklık listesi kelimesinin kaydı baştan yazılır (özel isim, argo, uygunsuz → atlanır).
"""
import argparse
import datetime
import json
import os
import re
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from freq_gap import known_forms, variants  # noqa: E402
from syn_filter import norm  # noqa: E402

MODEL = 'gemini-3.8-flash'
PACK = 10
TOKENS_PER_CHAR = 0.29
SOURCE = 'SON_GUNCEL_VERITABANI_V2.json'
SELECTED = 'content/lang/tr/new_words_v1.jsonl'
ENTRIES = 'content/lang/tr/new_entries_v1.jsonl'
BASE = 'content/batch/newwords_v1'
HARAKAT = re.compile(r'[ً-ْٰـ]')
ARABIC = re.compile(r'[ء-ي]')
# Model atlamadığı halde eklenmeyecek argo/aşağılayıcı kelimeler (harekesiz, syn_filter.norm biçiminde)
EXCLUDE = {'داعر', 'زنجي'}
TYPES = ['İsim', 'Mazî Fiil', 'Muzari Fiil', 'Mastar', 'Sıfat', 'Emir Fiil', 'İsim Tamlaması', 'Zarf',
         'Harf-i Cerli İsim', 'İsm-i Fail', "İsm-i Mef'ul", 'İsm-i Tafdil', 'Muzari Meçhul Fiil', 'Meçhul Mazî Fiil',
         'İsim, Çoğul', 'Edat', 'Deyim', 'Sıfat tamlaması', 'Harf-i Cerli Mastar', 'Sayı', 'Zamir']

SYSTEM = """You complete entries of a Turkish–Arabic learner's dictionary (the app "Kavaid"). Its users are Turkish speakers learning Modern Standard and Classical Arabic.

Each input entry is either "existing" (a full entry written earlier; keep its correct content) or "new" (only a lemma, a Turkish hint and the forms seen in a corpus). Return one complete entry per input:
- harekeliKelime: the fully vowelled headword. Existing: exactly the given headword. New: the given lemma, unless it is misspelled.
- kelime: the headword without vowel marks.
- koku: the root letters without spaces (كتب). For foreign loanwords without an Arabic root, the unvowelled word.
- tur: one label from this list: {types}.
- cogulForm: the vowelled plural of a noun or adjective that has a common plural; "" for verbs, words without a plural and words that are already plural.
- maziForm, muzariForm, mastarForm, emirForm: the forms of the related verb (3rd masc. sg. past, present, a masdar, 2nd masc. sg. imperative), vowelled. Nouns and adjectives derived from a verb get that verb's forms. "" when there is no related verb (loanwords, particles).
- anlamlar: Turkish meanings, comma-separated, most common first, 1–6 short glosses, translating the headword in the form shown (an inflected form keeps its person and number: "karar veriyorum").
- harfi_cerler: prepositions the word commonly takes with a distinct meaning (mostly verbs, masdars and participles), at most 3: [{{"harf": the unvowelled preposition (ب، على، إلى، عن، في، من، ل، مع، بين), "anlamlar": Turkish meanings with "..." for the object, e.g. "...den vazgeçmek, ...i bırakmak"}}]. [] when none.
- ornekler: exactly 2 short, natural Modern Standard Arabic sentences (4–10 words, fully vowelled) that contain the headword in exactly the form shown, each with a natural Turkish translation. Existing: return the given examples unchanged and add new ones only to reach 2. No Quran verses, hadith or poetry.
- skip: true only for a "new" entry that does not belong in the dictionary: a proper noun, a vulgar or offensive word or slur, a colloquial-only word, or not a real word. skip_reason: a few English words, else "".

Return only JSON matching the schema, one item per entry, same ids, same order."""

SCHEMA = {
    'type': 'OBJECT',
    'properties': {'items': {'type': 'ARRAY', 'items': {
        'type': 'OBJECT',
        'properties': {
            'id': {'type': 'INTEGER'},
            'skip': {'type': 'BOOLEAN'},
            'skip_reason': {'type': 'STRING'},
            'harekeliKelime': {'type': 'STRING'},
            'kelime': {'type': 'STRING'},
            'koku': {'type': 'STRING'},
            'tur': {'type': 'STRING', 'enum': TYPES},
            'cogulForm': {'type': 'STRING'},
            'maziForm': {'type': 'STRING'},
            'muzariForm': {'type': 'STRING'},
            'mastarForm': {'type': 'STRING'},
            'emirForm': {'type': 'STRING'},
            'anlamlar': {'type': 'STRING'},
            'harfi_cerler': {'type': 'ARRAY', 'items': {
                'type': 'OBJECT',
                'properties': {'harf': {'type': 'STRING'}, 'anlamlar': {'type': 'STRING'}},
                'required': ['harf', 'anlamlar'],
            }},
            'ornekler': {'type': 'ARRAY', 'items': {
                'type': 'OBJECT',
                'properties': {'ar': {'type': 'STRING'}, 'tr': {'type': 'STRING'}},
                'required': ['ar', 'tr'],
            }},
        },
        'required': ['id', 'skip', 'skip_reason', 'harekeliKelime', 'kelime', 'koku', 'tur', 'cogulForm', 'maziForm',
                     'muzariForm', 'mastarForm', 'emirForm', 'anlamlar', 'harfi_cerler', 'ornekler'],
    }}},
    'required': ['items'],
}


def load_jsonl(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding='utf-8') as f:
        return [json.loads(line) for line in f if line.strip()]


def bare(s):
    return HARAKAT.sub('', s or '').strip()


def known_bases():
    recs = [r['rec'] for r in load_jsonl('content/master/words.jsonl')]
    recs += [r['rec'] for r in load_jsonl('content/lang/tr/firebase_missing_v1.jsonl')]
    forms = known_forms(recs)
    bases = set(forms)
    for f in forms:
        for suf in ('ا', 'ه', 'ات', 'ون', 'ين', 'ان', 'تان', 'تين'):
            if f.endswith(suf) and len(f) - len(suf) >= 2:
                bases.add(f[:-len(suf)])
    return bases


def select(args):
    checks = {r['wid']: r for r in load_jsonl('content/lang/tr/fbnew_check_v1.jsonl')}
    rows, dropped = [], {'tekrar': 0, 'emin değil': 0, 'kelime değil': 0}
    for r in load_jsonl('content/lang/tr/firebase_missing_v1.jsonl'):
        c = checks.get(r['id'], {})
        if 'sözlükte' in (c.get('evidence') or ''):
            dropped['tekrar'] += 1
            continue
        if c.get('verdict') == 'unsure':
            dropped['emin değil'] += 1
            continue
        if 'not_a_word' in (c.get('problems') or []):
            dropped['kelime değil'] += 1
            continue
        rec = json.loads(json.dumps(r['rec']))
        if c.get('headword_fix'):
            rec['harekeliKelime'] = c['headword_fix']
            rec['kelime'] = bare(c['headword_fix'])
        if c.get('type_fix'):
            rec['dilbilgiselOzellikler']['tur'] = c['type_fix']
        if c.get('meaning_fix'):
            rec['anlam'] = c['meaning_fix']
        bad = set(c.get('bad_examples') or [])
        rec['ornekCumleler'] = [o for o in rec['ornekCumleler'] if o['arapcaCümle'] not in bad]
        rows.append({'id': r['id'], 'src': 'firebase', 'fbkey': r['fbkey'], 'rec': rec})

    bases, seen, freq = known_bases(), set(), []
    for name in ('subs', 'wiki'):
        for m in load_jsonl(f'content/lang/tr/freq_missing_{name}.jsonl'):
            n = norm(m['lemma'])
            if m['best_rank'] > args.max_rank or n in bases or n in seen:
                continue
            seen.add(n)
            freq.append({'id': 950000 + len(freq), 'src': f'freq_{name}', 'rank': m['best_rank'],
                         'lemma': m['lemma'], 'tr': m['tr'], 'forms': m['forms'][:5]})
    with open(SELECTED, 'w', encoding='utf-8') as f:
        for r in rows + freq:
            f.write(json.dumps(r, ensure_ascii=False) + '\n')
    print(f'Firebase: {len(rows)} kayıt (atılan {dropped}) · sıklık listeleri (ilk {args.max_rank}): {len(freq)} lemma')
    print(f'çıktı: {SELECTED}')


def payload(row):
    if row['src'] == 'firebase':
        rec = row['rec']
        gram, fiil = rec.get('dilbilgiselOzellikler') or {}, rec.get('fiilCekimler') or {}
        return {'id': row['id'], 'kind': 'existing', 'harekeliKelime': rec['harekeliKelime'], 'koku': rec.get('koku', ''),
                'tur': gram.get('tur', ''), 'cogulForm': gram.get('cogulForm', ''), 'fiilCekimler': fiil,
                'anlamlar': rec.get('anlam', ''),
                'ornekler': [{'ar': o['arapcaCümle'], 'tr': o['turkceAnlam']} for o in rec['ornekCumleler']]}
    return {'id': row['id'], 'kind': 'new', 'lemma': row['lemma'], 'turkish_hint': row['tr'], 'corpus_forms': row['forms']}


def make(args):
    rows = load_jsonl(SELECTED)
    os.makedirs('content/batch', exist_ok=True)
    system = SYSTEM.format(types='، '.join(TYPES).replace('، ', ', '))
    chunks, est = {}, 0
    path = f'{BASE}_part1.jsonl'
    with open(path, 'w', encoding='utf-8') as out:
        for start in range(0, len(rows), PACK):
            group = rows[start:start + PACK]
            body = {
                'systemInstruction': {'parts': [{'text': system}]},
                'contents': [{'role': 'user', 'parts': [{'text': json.dumps([payload(r) for r in group], ensure_ascii=False)}]}],
                'generationConfig': {'responseMimeType': 'application/json', 'responseSchema': SCHEMA,
                                     'thinkingConfig': {'thinkingLevel': 'low'}},
            }
            key = f'newwords:{start // PACK:05d}'
            out.write(json.dumps({'key': key, 'request': body}, ensure_ascii=False) + '\n')
            est += int(len(json.dumps(body, ensure_ascii=False)) * TOKENS_PER_CHAR)
            chunks[key] = [r['id'] for r in group]
    manifest = {'lang': 'newwords', 'version': 'v1', 'model': MODEL, 'pack': PACK,
                'created': datetime.datetime.now().isoformat(timespec='seconds'), 'words': len(rows),
                'parts': [{'file': path, 'requests': len(chunks), 'words': len(rows), 'est_input_tokens': est}],
                'chunks': chunks}
    with open(f'{BASE}_manifest.json', 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False)
    print(f'{path}: {len(chunks)} istek, {len(rows)} kelime, ~{est / 1e6:.2f} M girdi token')


def contains_headword(sentence, head):
    """Başlığın her kelimesi (çok kelimeli başlıklarda hepsi) cümlede ekli ya da eksiz geçiyor mu?"""
    toks = [norm(t) for t in re.findall(r'[ء-يً-ْٰ]+', sentence)]
    for part in head.split():
        target = norm(part)
        if target and not any(t == target or target in variants(t) for t in toks):
            return False
    return True


def valid_preps(preps):
    return [{'harf': h['harf'].strip(), 'anlamlar': h['anlamlar'].strip()} for h in preps
            if ARABIC.search(h['harf']) and h['anlamlar'].strip() and not ARABIC.search(h['anlamlar'])]


def problems(it):
    found = []
    if not ARABIC.search(it['harekeliKelime']) or not HARAKAT.search(it['harekeliKelime']):
        found.append('başlık harekesiz/Arapça değil')
    if not it['anlamlar'].strip() or ARABIC.search(it['anlamlar']):
        found.append('Türkçe anlam yok/bozuk')
    exs = [e for e in it['ornekler'] if e['ar'].strip() and e['tr'].strip()]
    if len(exs) < 2:
        found.append('2 örnek yok')
    for e in exs:
        if ARABIC.search(e['tr']) or not ARABIC.search(e['ar']):
            found.append('örnek dili bozuk')
        elif not contains_headword(e['ar'], it['harekeliKelime']):
            found.append('örnekte kelime yok')
    for h in it['harfi_cerler']:
        if not ARABIC.search(h['harf']) or ARABIC.search(h['anlamlar']) or not h['anlamlar'].strip():
            found.append('harf-i cer bozuk')
    return sorted(set(found))


def to_source(src_id, rec, harfi_cerler):
    return {'id': src_id, 'kelime': rec['kelime'], 'harekeliKelime': rec['harekeliKelime'], 'koku': rec.get('koku', ''),
            'dilbilgiselOzellikler': rec['dilbilgiselOzellikler'], 'fiilCekimler': rec['fiilCekimler'],
            'ornekCumleler': rec['ornekCumleler'], 'anlamlar': rec['anlam'], 'harfi_cerler': harfi_cerler}


def read(args):
    from validate import BATCH_PRICE
    rows = {r['id']: r for r in load_jsonl(SELECTED)}
    with open(f'{BASE}_manifest.json', encoding='utf-8') as f:
        manifest = json.load(f)
    items, usage = {}, {'in': 0, 'out': 0}
    for path in args.results:
        for line in load_jsonl(path):
            resp = line.get('response') or {}
            meta = resp.get('usageMetadata') or {}
            usage['in'] += meta.get('promptTokenCount', 0)
            usage['out'] += meta.get('candidatesTokenCount', 0) + meta.get('thoughtsTokenCount', 0)
            parts = ((resp.get('candidates') or [{}])[0].get('content') or {}).get('parts') or []
            try:
                for it in json.loads(''.join(p.get('text', '') for p in parts if not p.get('thought')))['items']:
                    items[it['id']] = it
            except (ValueError, KeyError, TypeError):
                pass

    out, report = [], {'firebase eklenen': 0, 'firebase harf-i cer eklenen': 0, 'firebase çoğul eklenen': 0,
                       'firebase örnek tamamlanan': 0,
                       'sıklık eklenen': 0, 'sıklık atlanan (model)': 0, 'sıklık denetimden kalan': 0, 'yanıtsız': 0}
    skipped, failed = [], []
    for rid, row in rows.items():
        it = items.get(rid)
        if row['src'] == 'firebase':
            rec = json.loads(json.dumps(row['rec']))
            preps = []
            if it is None:
                report['yanıtsız'] += 1
            else:
                # Firebase kaydının kendisi zaten denetlendi; modelden yalnız eklenen parçalar tek tek denetlenir
                preps = valid_preps(it['harfi_cerler'])
                report['firebase harf-i cer eklenen'] += bool(preps)
                gram = rec['dilbilgiselOzellikler']
                if not gram.get('cogulForm') and it['cogulForm'] and gram.get('tur') in ('İsim', 'Sıfat', 'İsm-i Fail', "İsm-i Mef'ul"):
                    gram['cogulForm'] = it['cogulForm']
                    report['firebase çoğul eklenen'] += 1
                have = {o['arapcaCümle'] for o in rec['ornekCumleler']}
                for e in it['ornekler']:
                    if len(rec['ornekCumleler']) >= 2:
                        break
                    if (e['ar'] not in have and e['tr'].strip() and not ARABIC.search(e['tr'])
                            and contains_headword(e['ar'], rec['harekeliKelime'])):
                        rec['ornekCumleler'].append({'arapcaCümle': e['ar'], 'turkceAnlam': e['tr']})
                        report['firebase örnek tamamlanan'] += 1
            if not rec['ornekCumleler']:
                failed.append({'id': rid, 'head': rec['harekeliKelime'], 'why': ['örnek kalmadı']})
                continue
            out.append(to_source(row['fbkey'], rec, preps))
            report['firebase eklenen'] += 1
            continue
        if it is None:
            report['yanıtsız'] += 1
            continue
        if it['skip'] or norm(it['harekeliKelime']) in EXCLUDE:
            report['sıklık atlanan (model)'] += 1
            skipped.append({'lemma': row['lemma'], 'why': it['skip_reason']})
            continue
        found = problems(it)
        if found:
            report['sıklık denetimden kalan'] += 1
            failed.append({'id': rid, 'head': it['harekeliKelime'], 'why': found})
            continue
        rec = {'kelime': bare(it['harekeliKelime']), 'harekeliKelime': it['harekeliKelime'], 'koku': it['koku'],
               'dilbilgiselOzellikler': {'cogulForm': it['cogulForm'], 'tur': it['tur']},
               'fiilCekimler': {'emirForm': it['emirForm'], 'mastarForm': it['mastarForm'],
                                'maziForm': it['maziForm'], 'muzariForm': it['muzariForm']},
               'ornekCumleler': [{'arapcaCümle': e['ar'], 'turkceAnlam': e['tr']} for e in it['ornekler'][:2]],
               'anlam': it['anlamlar']}
        out.append(to_source(f'freq-{rid}', rec, valid_preps(it['harfi_cerler'])))
        report['sıklık eklenen'] += 1

    with open(ENTRIES, 'w', encoding='utf-8') as f:
        for r in out:
            f.write(json.dumps(r, ensure_ascii=False) + '\n')
    with open('content/lang/tr/new_words_skipped_v1.json', 'w', encoding='utf-8') as f:
        json.dump({'skipped': skipped, 'failed': failed}, f, ensure_ascii=False, indent=1)
    price = BATCH_PRICE[manifest['model']]
    print(json.dumps(report, ensure_ascii=False))
    print(f'eklenecek toplam {len(out)} · maliyet ≈ ${(usage["in"] * price[0] + usage["out"] * price[1]) / 1e6:.2f}')
    print('atlananlardan örnek:', ', '.join(f"{s['lemma']} ({s['why']})" for s in skipped[:15]))


def merge(args):
    new = load_jsonl(ENTRIES)
    with open(SOURCE, encoding='utf-8') as f:
        data = json.load(f)
    have = {(r.get('harekeliKelime'), r.get('anlamlar')) for r in data}
    ids = {r.get('id') for r in data}
    add = [r for r in new if r['id'] not in ids and (r['harekeliKelime'], r['anlamlar']) not in have]
    backup = f'content/backup/{os.path.splitext(SOURCE)[0]}_{datetime.date.today().isoformat()}.json'
    os.makedirs(os.path.dirname(backup), exist_ok=True)
    if not os.path.exists(backup):
        shutil.copyfile(SOURCE, backup)
    with open(SOURCE, 'w', encoding='utf-8') as f:
        json.dump(data + add, f, ensure_ascii=False)
    print(f'{SOURCE}: {len(data)} + {len(add)} = {len(data) + len(add)} kayıt (yedek: {backup})')


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('action', choices=['select', 'make', 'read', 'merge'])
    ap.add_argument('--max-rank', type=int, default=20000)
    ap.add_argument('--results', nargs='*', default=[])
    args = ap.parse_args()
    {'select': select, 'make': make, 'read': read, 'merge': merge}[args.action](args)


if __name__ == '__main__':
    main()
