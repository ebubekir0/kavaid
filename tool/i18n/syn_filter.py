"""Arapça eş/zıt anlamlı ve kalıp süzgeci: sözlüğümüzde karşılığı olmayan kelimeleri ayıklar.

Kullanım (kavaid klasöründen):
    python tool/i18n/syn_filter.py content/pilot/ar3/out_gemini-3.1-flash-lite.jsonl ...

Karşılaştırma harekesiz, tatvilsiz, baştaki ال ve bitişik و/ف olmadan, أ/إ/آ→ا, ة→ه, ى→ي ile yapılır.
Sözlükte başlık olarak geçen ya da bir kaydın fiil çekimlerinde/çoğulunda bulunan kelime "gerçek" sayılır.
"""
import gzip
import json
import lzma
import re
import sys

HARAKAT = re.compile(r'[ً-ْٰـ]')


def norm(word):
    w = HARAKAT.sub('', word or '').strip()
    w = re.sub('[أإآ]', 'ا', w).replace('ة', 'ه').replace('ى', 'ي')
    if w.startswith('ال') and len(w) > 3:
        w = w[2:]
    return w


def vocabulary(path='assets/data/sozluk.json.xz'):
    vocab = set()
    with lzma.open(path, 'rt', encoding='utf-8') as f:
        for rec in json.load(f):
            for w in (rec.get('kelime'), rec.get('harekeliKelime'),
                      (rec.get('dilbilgiselOzellikler') or {}).get('cogulForm'),
                      *((rec.get('fiilCekimler') or {}).values())):
                if isinstance(w, str) and w.strip():
                    for part in re.split(r'[،,;/]', w):
                        n = norm(part)
                        if n:
                            vocab.add(n)
    return vocab


def known(word, vocab):
    n = norm(word)
    if n in vocab:
        return True
    # Bitişik و / ف ile gelen başlıklar ("وَخَرَجَ") için
    return len(n) > 3 and n[0] in 'وف' and n[1:] in vocab


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    vocab = vocabulary()
    for path in sys.argv[1:]:
        rows = [json.loads(l) for l in open(path, encoding='utf-8')]
        stats = {'syn': [0, 0], 'ant': [0, 0]}
        dropped = []
        for r in rows:
            res = r['result'] or {}
            for field in ('syn', 'ant'):
                kept = []
                for w in res.get(field) or []:
                    stats[field][0] += 1
                    if known(w, vocab):
                        kept.append(w)
                        stats[field][1] += 1
                    else:
                        dropped.append(w)
                res[field + '_kept'] = kept
        with open(path, 'w', encoding='utf-8') as f:
            for r in rows:
                f.write(json.dumps(r, ensure_ascii=False) + '\n')
        s, a = stats['syn'], stats['ant']
        print(f'{path}: eş anlamlı {s[1]}/{s[0]} kaldı, zıt anlamlı {a[1]}/{a[0]} kaldı; '
              f'atılan örnekleri: {"، ".join(dropped[:25])}')


if __name__ == '__main__':
    main()
