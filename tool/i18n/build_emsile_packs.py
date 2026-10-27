"""Emsile (çekim) bölümündeki fiil anlamlarını sözlük dillerine taşır; yalnız sözlük verisinden.

emsile.db'de 5.596 fiilin anlamları Türkçe. Diğer dillerde fiilin anlamı, o dilin sözlük
paketinde aynı kelimenin maddesinden alınır (kartta görülen anlamla aynı):
  1. mazi (كَتَبَ) fiil maddesi, 2. yoksa masdar (كِتَابَةٌ) maddesi, 3. yoksa muzari (يَكْتُبُ).
Karşılaştırmada harekeler korunur (yalnız son hareke/tenvin ve işaret sırası yok sayılır):
harekesiz eşleştirme farklı babları karıştırıyordu (كَتَّبَ ↔ كَتَبَ). Maddesi olmayan fiilde
anlam boş kalır; çeviri yapılmaz. Arapça–Arapça anlamlar uygulamada ArabicDefinitions'tan gelir.

Kullanım (kavaid klasöründen):  python tool/i18n/build_emsile_packs.py [--langs en id ms ur]
Çıktı: assets/data/lang/emsile_<dil>.json.xz  {"<emsile id>": ["anlam", ...]}
"""
import argparse
import json
import lzma
import os
import re
import sqlite3
import sys
import tempfile
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dictionary_source import load_dictionary  # noqa: E402

LANGS = ['en', 'id', 'ms', 'ur']
MAX_MEANINGS = 6
OUT_DIR = 'assets/data/lang'
_case_ending = re.compile('[ً-ِْ]+$')


def soft(text):
    """Harekeli karşılaştırma anahtarı: işaret sırası, uzatma çizgisi, ٱ ve son hareke yok sayılır."""
    t = unicodedata.normalize('NFD', (text or '').strip()).replace('ـ', '').replace('ٱ', 'ا')
    return _case_ending.sub('', unicodedata.normalize('NFC', t))


def kind(rec):
    tur = (rec.get('dilbilgiselOzellikler') or {}).get('tur') or ''
    if 'Muzari' in tur:
        return 'muzari'
    if 'Mastar' in tur:
        return 'masdar'
    if 'Fiil' in tur and 'Emir' not in tur:
        return 'mazi'
    return None


def load_emsile():
    raw = lzma.open('assets/data/emsile.db.xz').read()
    path = os.path.join(tempfile.gettempdir(), 'emsile_build.db')
    with open(path, 'wb') as f:
        f.write(raw)
    con = sqlite3.connect(path)
    rows = []
    for vid, mazi, muzari, forms in con.execute('SELECT id, mazi, muzari, emsile_24 FROM emsile'):
        masdar = next((f['arapca'] for f in json.loads(forms) if f.get('sira') == 3), '')
        rows.append((vid, mazi, masdar, muzari))
    con.close()
    return rows


def split_meaning(anlam):
    main = (anlam or '').split('||')[0]
    parts = [p.strip() for p in re.split('[,،]', main)]
    return [p for p in parts if p][:MAX_MEANINGS]


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--langs', nargs='+', default=LANGS)
    args = ap.parse_args()

    verbs = load_emsile()
    data = load_dictionary()
    kinds = [kind(rec) for rec in data]
    keys = [soft(rec.get('harekeliKelime')) for rec in data]

    for lang in args.langs:
        with lzma.open(f'{OUT_DIR}/{lang}.json.xz', 'rt', encoding='utf-8') as f:
            pack = json.load(f)
        # (tür, harekeli anahtar) -> bu dilde anlamı olan ilk madde
        index = {}
        for i, (k, key) in enumerate(zip(kinds, keys)):
            if k and isinstance(pack[i], list) and split_meaning(pack[i][0]):
                index.setdefault((k, key), i)

        result, counts = {}, {'mazi': 0, 'masdar': 0, 'muzari': 0, 'yok': 0}
        for vid, mazi, masdar, muzari in verbs:
            for k, form in (('mazi', mazi), ('masdar', masdar), ('muzari', muzari)):
                i = index.get((k, soft(form)))
                if i is not None:
                    result[str(vid)] = split_meaning(pack[i][0])
                    counts[k] += 1
                    break
            else:
                counts['yok'] += 1

        payload = json.dumps(result, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        path = f'{OUT_DIR}/emsile_{lang}.json.xz'
        with open(path, 'wb') as f:
            f.write(lzma.compress(payload, preset=9 | lzma.PRESET_EXTREME))
        print(f'{path}: {len(result)}/{len(verbs)} fiil {counts}, {os.path.getsize(path) / 1e3:.0f} KB')


if __name__ == '__main__':
    main()
