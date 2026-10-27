"""Pilot için tabakalı örneklem seçer.

Kullanım (kavaid klasöründen):
    python tool/i18n/pilot_sample.py              # 50 kelime
    python tool/i18n/pilot_sample.py --size 200   # 50'lik örneklem + 150 yeni kelime

Çıktı: content/pilot/sample_<n>.jsonl  (pid = sozluk.json.gz içindeki sıra;
pilotta geçici kimlik olarak kullanılır, kalıcı wid sonra atanacak). Büyük
örneklemler 50'lik örneklemi kapsar; böylece istem değişikliğinin önce/sonra
farkı aynı kelimelerde görülür.
"""
import argparse
import collections
import gzip
import json
import lzma
import os
import random

SOURCE = 'assets/data/sozluk.json.xz'
OUT = 'content/pilot/sample_{n}.jsonl'
SEED = 42

# Çok anlamlı / çok bilinen kelimeler: farkı en iyi bunlar gösterir.
ANCHORS = ['ذَهَبَ', 'قَامَ', 'قَالَ', 'عَيْنٌ', 'كِتَابٌ', 'بَيْتٌ', 'صَلَاةٌ', 'رَحْمَةٌ', 'دِينٌ']

# (etiket, tür seçici, adet)
STRATA = [
    ('isim', lambda t: t == 'İsim', 7),
    ('mazi', lambda t: t == 'Mazî Fiil', 7),
    ('muzari', lambda t: t == 'Muzari Fiil', 4),
    ('mastar', lambda t: t == 'Mastar', 4),
    ('sifat', lambda t: t == 'Sıfat', 3),
    ('emir', lambda t: t == 'Emir Fiil', 2),
    ('cogul', lambda t: 'Çoğul' in t, 2),
    ('meçhul', lambda t: 'Meçhul' in t or 'Nehiy' in t, 2),
    ('türemiş', lambda t: t.startswith('İsm-i') or t == 'İsim Fail', 3),
    ('tamlama_deyim', lambda t: 'tamlama' in t.lower() or t == 'Deyim', 3),
    ('harf_cerli', lambda t: t.startswith('Harf-i Cerli'), 2),
    ('edat_zarf', lambda t: t in ('Edat', 'Harf', 'Zarf'), 2),
]


def usable(rec):
    return bool(rec.get('anlam')) and bool(rec.get('ornekCumleler')) and bool(rec.get('harekeliKelime'))


def pick_strata(data, rng, taken, scale):
    """STRATA adetlerini scale ile çarparak taken dışındaki kelimelerden seçer."""
    pools = collections.defaultdict(list)
    for i, rec in enumerate(data):
        if i in taken or not usable(rec):
            continue
        tur = (rec.get('dilbilgiselOzellikler') or {}).get('tur') or ''
        for label, match, _ in STRATA:
            if match(tur):
                pools[label].append(i)
                break

    chosen = []
    for label, _, count in STRATA:
        count = max(1, round(count * scale))
        pool = pools[label]
        if label == 'mazi':
            # Harf-i cerli fiiller ayrıca sınansın: yarısı harf-i cerli olsun.
            with_prep = [i for i in pool if '||HARFI_CER:' in data[i]['anlam']]
            picks = rng.sample(with_prep, count // 2 + 1)
            picks += rng.sample([i for i in pool if i not in picks], count - len(picks))
        else:
            picks = rng.sample(pool, min(count, len(pool)))
        chosen += [(i, label) for i in picks]
    return chosen


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--size', type=int, default=50)
    size = ap.parse_args().size

    with lzma.open(SOURCE, 'rt', encoding='utf-8') as f:
        data = json.load(f)
    by_head = {rec.get('harekeliKelime'): i for i, rec in enumerate(data)}

    base_path = OUT.format(n=50)
    if size > 50 and os.path.exists(base_path):
        with open(base_path, encoding='utf-8') as f:
            chosen = [(row['pid'], row['stratum']) for row in map(json.loads, f)]
        rng = random.Random(SEED + size)
        scale = (size - len(chosen)) / sum(c for _, _, c in STRATA)
        chosen += pick_strata(data, rng, {i for i, _ in chosen}, scale)
    else:
        rng = random.Random(SEED)
        chosen = []
        for head in ANCHORS:
            i = by_head.get(head)
            if i is not None and usable(data[i]):
                chosen.append((i, 'anchor'))
        chosen += pick_strata(data, rng, {i for i, _ in chosen}, 1)

    taken = {i for i, _ in chosen}
    rest = [i for i, rec in enumerate(data) if usable(rec) and i not in taken]
    while len(chosen) < size:
        i = rng.choice(rest)
        if i not in taken:
            taken.add(i)
            chosen.append((i, 'rastgele'))

    out = OUT.format(n=size)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, 'w', encoding='utf-8') as f:
        for i, label in chosen[:size]:
            f.write(json.dumps({'pid': i, 'stratum': label, 'rec': data[i]}, ensure_ascii=False) + '\n')
    print(f'{len(chosen[:size])} kelime -> {out}')


if __name__ == '__main__':
    main()
