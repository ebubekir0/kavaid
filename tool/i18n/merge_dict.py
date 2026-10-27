"""Ana üretimin kabul edilenleriyle yeniden üretimin kabul edilenlerini birleştirir.

Kullanım (kavaid klasöründen):
    python tool/i18n/merge_dict.py --lang en --base v1 --fix v1r

Yeniden üretim tek kelimelik istekle yapılır (yanında başka kelime yok, karışma olamaz);
kabul edildiyse ana sürümün yerine o kullanılır. Düşük benzerlik listesindeki kelimeler
yeniden üretimden sonra da düşük benzerlik veriyorsa sorun büyük olasılıkla Türkçe veride:
bunlar inceleme listesine yazılır. Çıktı:
    content/lang/<dil>/dict_final.jsonl    her wid için tek kayıt
    content/lang/<dil>/unresolved.jsonl    iki turda da kabul edilmeyen wid'ler
    content/lang/<dil>/review.jsonl        düşük benzerlik (Türkçe veri / anlam incelemesi)
"""
import argparse
import json
import os
import sys


def read_jsonl(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding='utf-8') as f:
        return [json.loads(line) for line in f if line.strip()]


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--lang', required=True)
    ap.add_argument('--base', default='v1')
    ap.add_argument('--fix', default='v1r')
    ap.add_argument('--also', nargs='*', default=[],
                    help='ek yeniden üretim listeleri (ör. hakem: content/lang/ar/requeue_judge_v1.jsonl)')
    args = ap.parse_args()
    d = f'content/lang/{args.lang}'

    base = {r['wid']: r['result'] for r in read_jsonl(f'{d}/dict_{args.base}.jsonl')}
    mixed = {r['wid'] for r in read_jsonl(f'{d}/mixups_{args.base}.jsonl')}
    queued = {r['wid'] for r in read_jsonl(f'{d}/requeue_{args.base}.jsonl')} | mixed
    for path in args.also:
        queued |= {r['wid'] for r in read_jsonl(path)}
    fixed = {r['wid']: r['result'] for r in read_jsonl(f'{d}/dict_{args.fix}.jsonl')}

    final, unresolved = {}, []
    for w, res in base.items():
        if w not in queued:
            final[w] = res
    for w in sorted(queued):
        if w in fixed:
            final[w] = fixed[w]
        elif w in base:
            final[w] = base[w]  # yeniden üretim kabul edilmedi: ilk sonuç kalır, incelemeye düşer
            unresolved.append({'wid': w, 'reason': 'yeniden üretim kabul edilmedi, ilk sonuç kullanıldı'})
        else:
            unresolved.append({'wid': w, 'reason': 'iki turda da kabul edilmedi'})
    with open(f'{d}/review.jsonl', 'w', encoding='utf-8') as f:
        for r in read_jsonl(f'{d}/mixups_{args.base}.jsonl'):
            f.write(json.dumps({'wid': r['wid'], 'score': r['score'], 'reason': 'düşük benzerlik'}, ensure_ascii=False) + '\n')

    with open(f'{d}/dict_final.jsonl', 'w', encoding='utf-8') as f:
        for w in sorted(final):
            f.write(json.dumps({'wid': w, 'result': final[w]}, ensure_ascii=False) + '\n')
    with open(f'{d}/unresolved.jsonl', 'w', encoding='utf-8') as f:
        for row in unresolved:
            f.write(json.dumps(row, ensure_ascii=False) + '\n')
    print(f'son sözlük: {len(final)} kelime · insan incelemesine: {len(unresolved)}')


if __name__ == '__main__':
    main()
