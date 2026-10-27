"""Arapça–Arapça hakem turu: kabul edilen maddeleri ucuz bir modelle denetletip şüphelileri ayırır.

Kullanım (kavaid klasöründen):
    python tool/i18n/judge_ar.py make                 # content/batch/arjudge_v1_part<N>.jsonl + manifest
    ..\\..\\batch\\.venv\\Scripts\\python tool/i18n/run_parts.py --lang arjudge --parts 1 2
    python tool/i18n/judge_ar.py read --results content/batch/arjudge_v1_results_part1.jsonl [...]
                                                      # content/lang/ar/requeue_judge_v1.jsonl

Hakem yalnız açık hataları işaretler (yanlış anlam, başka kelimeyle karışma, anlam yerine biçim
anlatma, uydurma harf-i cerli kullanım); üslup ve eksik nadir anlam hata sayılmaz. İşaretlenenler
make_batch.py --wids ile güçlü modelde tek tek yeniden üretilir.
"""
import argparse
import datetime
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pilot_prompts import word_payload  # noqa: E402

MODEL = 'gemini-3.1-flash-lite'
PACK = 20
MAX_PART_TOKENS = 8_000_000
TOKENS_PER_CHAR = 0.29
BASE = 'content/batch/arjudge_v1'  # --version ile değişir (yeni kelimeler: v1n)

SYSTEM = """You review entries of a modern Arabic–Arabic learner's dictionary. Each entry has an id, the vowelled headword (it may be an inflected form), its part of speech (Turkish label), English hint meanings, its Arabic definitions ("senses") and preposition usages ("preps").

For each entry decide "ok":
- false ONLY when there is a clear error: a definition gives a meaning the vowelled headword does not have, mixes in another word spelled alike (دِين/دَيْن), describes the grammatical form instead of the meaning, contradicts the hint meanings, or a preposition usage does not exist or is explained wrongly.
- true otherwise. Do not fail entries for style, for missing rare senses, or for small wording issues.
"reason": when ok is false, a short English reason (at most 12 words); otherwise "".

Return only JSON that matches the schema, one item per entry, same ids, same order."""

SCHEMA = {
    'type': 'OBJECT',
    'properties': {'items': {'type': 'ARRAY', 'items': {
        'type': 'OBJECT',
        'properties': {'id': {'type': 'INTEGER'}, 'ok': {'type': 'BOOLEAN'}, 'reason': {'type': 'STRING'}},
        'required': ['id', 'ok', 'reason'],
    }}},
    'required': ['items'],
}


def load_jsonl(path):
    with open(path, encoding='utf-8') as f:
        return [json.loads(line) for line in f if line.strip()]


def make(args):
    dict_rows = load_jsonl(f'content/lang/ar/dict_{args.version}.jsonl')
    recs = {r['wid']: r['rec'] for r in load_jsonl('content/master/words.jsonl')}
    hints = {r['wid']: r['result'] for r in load_jsonl('content/lang/en/dict_final.jsonl')}
    os.makedirs('content/batch', exist_ok=True)
    chunks, parts = {}, []
    out, part_tokens = None, 0
    for start in range(0, len(dict_rows), PACK):
        group = dict_rows[start:start + PACK]
        payload = []
        for row in group:
            p = word_payload(recs[row['wid']])
            payload.append({
                'id': row['wid'],
                'headword': p['headword'],
                'part_of_speech': p['part_of_speech'],
                'hint_meanings': ', '.join((hints.get(row['wid']) or {}).get('senses', [])),
                'senses': [s['d'] for s in row['result']['senses']],
                'preps': [p_['m'] for p_ in row['result']['preps']],
            })
        body = {
            'systemInstruction': {'parts': [{'text': SYSTEM}]},
            'contents': [{'role': 'user', 'parts': [{'text': json.dumps(payload, ensure_ascii=False)}]}],
            'generationConfig': {
                'responseMimeType': 'application/json',
                'responseSchema': SCHEMA,
                'thinkingConfig': {'thinkingLevel': 'low'},
            },
        }
        key = f'arjudge:{start // PACK:05d}'
        est = int(len(json.dumps(body, ensure_ascii=False)) * TOKENS_PER_CHAR)
        if out is None or part_tokens + est > MAX_PART_TOKENS:
            if out:
                out.close()
            path = f'{BASE}_part{len(parts) + 1}.jsonl'
            out = open(path, 'w', encoding='utf-8')
            parts.append({'file': path, 'requests': 0, 'words': 0, 'est_input_tokens': 0})
            part_tokens = 0
        out.write(json.dumps({'key': key, 'request': body}, ensure_ascii=False) + '\n')
        part_tokens += est
        parts[-1]['requests'] += 1
        parts[-1]['words'] += len(group)
        parts[-1]['est_input_tokens'] += est
        chunks[key] = [r['wid'] for r in group]
    if out:
        out.close()
    manifest = {'lang': 'arjudge', 'version': args.version, 'model': MODEL, 'pack': PACK,
                'created': datetime.datetime.now().isoformat(timespec='seconds'),
                'words': len(dict_rows), 'parts': parts, 'chunks': chunks}
    with open(f'{BASE}_manifest.json', 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False)
    for p in parts:
        print(f"{p['file']}: {p['requests']} istek, {p['words']} kelime, ~{p['est_input_tokens'] / 1e6:.1f} M girdi token")


def read(args):
    with open(f'{BASE}_manifest.json', encoding='utf-8') as f:
        manifest = json.load(f)
    flagged, missing, usage = {}, set(), {'in': 0, 'out': 0}
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
            text = ''.join(p.get('text', '') for p in parts if not p.get('thought'))
            try:
                items = {it.get('id'): it for it in json.loads(text).get('items', [])}
            except (json.JSONDecodeError, AttributeError):
                items = {}
            for w in wids:
                it = items.get(w)
                if it is None:
                    missing.add(w)
                elif not it.get('ok', True):
                    flagged[w] = it.get('reason') or 'hakem'
    with open(f'content/lang/ar/requeue_judge_{args.version}.jsonl', 'w', encoding='utf-8') as f:
        for w in sorted(flagged):
            f.write(json.dumps({'wid': w, 'reasons': ['hakem: ' + flagged[w]]}, ensure_ascii=False) + '\n')
    cost = (usage['in'] * 0.125 + usage['out'] * 0.75) / 1e6
    print(f"denetlenen {manifest['words']} · işaretlenen {len(flagged)} (%{100 * len(flagged) / max(1, manifest['words']):.1f})"
          f" · yanıtsız {len(missing)} · hakem maliyeti ≈ ${cost:.2f}")


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('action', choices=['make', 'read'])
    ap.add_argument('--results', nargs='*', default=[])
    ap.add_argument('--version', default='v1')
    args = ap.parse_args()
    global BASE
    BASE = f'content/batch/arjudge_{args.version}'
    make(args) if args.action == 'make' else read(args)


if __name__ == '__main__':
    main()
