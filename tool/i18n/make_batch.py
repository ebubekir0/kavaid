"""Tam üretim için Gemini Batch API girdi dosyalarını üretir (gönderMEZ).

Kullanım (kavaid klasöründen):
    python tool/i18n/build_master.py          # önce wid'ler
    python tool/i18n/make_batch.py --lang en  # content/batch/en_v1_part<N>.jsonl + manifest

Her satır bir istektir: {"key": "<dil>:<parça no>", "request": {...generateContent gövdesi...}}
ve tek istekte --pack kadar kelime taşır. Parçalar, hesap seviyesindeki batch kuyruğu
sınırını (Tier 1'de gemini-3.1-flash-lite için 10 M token) aşmasın diye --max-part-tokens
ile bölünür. Manifest, her istek anahtarının hangi wid'leri taşıdığını tutar; sonuçlar
validate.py ile bu manifest üzerinden wid'lere eşlenir.

İngilizce dışındaki diller İngilizce sonuçları ipucu olarak kullanır (--hint-from).
"""
import argparse
import datetime
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pilot_prompts_v2 import build_batch_request  # noqa: E402
import pilot_ar3  # noqa: E402

WORDS = 'content/master/words.jsonl'
OUT_DIR = 'content/batch'
# countTokens ile 40 gerçek istekte ölçüldü (ortalama 2.779 token / 10 kelimelik istek):
# bu istem biçiminde ~3,4 karakter = 1 token.
TOKENS_PER_CHAR = 0.291


def load_hints(path):
    hints = {}
    with open(path, encoding='utf-8') as f:
        for line in f:
            row = json.loads(line)
            hints[row['wid']] = row['result']
    return hints


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--lang', required=True)
    ap.add_argument('--version', default='v1')
    ap.add_argument('--model', default='gemini-3.1-flash-lite')
    ap.add_argument('--thinking', default=None, help='varsayılan: ar için low, diğerleri minimal')
    ap.add_argument('--pack', type=int, default=10)
    # Kuyruk sınırı (10 M) çıktıyı da sayıyor olabilir; parça başına ~6 M girdi güvenli pay bırakır.
    ap.add_argument('--max-part-tokens', type=int, default=6_000_000)
    ap.add_argument('--hint-from', default=None, help='İngilizce kabul edilmiş sonuçlar (content/lang/en/dict_v1.jsonl)')
    ap.add_argument('--data-check', action='store_true', help='veri hatası işaretini iste (İngilizcede varsayılan açık)')
    ap.add_argument('--limit', type=int, default=0, help='yalnız ilk N kelime (deneme için)')
    ap.add_argument('--prompt', default=None, choices=['v5'],
                    help="ar için kartın son hali: numaralı anlamlar + örnek + harf-i cer (pilot_ar3.SYSTEM_ARABIC_V5)")
    ap.add_argument('--wids', default=None,
                    help='yalnız bu wid\'ler (validate.py/check_mixups.py requeue .jsonl dosyası); yeniden üretim için')
    args = ap.parse_args()

    thinking = args.thinking or ('low' if args.lang == 'ar' else 'minimal')
    data_check = args.data_check or args.lang == 'en'
    hints = load_hints(args.hint_from) if args.hint_from else None
    if args.lang != 'en' and hints is None:
        sys.exit('İngilizce dışındaki diller için --hint-from gerekli (önce İngilizce üretilmeli).')

    with open(WORDS, encoding='utf-8') as f:
        words = [json.loads(line) for line in f]
    if args.wids:
        with open(args.wids, encoding='utf-8') as f:
            wanted = {json.loads(line)['wid'] for line in f if line.strip()}
        words = [w for w in words if w['wid'] in wanted]
    if args.prompt == 'v5':
        # İngilizce ipucu olmayan kayıtlar (çöp/çözülemeyen, 9 tane) üretilmez
        words = [w for w in words if w['wid'] in hints]
    if args.limit:
        words = words[:args.limit]

    os.makedirs(OUT_DIR, exist_ok=True)
    base = f'{args.lang}_{args.version}'
    chunks, parts = {}, []
    part_no, part_tokens, part_lines, out = 0, 0, 0, None
    for start in range(0, len(words), args.pack):
        group = words[start:start + args.pack]
        entries = [(w['wid'], w['rec'], hints.get(w['wid']) if hints else None) for w in group]
        if args.prompt == 'v5':
            body = pilot_ar3.build_request(entries, thinking, pilot_ar3.SYSTEM_ARABIC_V5, pilot_ar3.SCHEMA_ARABIC_V5)
        else:
            body = build_batch_request(entries, args.lang, thinking, data_check=data_check)
        key = f'{args.lang}:{start // args.pack:05d}'
        line = json.dumps({'key': key, 'request': body}, ensure_ascii=False)
        est = int(len(json.dumps(body, ensure_ascii=False)) * TOKENS_PER_CHAR)
        if out is None or part_tokens + est > args.max_part_tokens:
            if out:
                out.close()
            part_no += 1
            path = os.path.join(OUT_DIR, f'{base}_part{part_no}.jsonl')
            out = open(path, 'w', encoding='utf-8')
            parts.append({'file': path, 'requests': 0, 'words': 0, 'est_input_tokens': 0})
            part_tokens = 0
        out.write(line + '\n')
        part_tokens += est
        parts[-1]['requests'] += 1
        parts[-1]['words'] += len(group)
        parts[-1]['est_input_tokens'] += est
        chunks[key] = [w['wid'] for w in group]
    if out:
        out.close()

    manifest = {
        'lang': args.lang, 'version': args.version, 'model': args.model, 'thinking': thinking,
        'pack': args.pack, 'data_check': data_check or args.prompt == 'v5', 'hint_from': args.hint_from,
        'prompt': args.prompt,
        'created': datetime.datetime.now().isoformat(timespec='seconds'),
        'words': len(words), 'parts': parts, 'chunks': chunks,
    }
    with open(os.path.join(OUT_DIR, f'{base}_manifest.json'), 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False)
    for p in parts:
        size = os.path.getsize(p['file']) / 1e6
        print(f"{p['file']}: {p['requests']} istek, {p['words']} kelime, ~{p['est_input_tokens'] / 1e6:.1f} M girdi token, {size:.0f} MB")
    print(f'manifest: {OUT_DIR}/{base}_manifest.json ({len(chunks)} istek, {len(words)} kelime)')


if __name__ == '__main__':
    main()
