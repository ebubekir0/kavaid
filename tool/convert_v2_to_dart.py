import json
import datetime

# Yeni veritabanı dosyasını oku
with open('SON_GUNCEL_VERITABANI_V2.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f"Loaded {len(data)} words.")

# Kavaid sözlüğünün kullandığı embedded_words_data.dart formatıyla uyumlu bir harmanlama
formatted_data = []
for row in data:
    # row'un orijinal alanlarını kopyala
    new_row = {
        'kelime': row.get('kelime', ''),
        'harekeliKelime': row.get('harekeliKelime', ''),
        'koku': row.get('koku', ''),
        'dilbilgiselOzellikler': row.get('dilbilgiselOzellikler', {}),
        'fiilCekimler': row.get('fiilCekimler', {}),
        'ornekCumleler': row.get('ornekCumleler', [])
    }
    
    # Anlamı birleştirme: "anlamlar||HARFI_CER:harf=hcAnlam" mantığını koruyoruz.
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


out_path = 'lib/data/embedded_words_data.dart'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY\n')
    f.write('// Generated from SON_GUNCEL_VERITABANI_V2.json\n')
    f.write(f'// Total words: {len(formatted_data)}\n')
    f.write(f'// Generated on: {datetime.datetime.now().isoformat()}\n')
    f.write('// Harfi_cer format: anlam||HARFI_CER:harf=anlamlar\n\n')
    
    f.write('const embeddedWordsData = <Map<String, dynamic>>[\n')
    
    for row in formatted_data:
        json_str = json.dumps(row, ensure_ascii=False)
        f.write('  ' + json_str + ',\n')
        
    f.write('];\n')

print(f"Successfully generated {out_path} with {len(formatted_data)} items.")
