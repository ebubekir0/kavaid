"""Arapça–Arapça batch sonuçlarını (v5 istem: numaralı anlamlar + örnek + harf-i cer) denetler.

Kullanım (kavaid klasöründen):
    python tool/i18n/validate_ar.py --results content/batch/ar_v1_results_part1.jsonl [...]

Çıktı : content/lang/ar/dict_<sürüm>.jsonl        kabul edilen {"wid", "result"}
        content/lang/ar/requeue_<sürüm>.jsonl     yeniden üretilecek {"wid", "reasons"}
        content/lang/ar/data_issues_<sürüm>.jsonl Türkçe veride sorun işaretlenenler
Denetimler: anlam var mı, yalnız Arap yazısı mı, tanım başlığın kendisi mi, ayet parantezi,
örnek numarası geçerli mi, örneği olmayan anlama örnek yazılmış mı, harf-i cer boş mu.
"""
import argparse
import collections
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pilot_prompts import word_payload  # noqa: E402
from syn_filter import norm  # noqa: E402
from validate import BATCH_PRICE  # noqa: E402

LATIN = re.compile(r'[A-Za-zÀ-ɏ]')
MAX_SENSES = 6
MAX_DEF_WORDS = 30
MAX_EXT_WORDS = 14


def problems(item, rec):
    found = []
    head = rec.get('harekeliKelime') or rec.get('kelime') or ''
    n_examples = len(word_payload(rec)['examples'])
    senses = item.get('senses') or []
    if not senses:
        return ['anlam yok']
    if len(senses) > MAX_SENSES:
        found.append('çok fazla anlam')
    for s in senses:
        d = (s.get('d') or '').strip()
        ext = (s.get('ext') or '').strip()
        ex = s.get('ex')
        if not d:
            found.append('boş tanım')
        elif norm(d.rstrip('.')) == norm(head):
            found.append('tanım başlığın kendisi')
        if len(d.split()) > MAX_DEF_WORDS:
            found.append('tanım çok uzun')
        if not isinstance(ex, int) or ex < -1 or ex >= n_examples:
            found.append('örnek numarası geçersiz')
        if ex == -1 and not ext:
            found.append('örnek yok')
        if ext and len(ext.split()) > MAX_EXT_WORDS:
            found.append('yazılan örnek uzun')
    for p in item.get('preps') or []:
        if not (p.get('m') or '').strip():
            found.append('boş harf-i cer')
    text = json.dumps({'s': senses, 'p': item.get('preps') or []}, ensure_ascii=False)
    values = ' '.join(v for s in senses for v in (s.get('d') or '', s.get('ext') or '')) + ' ' + \
        ' '.join(p.get('m') or '' for p in item.get('preps') or [])
    if LATIN.search(values):
        found.append('Latin harf')
    if '﴿' in text or '﴾' in text:
        found.append('ayet parantezi')
    return sorted(set(found))


def tidy(item):
    return {
        'senses': [{'d': s['d'].strip(), 'ex': s['ex'], 'ext': (s.get('ext') or '').strip()} for s in item['senses']],
        'preps': [{'h': p['h'].strip(), 'm': p['m'].strip()} for p in item.get('preps') or []],
        'data_issue': bool(item.get('data_issue')),
    }


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--version', default='v1')
    ap.add_argument('--results', nargs='+', required=True)
    args = ap.parse_args()

    with open(f'content/batch/ar_{args.version}_manifest.json', encoding='utf-8') as f:
        manifest = json.load(f)
    with open('content/master/words.jsonl', encoding='utf-8') as f:
        recs = {row['wid']: row['rec'] for row in map(json.loads, f)}

    accepted, requeue, issues = {}, {}, []
    usage, reasons = collections.Counter(), collections.Counter()
    for path in args.results:
        with open(path, encoding='utf-8') as f:
            for line in f:
                if not line.strip():
                    continue
                row = json.loads(line)
                wids = manifest['chunks'].get(row.get('key'), [])
                resp = row.get('response')
                if not resp:
                    for w in wids:
                        requeue[w] = ['istek başarısız']
                    reasons['istek başarısız'] += len(wids)
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
                    item = items.get(w)
                    if item is None:
                        requeue[w] = ['yanıtta yok']
                        reasons['yanıtta yok'] += 1
                        continue
                    found = problems(item, recs[w])
                    if found:
                        requeue[w] = found
                        reasons.update(found)
                        continue
                    accepted[w] = tidy(item)
                    if accepted[w]['data_issue']:
                        pay = word_payload(recs[w])
                        issues.append({'wid': w, 'headword': pay['headword'], 'tur': pay['part_of_speech'],
                                       'turkish': pay['turkish_meanings'], 'examples': pay['examples']})

    expected = {w for ws in manifest['chunks'].values() for w in ws}
    for w in expected - accepted.keys() - requeue.keys():
        requeue[w] = ['sonuç dosyasında yok']
        reasons['sonuç dosyasında yok'] += 1

    out_dir = 'content/lang/ar'
    os.makedirs(out_dir, exist_ok=True)
    for name, rows in (('dict', [{'wid': w, 'result': accepted[w]} for w in sorted(accepted)]),
                       ('requeue', [{'wid': w, 'reasons': requeue[w]} for w in sorted(requeue)]),
                       ('data_issues', issues)):
        with open(f'{out_dir}/{name}_{args.version}.jsonl', 'w', encoding='utf-8') as f:
            for row in rows:
                f.write(json.dumps(row, ensure_ascii=False) + '\n')

    price = BATCH_PRICE.get(manifest['model'], (0, 0))
    cost = (usage['in'] * price[0] + usage['out'] * price[1]) / 1e6
    print(f'beklenen {len(expected)} · kabul {len(accepted)} · yeniden üretim {len(requeue)} · veri sorunu {len(issues)}')
    print('yeniden üretim nedenleri:', dict(reasons))
    print(f'token: girdi {usage["in"]:,} · çıktı {usage["out"]:,} · batch maliyeti ≈ ${cost:.2f}')


if __name__ == '__main__':
    main()
