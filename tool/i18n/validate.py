"""Batch sonuçlarını wid'lere eşler, otomatik kontrolleri ve biçim düzeltmelerini yapar.

Kullanım (kavaid klasöründen):
    python tool/i18n/validate.py --lang en --results content/batch/en_v1_results_part1.jsonl [...]

Girdi : Gemini Batch API çıktısı (her satır {"key", "response"} ya da {"key", "error"})
        content/batch/<dil>_<sürüm>_manifest.json (istek anahtarı -> wid listesi)
Çıktı : content/lang/<dil>/dict_<sürüm>.jsonl        kabul edilen {"wid", "result"}
        content/lang/<dil>/requeue_<sürüm>.jsonl     yeniden üretilecek {"wid", "reasons"}
        content/lang/<dil>/data_issues_<sürüm>.jsonl Türkçe veride sorun işaretlenenler
Kabul edilenler üzerinde biçim düzeltmeleri yapılır: virgüllü anlam bölünür, "..." -> "…",
tekrar eden anlam silinir, editör listesinde olmayan harf-i cer "added": true olur.
Karışma kontrolü (anlam ↔ ipucu benzerliği) ayrıca check_mixups.py ile yapılır.
"""
import argparse
import collections
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pilot_prompts import word_payload  # noqa: E402

ARABIC = re.compile('[؀-ۿ]')
LATIN = re.compile('[A-Za-z]{3,}')
# Harf sınıfı büyük/küçük harf duyarlı kalmalı: IGNORECASE altında ı/İ, İngilizce i/I ile eşleşir.
TURKISH_CHARS = re.compile('[ğĞşŞıİ]')
TURKISH_WORDS = re.compile(r'\b(ve|bir|etmek|olmak|için|namaz|vacip|abdest|oruç|dalgın|yakarış|başkası|diğerleri)\b', re.I)
ENGLISH_SENSE = re.compile(r"^(to |she |he |they |we |I |you |it |and he |and she |was |is |were |are being |is being )", re.I)
HARAKAT = re.compile(r'[ً-ْٰـ]')
ARABIC_SCRIPT = {'ar', 'ur', 'fa'}
# Pilot ölçümü: gemini-3.1-flash-lite batch fiyatı (1 M token başına USD).
BATCH_PRICE = {'gemini-3.1-flash-lite': (0.125, 0.75), 'gemini-3.8-flash': (0.375, 1.875)}


def norm_harf(h):
    return HARAKAT.sub('', h).replace('ـ', '').strip()


def problems(lang, item, rec):
    """Yeniden üretim gerektiren sorunlar (boş liste = kabul)."""
    found = []
    senses, preps, examples = item.get('senses'), item.get('preps'), item.get('examples')
    if not isinstance(senses, list) or not isinstance(preps, list) or not isinstance(examples, list):
        return ['şema dışı']
    if not [s for s in senses if isinstance(s, str) and s.strip()]:
        found.append('boş anlam')
    text = ' '.join(senses + examples + [m for p in preps for m in p.get('m', [])])
    if lang in ARABIC_SCRIPT:
        if LATIN.search(text):
            found.append('Latin harf')
    else:
        if ARABIC.search(text):
            found.append('Arap harfi / çevrilmemiş')
        if TURKISH_CHARS.search(text) or TURKISH_WORDS.search(text):
            found.append('Türkçe sızıntı')
    if lang not in ('en',) and lang not in ARABIC_SCRIPT:
        if sum(1 for s in senses if ENGLISH_SENSE.match(s.strip())) >= max(1, len(senses) // 2):
            found.append('anlamlar İngilizce kalmış')
    if len(examples) != len(word_payload(rec)['examples']):
        found.append('örnek sayısı tutmuyor')
    return found


def tidy(item, rec):
    """Kabul edilen kayıtta otomatik biçim düzeltmeleri."""
    senses, seen = [], set()
    for s in item['senses']:
        for part in re.split(r'\s*[,،;]\s*', s):
            part = part.strip()
            if part and part.lower() not in seen:
                seen.add(part.lower())
                senses.append(part)
    editor = {norm_harf(h) for h in word_payload(rec)['editor_prepositions']}
    preps = []
    for p in item['preps']:
        h = p.get('h', '').strip()
        meanings = [m.replace('...', '…').strip() for m in p.get('m', []) if m.strip()]
        if not h or not meanings:
            continue
        preps.append({'h': h, 'm': meanings, 'added': bool(p.get('added')) or norm_harf(h) not in editor})
    out = {'senses': senses[:12], 'preps': preps, 'examples': [e.strip() for e in item['examples']]}
    if 'data_issue' in item:
        out['data_issue'] = bool(item['data_issue'])
    return out


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--lang', required=True)
    ap.add_argument('--version', default='v1')
    ap.add_argument('--results', nargs='+', required=True)
    args = ap.parse_args()

    with open(f'content/batch/{args.lang}_{args.version}_manifest.json', encoding='utf-8') as f:
        manifest = json.load(f)
    with open('content/master/words.jsonl', encoding='utf-8') as f:
        recs = {row['wid']: row['rec'] for row in map(json.loads, f)}

    accepted, requeue, issues = {}, {}, []
    usage = collections.Counter()
    reasons = collections.Counter()
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
                    found = problems(args.lang, item, recs[w])
                    if found:
                        requeue[w] = found
                        reasons.update(found)
                        continue
                    accepted[w] = tidy(item, recs[w])
                    if accepted[w].get('data_issue'):
                        pay = word_payload(recs[w])
                        issues.append({'wid': w, 'headword': pay['headword'], 'tur': pay['part_of_speech'],
                                       'turkish': pay['turkish_meanings'], 'examples': pay['examples']})

    expected = {w for ws in manifest['chunks'].values() for w in ws}
    for w in expected - accepted.keys() - requeue.keys():
        requeue[w] = ['sonuç dosyasında yok']
        reasons['sonuç dosyasında yok'] += 1

    out_dir = f'content/lang/{args.lang}'
    os.makedirs(out_dir, exist_ok=True)
    with open(f'{out_dir}/dict_{args.version}.jsonl', 'w', encoding='utf-8') as f:
        for w in sorted(accepted):
            f.write(json.dumps({'wid': w, 'result': accepted[w]}, ensure_ascii=False) + '\n')
    with open(f'{out_dir}/requeue_{args.version}.jsonl', 'w', encoding='utf-8') as f:
        for w in sorted(requeue):
            f.write(json.dumps({'wid': w, 'reasons': requeue[w]}, ensure_ascii=False) + '\n')
    with open(f'{out_dir}/data_issues_{args.version}.jsonl', 'w', encoding='utf-8') as f:
        for row in issues:
            f.write(json.dumps(row, ensure_ascii=False) + '\n')

    price = BATCH_PRICE.get(manifest['model'], (0, 0))
    cost = (usage['in'] * price[0] + usage['out'] * price[1]) / 1e6
    print(f'beklenen {len(expected)} · kabul {len(accepted)} · yeniden üretim {len(requeue)} · veri sorunu {len(issues)}')
    print('yeniden üretim nedenleri:', dict(reasons))
    print(f'token: girdi {usage["in"]:,} · çıktı {usage["out"]:,} · batch maliyeti ≈ ${cost:.2f}')


if __name__ == '__main__':
    main()
