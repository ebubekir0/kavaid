"""Toplu istekte kelime karışmasını yakalar: her kelimenin üretilen anlamlarını kendi
ipucu anlamlarıyla (İngilizce için Türkçe, diğer diller için İngilizce) gömme
benzerliğiyle karşılaştırır; eşiğin altında kalanlar yeniden üretime gider.

Kullanım (kavaid klasöründen):
    $env:GEMINI_API_KEY = "..."
    python tool/i18n/check_mixups.py --lang en                    # İngilizce ↔ Türkçe
    python tool/i18n/check_mixups.py --lang fr --hint-from content/lang/en/dict_v1.jsonl

Çıktı: content/lang/<dil>/mixups_<sürüm>.jsonl ({"wid", "score", "reasons"}); bu dosya
make_batch.py --wids ile doğrudan yeniden üretim girdisi olur.
Maliyet: gemini-embedding-2, kelime başına ~2 kısa metin (~50 token) → 55 bin kelime ≈ $0,5.
"""
import argparse
import concurrent.futures
import hashlib
import json
import math
import os
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pilot_prompts import split_anlam  # noqa: E402

MODEL = 'gemini-embedding-2'
API = f'https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:embedContent'
# Pilot 200 kelimeden kalibre edildi (bkz. plan 5.2.8): bilinen karışma bu eşiğin altında kalıyor.
DEFAULT_THRESHOLD = 0.55


def embed(text, key, retries=5):
    body = json.dumps({'content': {'parts': [{'text': text}]}}).encode('utf-8')
    req = urllib.request.Request(API, data=body, method='POST',
                                 headers={'Content-Type': 'application/json', 'x-goog-api-key': key})
    delay = 2
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return json.loads(resp.read())['embedding']['values']
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError):
            if attempt == retries - 1:
                raise
            time.sleep(delay)
            delay *= 2


def cosine(a, b):
    dot = sum(x * y for x, y in zip(a, b))
    return dot / (math.sqrt(sum(x * x for x in a)) * math.sqrt(sum(y * y for y in b)))


def scores(pairs, key, workers=16):
    """pairs: {wid: (üretilen metin, ipucu metni)} -> {wid: benzerlik}"""
    texts = sorted({t for pair in pairs.values() for t in pair})
    with concurrent.futures.ThreadPoolExecutor(workers) as ex:
        vectors = dict(zip(texts, ex.map(lambda t: embed(t, key), texts)))
    return {w: cosine(vectors[a], vectors[b]) for w, (a, b) in pairs.items()}


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--lang', required=True)
    ap.add_argument('--version', default='v1')
    ap.add_argument('--hint-from', default=None)
    ap.add_argument('--threshold', type=float, default=DEFAULT_THRESHOLD)
    args = ap.parse_args()
    key = os.environ.get('GEMINI_API_KEY') or sys.exit('GEMINI_API_KEY ortam değişkeni yok.')

    with open(f'content/lang/{args.lang}/dict_{args.version}.jsonl', encoding='utf-8') as f:
        results = {row['wid']: row['result'] for row in map(json.loads, f)}
    if args.hint_from:
        with open(args.hint_from, encoding='utf-8') as f:
            hints = {row['wid']: ', '.join(row['result']['senses']) for row in map(json.loads, f)}
    else:
        with open('content/master/words.jsonl', encoding='utf-8') as f:
            hints = {row['wid']: split_anlam(row['rec'].get('anlam'))[0] for row in map(json.loads, f)}

    pairs = {w: (', '.join(r['senses']), hints[w]) for w, r in results.items() if hints.get(w) and r['senses']}
    # Önbellek: aynı metin çifti bir daha ölçülüp ödenmesin (parçalar geldikçe çalıştırılabilir).
    cache_path = f'content/lang/{args.lang}/mixup_scores_{args.version}.json'
    cache = {}
    if os.path.exists(cache_path):
        with open(cache_path, encoding='utf-8') as f:
            cache = json.load(f)
    sig = {w: hashlib.sha1('\n'.join(p).encode('utf-8')).hexdigest()[:12] for w, p in pairs.items()}
    todo = {w: p for w, p in pairs.items() if cache.get(str(w), [None])[0] != sig[w]}
    print(f'{len(pairs)} kelime, önbellekte {len(pairs) - len(todo)}, ölçülecek {len(todo)}')
    for w, s in scores(todo, key).items():
        cache[str(w)] = [sig[w], s]
    with open(cache_path, 'w', encoding='utf-8') as f:
        json.dump(cache, f)
    sc = {w: cache[str(w)][1] for w in pairs}
    low = sorted((s, w) for w, s in sc.items() if s < args.threshold)
    path = f'content/lang/{args.lang}/mixups_{args.version}.jsonl'
    with open(path, 'w', encoding='utf-8') as f:
        for s, w in low:
            f.write(json.dumps({'wid': w, 'score': round(s, 3), 'reasons': ['karışma şüphesi']}, ensure_ascii=False) + '\n')
    print(f'{len(sc)} kelime ölçüldü · eşik {args.threshold} altında {len(low)} (%{100 * len(low) / max(1, len(sc)):.1f}) -> {path}')


if __name__ == '__main__':
    main()
