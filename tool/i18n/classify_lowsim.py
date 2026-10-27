"""check_mixups.py'nin düşük benzerlik listesini ikiye ayırır:
  - gerçek karışma: üretilen anlam, aynı istekteki başka bir kelimenin ipucuna kendi
    ipucundan belirgin şekilde daha çok benziyor → yeniden üretim
  - inceleme: komşulardan birine de benzemiyor → büyük olasılıkla Türkçe veri hatası
    ya da kelimenin başka bir anlamı; insan incelemesi / Türkçe veri temizliği

Kullanım (kavaid klasöründen):
    $env:GEMINI_API_KEY = "..."
    python tool/i18n/classify_lowsim.py --lang en

Çıktı: content/lang/<dil>/mixups_real_<sürüm>.jsonl  (make_batch.py --wids girdisi)
       content/lang/<dil>/review_lowsim_<sürüm>.jsonl
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_mixups import cosine, embed  # noqa: E402
from pilot_prompts import split_anlam  # noqa: E402
import concurrent.futures  # noqa: E402

MARGIN = 0.08


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--lang', required=True)
    ap.add_argument('--version', default='v1')
    args = ap.parse_args()
    key = os.environ.get('GEMINI_API_KEY') or sys.exit('GEMINI_API_KEY ortam değişkeni yok.')
    d = f'content/lang/{args.lang}'

    with open(f'content/batch/{args.lang}_{args.version}_manifest.json', encoding='utf-8') as f:
        chunks = json.load(f)['chunks']
    chunk_of = {w: ws for ws in chunks.values() for w in ws}
    with open('content/master/words.jsonl', encoding='utf-8') as f:
        recs = {r['wid']: r['rec'] for r in map(json.loads, f)}
    with open(f'{d}/dict_{args.version}.jsonl', encoding='utf-8') as f:
        results = {r['wid']: r['result'] for r in map(json.loads, f)}
    with open(f'{d}/mixups_{args.version}.jsonl', encoding='utf-8') as f:
        low = {r['wid']: r['score'] for r in map(json.loads, f)}

    hint = lambda w: split_anlam(recs[w].get('anlam'))[0]
    texts = set()
    for w in low:
        texts.add(', '.join(results[w]['senses']))
        texts.update(hint(n) for n in chunk_of[w] if n != w and hint(n))
    texts = sorted(texts)
    with concurrent.futures.ThreadPoolExecutor(16) as ex:
        vec = dict(zip(texts, ex.map(lambda t: embed(t, key), texts)))

    real, review = [], []
    for w, own in sorted(low.items(), key=lambda kv: kv[1]):
        mine = vec[', '.join(results[w]['senses'])]
        best, best_w = -1, None
        for n in chunk_of[w]:
            if n != w and hint(n):
                s = cosine(mine, vec[hint(n)])
                if s > best:
                    best, best_w = s, n
        row = {'wid': w, 'score': own, 'neighbor': best_w, 'neighbor_score': round(best, 3),
               'headword': recs[w].get('harekeliKelime'), 'en': results[w]['senses'], 'turkish': hint(w)}
        if best - own > MARGIN:
            row['reasons'] = ['karışma']
            real.append(row)
        else:
            review.append(row)
    for name, rows in (('mixups_real', real), ('review_lowsim', review)):
        with open(f'{d}/{name}_{args.version}.jsonl', 'w', encoding='utf-8') as f:
            for row in rows:
                f.write(json.dumps(row, ensure_ascii=False) + '\n')
    print(f'düşük benzerlik {len(low)} · gerçek karışma {len(real)} · inceleme {len(review)}')
    for row in real[:8]:
        print(f"  karışma: {row['headword']} -> {', '.join(row['en'])[:40]} "
              f"(kendi {row['score']:.2f}, komşu {recs[row['neighbor']].get('harekeliKelime')} {row['neighbor_score']:.2f})")


if __name__ == '__main__':
    main()
