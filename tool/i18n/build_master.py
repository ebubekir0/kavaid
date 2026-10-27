"""Kalıcı kelime kimliği (wid) atar ve yerelleştirme için ana veriyi yazar.

Kullanım (kavaid klasöründen):
    python tool/i18n/build_master.py

Girdi : assets/data/sozluk.json.xz
Çıktı : content/master/wid_map.json  anahtar -> wid; bir kez atanan wid bir daha değişmez
        content/master/words.jsonl   {"wid", "rec"} — tam kopya kayıtlar tek wid altında

Anahtar, kaydın harekeli yazımı, harekesiz yazımı, türü ve Türkçe anlamından
türetilir. Sözlük güncellenince mevcut kayıtlar aynı wid'i korur, yeni kayıtlar
en büyük wid'den sonra numara alır, silinen kaydın wid'i tekrar kullanılmaz.
"""
import gzip
import hashlib
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dictionary_source import load_dictionary  # noqa: E402

OUT_DIR = 'content/master'
MAP_PATH = os.path.join(OUT_DIR, 'wid_map.json')
WORDS_PATH = os.path.join(OUT_DIR, 'words.jsonl')


def record_key(rec):
    tur = (rec.get('dilbilgiselOzellikler') or {}).get('tur') or ''
    raw = '\t'.join([rec.get('harekeliKelime') or '', rec.get('kelime') or '', tur, rec.get('anlam') or ''])
    return hashlib.sha1(raw.encode('utf-8')).hexdigest()[:16]


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    data = load_dictionary()
    os.makedirs(OUT_DIR, exist_ok=True)
    wid_map = {}
    if os.path.exists(MAP_PATH):
        with open(MAP_PATH, encoding='utf-8') as f:
            wid_map = json.load(f)
    next_wid = max(wid_map.values(), default=0) + 1

    seen, words, new = set(), [], 0
    for rec in data:
        key = record_key(rec)
        if key not in wid_map:
            wid_map[key] = next_wid
            next_wid += 1
            new += 1
        wid = wid_map[key]
        if wid in seen:
            continue  # tam kopya: aynı wid zaten yazıldı
        seen.add(wid)
        words.append({'wid': wid, 'rec': rec})

    with open(MAP_PATH, 'w', encoding='utf-8') as f:
        json.dump(wid_map, f, ensure_ascii=False)
    with open(WORDS_PATH, 'w', encoding='utf-8') as f:
        for row in words:
            f.write(json.dumps(row, ensure_ascii=False) + '\n')
    print(f'{len(data)} kayıt -> {len(words)} tekil wid ({len(data) - len(words)} tam kopya birleşti), '
          f'{new} yeni wid atandı. En büyük wid: {next_wid - 1}')


if __name__ == '__main__':
    main()
