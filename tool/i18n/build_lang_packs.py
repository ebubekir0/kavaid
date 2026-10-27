"""Uygulamanın içine konan dil paketlerini üretir (anlam dili tr dışındaysa sözlük bunlarla kurulur).

Kullanım (kavaid klasöründen):
    python tool/i18n/build_lang_packs.py               # en ar id ms ur
    python tool/i18n/build_lang_packs.py --langs en id

Girdi : assets/data/sozluk.json.xz (kayıt sırası), content/master/wid_map.json,
        content/lang/<dil>/dict_final.jsonl
Çıktı : assets/data/lang/<dil>.json.xz     sozluk.json.xz ile aynı sırada liste
          çeviri dilleri: [anlam, [örnek çevirileri]] — anlam uygulamanın biçiminde (a, b||HARFI_CER:harf=x)
          ar: {"s": [[tanım, örnek]], "p": [[harf-i cerli kalıp, anlam]]} (örnek metin olarak)
          o dilde sonucu olmayan kayıt: null (uygulama Türkçe/İngilizce hâlini gösterir)
        lib/data/lang_packs_meta.dart          paket yolları, sürümleri ve boyutları
xz, gzip'e göre paketleri ≈ %35 küçültür; uygulama paketi yalnız dil seçilince bir kez çözer.
"""
import argparse
import datetime
import gzip
import hashlib
import json
import lzma
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dictionary_source import load_dictionary  # noqa: E402
from build_master import record_key  # noqa: E402
from check_app_compat import to_app_anlam  # noqa: E402

OUT_DIR = 'assets/data/lang'
META = 'lib/data/lang_packs_meta.dart'
LANGS = ['en', 'ar', 'id', 'ms', 'ur']


def translation_item(res):
    return [to_app_anlam(res), [e.strip() for e in res.get('examples') or []]]


def arabic_item(res, rec):
    examples = [o.get('arapcaCümle') or o.get('arapcaCumle') or ''
                for o in rec.get('ornekCumleler') or [] if isinstance(o, dict)]
    senses = []
    for s in res['senses']:
        ex = s.get('ex', -1)
        text = examples[ex] if isinstance(ex, int) and 0 <= ex < len(examples) else (s.get('ext') or '')
        senses.append([s['d'], text])
    return {'s': senses, 'p': [[p['h'], p['m']] for p in res.get('preps') or []]}


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--langs', nargs='+', default=LANGS)
    args = ap.parse_args()

    data = load_dictionary()
    with open('content/master/wid_map.json', encoding='utf-8') as f:
        wid_map = json.load(f)
    wids = [wid_map.get(record_key(rec)) for rec in data]
    os.makedirs(OUT_DIR, exist_ok=True)

    meta = {}
    for lang in args.langs:
        with open(f'content/lang/{lang}/dict_final.jsonl', encoding='utf-8') as f:
            results = {row['wid']: row['result'] for row in map(json.loads, f)}
        items, filled = [], 0
        for rec, wid in zip(data, wids):
            res = results.get(wid)
            if not res or not res.get('senses'):
                items.append(None)
                continue
            items.append(arabic_item(res, rec) if lang == 'ar' else translation_item(res))
            filled += 1
        payload = json.dumps(items, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        packed = lzma.compress(payload, preset=9 | lzma.PRESET_EXTREME)
        path = f'{OUT_DIR}/{lang}.json.xz'
        with open(path, 'wb') as f:
            f.write(packed)
        meta[lang] = (path, hashlib.sha256(payload).hexdigest()[:12], len(packed))
        print(f'{path}: {filled}/{len(data)} kayıt, {len(packed) / 1e6:.2f} MB')

    # Önceden üretilmiş paketler de meta'da kalsın (yalnız bazı diller yeniden üretildiyse)
    for lang in LANGS:
        path = f'{OUT_DIR}/{lang}.json.xz'
        if lang not in meta and os.path.exists(path):
            with open(path, 'rb') as f:
                payload = lzma.decompress(f.read())
            meta[lang] = (path, hashlib.sha256(payload).hexdigest()[:12], os.path.getsize(path))

    lines = [
        '// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY',
        '// tool/i18n/build_lang_packs.py tarafından üretildi.',
        f'// Üretim: {datetime.datetime.now().isoformat(timespec="seconds")}',
        '',
        '/// Uygulamanın içindeki dil paketleri: dil -> (asset yolu, veri sürümü, bayt).',
        'const langPacks = <String, ({String asset, String version, int bytes})>{',
    ]
    for lang in LANGS:
        if lang in meta:
            path, version, size = meta[lang]
            lines.append(f"  '{lang}': (asset: '{path}', version: '{version}', bytes: {size}),")
    lines.append('};')
    with open(META, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')
    print(f'{META}: {", ".join(meta)}')


if __name__ == '__main__':
    main()
