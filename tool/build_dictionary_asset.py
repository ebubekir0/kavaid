"""Sözlük verisini uygulamaya gömülecek asset'e dönüştürür (xz; gzip'e göre ≈ %47 küçük).

Kullanım (proje kökünden):
    python tool/build_dictionary_asset.py [kaynak.json]

Kaynak varsayılan olarak SON_GUNCEL_VERITABANI_V2.json'dur. Üretilenler:
  - assets/data/sozluk.json.xz          : uygulamanın okuduğu sıkıştırılmış veri
  - lib/data/embedded_words_meta.dart   : veri sürümü ve kelime sayısı

Veri sürümü içerikten (SHA-256) hesaplanır. Sürüm değiştiğinde uygulama
açılışta yerel SQLite sözlüğünü otomatik olarak yeniden kurar; böylece
güncellenen kelimeler mevcut kullanıcılara da ulaşır.
"""
import datetime
import lzma
import hashlib
import json
import sys

SOURCE = sys.argv[1] if len(sys.argv) > 1 else 'SON_GUNCEL_VERITABANI_V2.json'
ASSET_PATH = 'assets/data/sozluk.json.xz'
META_PATH = 'lib/data/embedded_words_meta.dart'

with open(SOURCE, 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f"Loaded {len(data)} words from {SOURCE}.")

formatted_data = []
for row in data:
    new_row = {
        'kelime': row.get('kelime', ''),
        'harekeliKelime': row.get('harekeliKelime', ''),
        'koku': row.get('koku', ''),
        'dilbilgiselOzellikler': row.get('dilbilgiselOzellikler', {}),
        'fiilCekimler': row.get('fiilCekimler', {}),
        'ornekCumleler': row.get('ornekCumleler', [])
    }

    # Anlamı birleştirme: "anlamlar||HARFI_CER:harf=hcAnlam" formatı korunur.
    anlam_str = row.get('anlamlar') or row.get('anlam') or ""
    harfi_cerler = row.get('harfi_cerler', [])

    if harfi_cerler and isinstance(harfi_cerler, list):
        for hc in harfi_cerler:
            harf = hc.get('harf', '')
            hcAnlam = hc.get('anlam', '') or hc.get('anlamlar', '')
            if harf:
                anlam_str += f"||HARFI_CER:{harf}={hcAnlam}"

    new_row['anlam'] = anlam_str

    formatted_data.append(new_row)

payload = json.dumps(
    formatted_data, ensure_ascii=False, separators=(',', ':')
).encode('utf-8')
version = hashlib.sha256(payload).hexdigest()[:16]

# Aynı veri her seferinde aynı dosyayı üretir (gereksiz git farkı olmasın).
# Uygulama veriyi yalnız sözlük sürümü değişince bir kez çözer (embedded_words.dart).
with open(ASSET_PATH, 'wb') as f:
    f.write(lzma.compress(payload, preset=9 | lzma.PRESET_EXTREME))

with open(META_PATH, 'w', encoding='utf-8', newline='\n') as f:
    f.write('// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY\n')
    f.write('// tool/build_dictionary_asset.py tarafından üretildi.\n')
    f.write(f'// Kaynak: {SOURCE}\n')
    f.write(f'// Üretim: {datetime.datetime.now().isoformat(timespec="seconds")}\n')
    f.write('// Harfi_cer format: anlam||HARFI_CER:harf=anlamlar\n\n')
    f.write(f"const embeddedWordsAsset = '{ASSET_PATH}';\n")
    f.write(f"const embeddedWordsVersion = '{version}';\n")
    f.write(f'const embeddedWordsCount = {len(formatted_data)};\n')

print(f"Wrote {ASSET_PATH} ({len(payload)} bytes raw) and {META_PATH}.")
print(f"Version: {version}, words: {len(formatted_data)}")
