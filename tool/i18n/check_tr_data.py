"""Türkçe sözlük verisindeki şüpheli kayıtları denetler (Arapça üretimde data_issue işaretlenenler).

Kullanım (kavaid klasöründen; GEMINI_API_KEY ortamda):
    python tool/i18n/check_tr_data.py pilot          # el ile bakılan 30 kayıtta eşzamanlı deneme
    python tool/i18n/check_tr_data.py make           # content/batch/trfix_v1_part1.jsonl + manifest
    ..\\..\\batch\\.venv\\Scripts\\python tool/i18n/run_parts.py --lang trfix --parts 1
    python tool/i18n/check_tr_data.py read --results content/batch/trfix_v1_results_part1.jsonl

Sözlükte olmayan yeni kayıtlar için (firebase_missing.py çıktısı gibi {"id", "rec"} satırları):
    python tool/i18n/check_tr_data.py make --recs content/lang/tr/firebase_missing_v1.jsonl --tag fbnew
    ..\\..\\batch\\.venv\\Scripts\\python tool/i18n/run_parts.py --lang fbnew --parts 1
    python tool/i18n/check_tr_data.py read --recs content/lang/tr/firebase_missing_v1.jsonl --tag fbnew \\
        --results content/batch/fbnew_v1_results_part1.jsonl
Bu kipte önerilen başlık sözlükte zaten varsa kayıt büyük olasılıkla yazım hatalı bir tekrardır.

Model her kayda ok / fix / unsure der; fix'te düzeltilmiş harekeli başlık, tür, Türkçe anlam ve hatalı örnek
numaralarını verir. Önerilen başlık kaydın kendi örneklerinde ya da sözlükte geçiyorsa kanıt sayılır.
Çıktı: content/lang/tr/fix_v1.jsonl ve insan incelemesi için duzeltme_listesi_v1.csv (Excel açar).
Veride hiçbir şey değiştirilmez.
"""
import argparse
import collections
import csv
import datetime
import json
import os
import random
import re
import sys
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pilot_prompts import split_anlam  # noqa: E402
from pilot_run import PRICES, call, parse_response  # noqa: E402
from syn_filter import norm  # noqa: E402

MODEL = 'gemini-3.8-flash'
THINKING = os.environ.get('TRFIX_THINKING', 'low')
PACK = 10
TOKENS_PER_CHAR = 0.29
OUT_DIR = 'content/lang/tr'
ISSUES = ('content/lang/ar/data_issues_v1.jsonl', 'content/lang/ar/data_issues_v1r.jsonl')

SYSTEM = """You check entries of a Turkish–Arabic learner's dictionary for data errors. Each entry has an id, the vowelled Arabic headword, its unvowelled form, root, a Turkish part-of-speech label, plural, verb forms, Turkish meanings and numbered example sentences (Arabic with Turkish translation).

verdict:
- "ok": the entry is correct. Rare but real words, valid alternative spellings, modern loanwords and small style issues are ok.
- "fix": there is a clear error and you can say exactly how to correct it.
- "unsure": something is wrong but the correction is not clear.

problems (all that apply):
- "spelling": a wrong letter or dot in the headword (طَلَافَةٌ → طَلَاقَةٌ, غَازِفٌ → عَازِفٌ, يَخْتَضِنُ → يَحْتَضِنُ).
- "vowels": wrong harakat, shadda or hamza that breaks the word or changes it into another word (مُدَرِّسَةٌ written for مَدْرَسَةٌ "school").
- "type": the part-of-speech label is wrong (اُكْتُبْ labelled "Mazî Fiil" instead of "Emir Fiil").
- "meaning": the Turkish meanings do not fit the headword.
- "mixed": the meanings or examples mix two different words spelled alike (وَثُقَ "be firm" given the meaning of وَثِقَ بِهِ "trust").
- "example": an example sentence does not use this word in this meaning, or is ungrammatical.
- "not_a_word": the headword is not Arabic and no correction is clear.

Fields:
- headword_fix: the corrected, fully vowelled headword when spelling or vowels are wrong, otherwise "". Keep the same form (person, number, tense, definiteness, attached pronouns); only repair the error.
- type_fix: the corrected label in the same Turkish style as the input (e.g. "Emir Fiil", "Mazî Fiil", "Muzari Fiil", "İsim", "Sıfat", "Mastar"), otherwise "".
- meaning_fix: corrected Turkish meanings, comma-separated, only when the meanings are wrong for the (corrected) headword, otherwise "".
- bad_examples: numbers of the example sentences that are wrong.
- note_tr: a short Turkish explanation of the problem (at most 15 words); "" when ok.

Headwords are often deliberately inflected forms (case endings such as سَرِيعًا or الْكِتَابِ, duals, plurals, conjugated verbs, attached pronouns or prepositions). That is not an error: never change a headword just to give its base or dictionary form.
Never invent words. Return only JSON matching the schema, one item per entry, same ids, same order."""

SCHEMA = {
    'type': 'OBJECT',
    'properties': {'items': {'type': 'ARRAY', 'items': {
        'type': 'OBJECT',
        'properties': {
            'id': {'type': 'INTEGER'},
            'verdict': {'type': 'STRING', 'enum': ['ok', 'fix', 'unsure']},
            'problems': {'type': 'ARRAY', 'items': {'type': 'STRING', 'enum': [
                'spelling', 'vowels', 'type', 'meaning', 'mixed', 'example', 'not_a_word']}},
            'headword_fix': {'type': 'STRING'},
            'type_fix': {'type': 'STRING'},
            'meaning_fix': {'type': 'STRING'},
            'bad_examples': {'type': 'ARRAY', 'items': {'type': 'INTEGER'}},
            'note_tr': {'type': 'STRING'},
        },
        'required': ['id', 'verdict', 'problems', 'headword_fix', 'type_fix', 'meaning_fix', 'bad_examples', 'note_tr'],
    }}},
    'required': ['items'],
}

PROBLEM_TR = {'spelling': 'yazım', 'vowels': 'hareke', 'type': 'tür', 'meaning': 'anlam', 'mixed': 'iki kelime karışmış',
              'example': 'örnek', 'not_a_word': 'kelime değil'}


def load_jsonl(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding='utf-8') as f:
        return [json.loads(line) for line in f if line.strip()]


def flagged_wids():
    seen = []
    for path in ISSUES:
        for row in load_jsonl(path):
            if row['wid'] not in seen:
                seen.append(row['wid'])
    return seen


def examples_of(rec):
    out = []
    for o in rec.get('ornekCumleler') or []:
        if isinstance(o, dict):
            ar = o.get('arapcaCümle') or o.get('arapcaCumle') or ''
            if ar:
                out.append({'ar': ar, 'tr': o.get('turkceAnlam') or ''})
    return out


def entry(wid, rec):
    gram = rec.get('dilbilgiselOzellikler') or {}
    fiil = rec.get('fiilCekimler') or {}
    meanings, preps = split_anlam(rec.get('anlam'))
    forms = {k: fiil.get(v) for k, v in (('past', 'maziForm'), ('present', 'muzariForm'),
                                         ('masdar', 'mastarForm'), ('imperative', 'emirForm')) if fiil.get(v)}
    return {
        'id': wid,
        'headword': rec.get('harekeliKelime') or rec.get('kelime'),
        'unvowelled': rec.get('kelime') or '',
        'root': rec.get('koku') or '',
        'part_of_speech': gram.get('tur') or '',
        'plural': gram.get('cogulForm') or '',
        'verb_forms': forms,
        'turkish_meanings': meanings,
        'turkish_preposition_meanings': preps,
        'examples': {str(i): e for i, e in enumerate(examples_of(rec))},
    }


def request_body(group, recs):
    return {
        'systemInstruction': {'parts': [{'text': SYSTEM}]},
        'contents': [{'role': 'user', 'parts': [{'text': json.dumps(
            [entry(w, recs[w]) for w in group], ensure_ascii=False)}]}],
        'generationConfig': {
            'responseMimeType': 'application/json',
            'responseSchema': SCHEMA,
            'thinkingConfig': {'thinkingLevel': THINKING},
        },
    }


def load_recs(args=None):
    if args is not None and args.recs:
        return {r['id']: r['rec'] for r in load_jsonl(args.recs)}
    return {r['wid']: r['rec'] for r in load_jsonl('content/master/words.jsonl')}


def base_of(args):
    return f'content/batch/{args.tag}_v1'


def outputs_of(args):
    if args.tag == 'trfix':
        return f'{OUT_DIR}/fix_v1.jsonl', f'{OUT_DIR}/duzeltme_listesi_v1.csv'
    return f'{OUT_DIR}/{args.tag}_check_v1.jsonl', f'{OUT_DIR}/{args.tag}_liste_v1.csv'


def items_of(text):
    try:
        return {it.get('id'): it for it in json.loads(text).get('items', [])}
    except (json.JSONDecodeError, AttributeError):
        return {}


def pilot(args):
    # validate_ar'ın yazdığı sırayla, el ile bakılan örnekle aynı 30 kayıt (seed 7)
    rows = load_jsonl(ISSUES[0])
    random.seed(args.seed)
    sample = [r['wid'] for r in random.sample(rows, args.n)]
    recs, key = load_recs(), os.environ['GEMINI_API_KEY']
    groups = [sample[i:i + PACK] for i in range(0, len(sample), PACK)]

    def run(group):
        text, usage = parse_response(call(MODEL, request_body(group, recs), key))
        return items_of(text), usage

    with ThreadPoolExecutor(4) as ex:
        results = list(ex.map(run, groups))
    items = {k: v for its, _ in results for k, v in its.items()}
    tin = sum(u['in'] for _, u in results)
    tout = sum(u['out'] + u['think'] for _, u in results)
    for i, w in enumerate(sample, 1):
        it = items.get(w) or {}
        head = recs[w].get('harekeliKelime') or recs[w].get('kelime')
        fix = ' → ' + it['headword_fix'] if it.get('headword_fix') else ''
        typ = ' tür→' + it['type_fix'] if it.get('type_fix') else ''
        print(f"{i}. {head}{fix}{typ} | {it.get('verdict')} {it.get('problems')} | {it.get('note_tr', '')}"
              + (f" | anlam: {it['meaning_fix']}" if it.get('meaning_fix') else ''))
    std = PRICES[MODEL]['std']
    print(f'pilot: {len(sample)} kayıt, ${(tin * std[0] + tout * std[1]) / 1e6:.3f}, kayıt başı giriş {tin / len(sample):.0f} / çıkış {tout / len(sample):.0f}')


def make(args):
    recs = load_recs(args)
    wids = list(recs) if args.recs else flagged_wids()
    base = base_of(args)
    os.makedirs('content/batch', exist_ok=True)
    chunks, est_total = {}, 0
    path = f'{base}_part1.jsonl'
    with open(path, 'w', encoding='utf-8') as out:
        for start in range(0, len(wids), PACK):
            group = wids[start:start + PACK]
            body = request_body(group, recs)
            key = f'{args.tag}:{start // PACK:05d}'
            out.write(json.dumps({'key': key, 'request': body}, ensure_ascii=False) + '\n')
            est_total += int(len(json.dumps(body, ensure_ascii=False)) * TOKENS_PER_CHAR)
            chunks[key] = group
    manifest = {'lang': args.tag, 'version': 'v1', 'model': MODEL, 'thinking': THINKING, 'pack': PACK,
                'created': datetime.datetime.now().isoformat(timespec='seconds'), 'words': len(wids),
                'parts': [{'file': path, 'requests': len(chunks), 'words': len(wids), 'est_input_tokens': est_total}],
                'chunks': chunks}
    with open(f'{base}_manifest.json', 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False)
    print(f'{path}: {len(chunks)} istek, {len(wids)} kayıt, ~{est_total / 1e6:.1f} M girdi token')


def evidence(fix, rec, vocab):
    """Önerilen başlık kaydın kendi örneklerinde ya da sözlükte geçiyor mu?"""
    target = norm(fix)
    if not target:
        return ''
    found = []
    for e in examples_of(rec):
        for tok in re.findall(r'[؀-ۿ]+', e['ar']):
            t = norm(tok)
            if t == target or (t.endswith(target) and len(t) - len(target) <= 2):
                found.append('kendi örneğinde geçiyor')
                break
        if found:
            break
    if target in vocab:
        found.append('sözlükte başlık olarak var')
    return ', '.join(found)


def read(args):
    from validate import BATCH_PRICE
    with open(f'{base_of(args)}_manifest.json', encoding='utf-8') as f:
        manifest = json.load(f)
    recs = load_recs(args)
    vocab = {norm(r.get('harekeliKelime') or r.get('kelime') or '') for r in load_recs().values()}
    results, missing, usage = {}, set(), collections.Counter()
    for path in args.results:
        for row in load_jsonl(path):
            wids = manifest['chunks'].get(row.get('key'), [])
            resp = row.get('response')
            if not resp:
                missing.update(wids)
                continue
            meta = resp.get('usageMetadata') or {}
            usage['in'] += meta.get('promptTokenCount', 0)
            usage['out'] += meta.get('candidatesTokenCount', 0) + meta.get('thoughtsTokenCount', 0)
            parts = ((resp.get('candidates') or [{}])[0].get('content') or {}).get('parts') or []
            items = items_of(''.join(p.get('text', '') for p in parts if not p.get('thought')))
            for w in wids:
                if w in items:
                    results[w] = items[w]
                else:
                    missing.add(w)

    os.makedirs(OUT_DIR, exist_ok=True)
    verdicts, problems, proven = collections.Counter(), collections.Counter(), 0
    rows = []
    for w in sorted(results):
        it, rec = results[w], recs[w]
        head = rec.get('harekeliKelime') or rec.get('kelime')
        fix = it['headword_fix'] if it['headword_fix'] and it['headword_fix'] != head else ''
        exs = examples_of(rec)
        # "fix" deyip hiçbir şey önermeyen yanıt (aynı başlığı geri yazmak gibi) ok sayılır
        if it['verdict'] == 'fix' and not (fix or it['type_fix'] or it['meaning_fix'] or it['bad_examples']):
            it['verdict'] = 'ok'
        verdicts[it['verdict']] += 1
        # yeni kayıt kipinde sorunsuzlar da listede kalır (eklenecekler listesi)
        if it['verdict'] == 'ok' and not args.recs:
            continue
        problems.update(it['problems'])
        ev = evidence(fix, rec, vocab) if fix else ''
        proven += bool(ev)
        rows.append({
            'wid': w, 'verdict': it['verdict'], 'problems': it['problems'],
            'headword': head, 'headword_fix': fix, 'evidence': ev,
            'type': (rec.get('dilbilgiselOzellikler') or {}).get('tur') or '', 'type_fix': it['type_fix'],
            'meanings': split_anlam(rec.get('anlam'))[0], 'meaning_fix': it['meaning_fix'],
            'bad_examples': [exs[i]['ar'] for i in it['bad_examples'] if 0 <= i < len(exs)],
            'note_tr': it['note_tr'],
        })
    out_jsonl, out_csv = outputs_of(args)
    with open(out_jsonl, 'w', encoding='utf-8') as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + '\n')
    with open(out_csv, 'w', encoding='utf-8-sig', newline='') as f:
        wr = csv.writer(f, delimiter=';')
        wr.writerow(['wid', 'karar', 'sorun', 'şu anki kelime', 'önerilen kelime', 'kanıt', 'şu anki tür',
                     'önerilen tür', 'şu anki anlam', 'önerilen anlam', 'hatalı örnekler', 'açıklama', 'onay (e/h)'])
        for r in rows:
            wr.writerow([r['wid'], r['verdict'], ', '.join(PROBLEM_TR[p] for p in r['problems']), r['headword'],
                         r['headword_fix'], r['evidence'], r['type'], r['type_fix'], r['meanings'], r['meaning_fix'],
                         ' | '.join(r['bad_examples']), r['note_tr'], ''])
    price = BATCH_PRICE.get(manifest['model'], (0, 0))
    cost = (usage['in'] * price[0] + usage['out'] * price[1]) / 1e6
    with_fix = sum(1 for r in rows if r['headword_fix'])
    print(f"denetlenen {manifest['words']} · ok {verdicts['ok']} · düzeltme {verdicts['fix']} · emin değil {verdicts['unsure']}"
          f" · yanıtsız {len(missing)}")
    print('sorunlar:', {PROBLEM_TR[k]: v for k, v in problems.most_common()})
    print(f'başlık düzeltmesi {with_fix} · kanıtlı {proven} · maliyet ≈ ${cost:.2f}')
    if args.recs:
        dup = sum(1 for r in rows if 'sözlükte' in r['evidence'])
        print(f"yeni kayıt kipi: olduğu gibi eklenebilir {verdicts['ok']} · düzeltilerek {verdicts['fix'] - dup}"
              f" · sözlükteki kelimenin hatalı tekrarı {dup} · emin değil {verdicts['unsure']}")


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('action', choices=['pilot', 'make', 'read'])
    ap.add_argument('--seed', type=int, default=7)
    ap.add_argument('--n', type=int, default=30)
    ap.add_argument('--results', nargs='*', default=[])
    ap.add_argument('--recs', default=None, help='sözlükte olmayan kayıtlar: {"id", "rec"} satırları')
    ap.add_argument('--tag', default='trfix', help='batch/çıktı adı (yeni kayıtlar için ör. fbnew)')
    args = ap.parse_args()
    {'pilot': pilot, 'make': make, 'read': read}[args.action](args)


if __name__ == '__main__':
    main()
