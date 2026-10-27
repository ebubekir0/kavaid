"""Firebase'deki eski ortak sözlükte (kelimeler) olup uygulama sözlüğünde olmayan kayıtları çıkarır.

Kullanım (kavaid klasöründen):
    python tool/i18n/firebase_missing.py --src content/firebase/kelimeler_2026-10-26.json

Karşılaştırma harekesiz biçimle yapılır (syn_filter.norm): harekesiz hali sözlükte olan kayıt "var" sayılır,
harekesi farklı olup başka kelime olabilecekler yalnız sayılır. Aynı kelimenin tekrarlarından en dolu kayıt seçilir.
Çıktı: content/lang/tr/firebase_missing_v1.jsonl  {"id", "fbkey", "added", "rec"} (rec ana veri biçiminde);
id'ler 900000'den başlar (wid değildir; sözlüğe eklenirken build_master yeni wid verir).
"""
import argparse
import datetime
import json
import os
import re
import sys
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from syn_filter import norm  # noqa: E402

ARABIC = re.compile(r'[ء-ي]')
OUT = 'content/lang/tr/firebase_missing_v1.jsonl'


def to_master(v):
    """Firebase kaydını content/master/words.jsonl'deki rec biçimine çevirir."""
    return {
        'kelime': v.get('kelime') or '',
        'harekeliKelime': v.get('harekeliKelime') or '',
        'koku': v.get('koku') or '',
        'dilbilgiselOzellikler': v.get('dilbilgiselOzellikler') or {},
        'fiilCekimler': v.get('fiilCekimler') or {},
        'ornekCumleler': [{'arapcaCümle': o.get('arapcaCumle') or o.get('arapcaCümle') or '',
                           'turkceAnlam': o.get('turkceCeviri') or o.get('turkceAnlam') or ''}
                          for o in v.get('ornekCumleler') or [] if isinstance(o, dict)],
        'anlam': v.get('anlam') or '',
    }


def fullness(v):
    return (len(v.get('ornekCumleler') or []), len(v.get('anlam') or ''), v.get('eklenmeTarihi') or 0)


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', required=True)
    args = ap.parse_args()

    with open(args.src, encoding='utf-8') as f:
        fb = json.load(f)
    with open('content/master/words.jsonl', encoding='utf-8') as f:
        recs = [json.loads(line)['rec'] for line in f]
    bare, vowelled = set(), set()
    for r in recs:
        for h in (r.get('kelime'), r.get('harekeliKelime')):
            if h:
                bare.add(norm(h))
                vowelled.add(unicodedata.normalize('NFC', h.strip()))

    missing, vowel_variant, junk = {}, set(), 0
    for key, v in fb.items():
        head = (v or {}).get('harekeliKelime') or (v or {}).get('kelime') or ''
        if not ARABIC.search(head) or not (v.get('anlam') or '').strip():
            junk += 1
            continue
        n = norm(head)
        if n in bare:
            if unicodedata.normalize('NFC', head.strip()) not in vowelled:
                vowel_variant.add(unicodedata.normalize('NFC', head.strip()))
            continue
        if n not in missing or fullness(v) > fullness(missing[n][1]):
            missing[n] = (key, v)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    rows = sorted(missing.values(), key=lambda kv: kv[1].get('eklenmeTarihi') or 0)
    by_month = {}
    with open(OUT, 'w', encoding='utf-8') as f:
        for i, (key, v) in enumerate(rows):
            ts = v.get('eklenmeTarihi')
            added = datetime.datetime.fromtimestamp(ts / 1000).strftime('%Y-%m-%d') if ts else ''
            by_month[added[:7]] = by_month.get(added[:7], 0) + 1
            f.write(json.dumps({'id': 900000 + i, 'fbkey': key, 'added': added, 'rec': to_master(v)},
                               ensure_ascii=False) + '\n')
    print(f'Firebase kayıt {len(fb)} · çöp/boş {junk} · sözlükte olmayan farklı kelime {len(missing)}'
          f' · harekesi farklı biçim (yalnız sayıldı) {len(vowel_variant)}')
    print('eksiklerin eklenme ayı:', dict(sorted(by_month.items())))
    print(f'çıktı: {OUT}')


if __name__ == '__main__':
    main()
