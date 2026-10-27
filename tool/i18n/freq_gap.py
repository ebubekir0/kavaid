"""Bir Arapça sıklık listesindeki kelimelerden sözlüğümüzde karşılığı olmayanları sıklık sırasıyla çıkarır.

Kullanım (kavaid klasöründen):
    python tool/i18n/freq_gap.py --freq content/freq/ar_50k.txt --name subs

Liste satırı "kelime sayı" biçimindedir (FrequencyWords, wikipedia-word-frequency). Kelime "biliniyor" sayılır:
harekesiz hali sözlükte başlık, çoğul ya da fiil biçimi (mazi, muzari, mastar, emir) olarak varsa; ya da baştaki
bağlaç/harf-i cer/ال ve sondaki zamir/çekim ekleri atılınca, muzari öneki ي'ye çevrilince ya da sondaki tenvin elifi
atılınca böyle bir biçime ulaşılıyorsa. Firebase'den eklenecek kayıtlar da bilinen sayılır.
Kurallar kabadır: kalan adayların bir kısmı yine çekimdir, özel isimdir ya da lehçedir (sonraki adımda sınıflandırılır).
Çıktı: content/lang/tr/freq_gap_<ad>.jsonl  {"rank", "word", "count"}
"""
import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from syn_filter import norm  # noqa: E402

ARABIC_ONLY = re.compile(r'^[ء-يً-ْٰ]+$')
# "ا" soru hemzesi (أتريد), "ما/يا/لا" altyazılarda bitişik yazılan edatlar (مالذي، يارجل، لاشيء)
PREFIXES = ('وال', 'فال', 'بال', 'كال', 'لل', 'وس', 'فس', 'ما', 'يا', 'لا', 'و', 'ف', 'ب', 'ل', 'ك', 'س', 'ا')
SUFFIXES = ('تموها', 'تمونا', 'كما', 'هما', 'تما', 'تم', 'تن', 'هم', 'هن', 'كم', 'كن', 'نا', 'ها', 'ون', 'ين',
            'ان', 'وا', 'ات', 'ني', 'ه', 'ك', 'ي', 'ت', 'ن', 'ا')


def known_forms(recs):
    forms = set()
    for r in recs:
        gram = r.get('dilbilgiselOzellikler') or {}
        fiil = r.get('fiilCekimler') or {}
        for h in (r.get('kelime'), r.get('harekeliKelime'), gram.get('cogulForm'), fiil.get('maziForm'),
                  fiil.get('muzariForm'), fiil.get('mastarForm'), fiil.get('emirForm')):
            for part in re.split(r'[،,/]', h or ''):
                n = norm(part)
                if n:
                    forms.add(n)
    return forms


def variants(w):
    """Kelimenin ek atılmış olası biçimleri (kendisi dahil)."""
    stems = {w}
    for p in PREFIXES:
        for s in list(stems):
            if s.startswith(p) and len(s) - len(p) >= 2:
                stems.add(s[len(p):])
    out = set()
    for s in stems:
        out.add(s)
        for q in SUFFIXES:
            if s.endswith(q) and len(s) - len(q) >= 2:
                out.add(s[:-len(q)])
    for s in list(out):
        if s[:1] in 'تنا' and len(s) >= 3:
            out.add('ي' + s[1:])
        if s.endswith('ت') and len(s) >= 3:  # ة zamir alınca ت olur: زوجتك → زوجة
            out.add(s[:-1] + 'ه')
        out.add(norm('ال' + s))
    return out


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--freq', required=True)
    ap.add_argument('--name', required=True)
    ap.add_argument('--top', type=int, default=50000)
    args = ap.parse_args()

    with open('content/master/words.jsonl', encoding='utf-8') as f:
        recs = [json.loads(line)['rec'] for line in f]
    extra = 'content/lang/tr/firebase_missing_v1.jsonl'
    if os.path.exists(extra):
        with open(extra, encoding='utf-8') as f:
            recs += [json.loads(line)['rec'] for line in f]
    forms = known_forms(recs)

    rows, seen = [], set()
    with open(args.freq, encoding='utf-8') as f:
        for rank, line in enumerate(f, 1):
            if rank > args.top:
                break
            parts = line.split()
            if len(parts) < 2 or not ARABIC_ONLY.match(parts[0]):
                continue
            w = norm(parts[0])
            if len(w) < 2 or w in seen:
                continue
            seen.add(w)
            if not (variants(w) & forms):
                rows.append({'rank': rank, 'word': parts[0], 'count': int(parts[1])})

    out = f'content/lang/tr/freq_gap_{args.name}.jsonl'
    with open(out, 'w', encoding='utf-8') as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + '\n')
    print(f'listedeki farklı Arapça kelime {len(seen)} · sözlükte karşılığı bulunamayan {len(rows)}')
    for lim in (1000, 5000, 10000, 20000, 30000, 50000):
        print(f'  ilk {lim:>6} içinde: {sum(1 for r in rows if r["rank"] <= lim)}')
    print(f'çıktı: {out}')


if __name__ == '__main__':
    main()
