"""
SON_GUNCEL_VERITABANI.json'u embedded_words_data.dart formatına dönüştürür.

Yeni JSON formatı:
  {
    "id": "...",
    "kelime": "...",
    "harekeliKelime": "...",
    "koku": "...",
    "dilbilgiselOzellikler": {"cogulForm": "...", "tur": "..."},
    "fiilCekimler": {"emirForm": "...", "mastarForm": "...", "maziForm": "...", "muzariForm": "..."},
    "ornekCumleler": [{"arapcaCümle": "...", "turkceAnlam": "..."}],
    "anlamlar": "anlam1, anlam2, anlam3",
    "harfi_cerler": [{"harf": "...", "anlamlar": "..."}]
  }

Dart formatı (mevcut embedded_words_data.dart):
  {
    "kelime": "...",
    "harekeliKelime": "...",
    "anlam": "anlam1, anlam2, anlam3||harf=عَلَى||anlamlar=...e farz kılmak",
    "koku": "...",
    "dilbilgiselOzellikler": {"cogulForm": "...", "tur": "..."},
    "ornekCumleler": [...],
    "fiilCekimler": {...},
    "eklenmeTarihi": 1234567890
  }

Harfi_cerler => anlam stringine ||HARFI_CER:harf=X||anlamlar=Y formatında eklenir
"""

import json
import re
import sys
from datetime import datetime

def escape_dart_string(s):
    """Dart string'i için güvenli hale getir."""
    if not s:
        return ''
    # Ters eğik çizgi ve tırnak işaretlerini escape et
    s = s.replace('\\', '\\\\')
    s = s.replace('"', '\\"')
    s = s.replace('\n', '\\n')
    s = s.replace('\r', '')
    return s

def word_to_dart_map(word):
    """Bir kelimeyi Dart Map formatına dönüştür."""
    kelime = word.get('kelime', '') or ''
    harekeli = word.get('harekeliKelime', '') or ''
    koku = word.get('koku', '') or ''
    
    # Anlamlar - yeni format "anlamlar" key'i kullanıyor
    anlamlar_raw = word.get('anlamlar', '') or ''
    
    # dilbilgiselOzellikler
    dilbilgisel = word.get('dilbilgiselOzellikler', {}) or {}
    
    # fiilCekimler
    fiil_cekimler = word.get('fiilCekimler', {}) or {}
    
    # ornekCumleler - eski formatta arapcaCümle/turkceAnlam, 
    # yeni formatta arapcaCümle/turkceAnlam veya arapcaCumle/turkceCeviri
    ornek_cumleler = word.get('ornekCumleler', []) or []
    
    # harfi_cerler
    harfi_cerler = word.get('harfi_cerler', []) or []
    
    # Eğer kelime veya harekeliKelime yoksa ve anlam da yoksa, atla
    if not kelime.strip():
        return None
    
    # Anlam string'ini oluştur
    # harfi_cerler varsa, özel separator ile anlama ekle
    # Format: "anlam1, anlam2||HARFI_CER:هarf=فِي||anlamlar=...de olmak"
    anlam = anlamlar_raw.strip()
    
    if harfi_cerler:
        harfi_cer_parts = []
        for hc in harfi_cerler:
            harf = hc.get('harf', '') or ''
            hc_anlamlar = hc.get('anlamlar', '') or ''
            if harf:
                harfi_cer_parts.append(f"HARFI_CER:{harf}={hc_anlamlar}")
        if harfi_cer_parts:
            anlam = anlam + ('||' if anlam else '') + '||'.join(harfi_cer_parts)
    
    # ornekCumleler'i standart formata çevir
    normalized_ornekler = []
    for ornek in ornek_cumleler:
        if isinstance(ornek, dict):
            # Tüm olası key formatlarını destekle
            arapca = (ornek.get('arapcaCumle') or 
                     ornek.get('arapcaCümle') or 
                     ornek.get('arapca') or '')
            turkce = (ornek.get('turkceCeviri') or 
                     ornek.get('turkceAnlam') or 
                     ornek.get('turkce') or '')
            if arapca or turkce:
                normalized_ornekler.append({
                    'arapcaCumle': arapca,
                    'turkceCeviri': turkce
                })
    
    # dilbilgiselOzellikler normalize et
    normalized_dilbilgisel = {}
    if dilbilgisel:
        cogul = dilbilgisel.get('cogulForm', '') or ''
        tur = dilbilgisel.get('tur', '') or ''
        if cogul:
            normalized_dilbilgisel['cogulForm'] = cogul
        if tur:
            normalized_dilbilgisel['tur'] = tur
    
    # fiilCekimler normalize et
    normalized_fiil = {}
    if fiil_cekimler:
        emir = fiil_cekimler.get('emirForm', '') or ''
        mastar = fiil_cekimler.get('mastarForm', '') or ''
        mazi = fiil_cekimler.get('maziForm', '') or ''
        muzari = fiil_cekimler.get('muzariForm', '') or ''
        if emir: normalized_fiil['emirForm'] = emir
        if mastar: normalized_fiil['mastarForm'] = mastar
        if mazi: normalized_fiil['maziForm'] = mazi
        if muzari: normalized_fiil['muzariForm'] = muzari
    
    return {
        'kelime': kelime,
        'harekeliKelime': harekeli,
        'anlam': anlam,
        'koku': koku,
        'dilbilgiselOzellikler': normalized_dilbilgisel,
        'ornekCumleler': normalized_ornekler,
        'fiilCekimler': normalized_fiil,
        'eklenmeTarihi': int(datetime.now().timestamp() * 1000)
    }

def dict_to_dart_literal(d, indent=1):
    """Python dict'ini Dart Map literal'ına çevir."""
    if not d:
        return '{}'
    
    indent_str = '  ' * indent
    inner_indent = '  ' * (indent + 1)
    
    parts = []
    for k, v in d.items():
        key_str = f'"{escape_dart_string(k)}"'
        val_str = value_to_dart(v, indent + 1)
        parts.append(f'{inner_indent}{key_str}:{val_str}')
    
    return '{\n' + ',\n'.join(parts) + '\n' + indent_str + '}'

def list_to_dart_literal(lst, indent=1):
    """Python list'ini Dart List literal'ına çevir."""
    if not lst:
        return '[]'
    
    indent_str = '  ' * indent
    inner_indent = '  ' * (indent + 1)
    
    parts = []
    for item in lst:
        val_str = value_to_dart(item, indent + 1)
        parts.append(f'{inner_indent}{val_str}')
    
    return '[\n' + ',\n'.join(parts) + '\n' + indent_str + ']'

def value_to_dart(v, indent=1):
    """Python değerini Dart literal'ına çevir."""
    if v is None:
        return 'null'
    elif isinstance(v, bool):
        return 'true' if v else 'false'
    elif isinstance(v, int):
        return str(v)
    elif isinstance(v, float):
        return str(v)
    elif isinstance(v, str):
        return f'"{escape_dart_string(v)}"'
    elif isinstance(v, dict):
        return dict_to_dart_literal(v, indent)
    elif isinstance(v, list):
        return list_to_dart_literal(v, indent)
    else:
        return f'"{escape_dart_string(str(v))}"'

def main():
    input_file = 'SON_GUNCEL_VERITABANI.json'
    output_file = 'lib/data/embedded_words_data.dart'
    
    print(f"Reading {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Total words in JSON: {len(data)}")
    
    # Convert words
    dart_words = []
    skipped = 0
    harfi_cer_count = 0
    
    for i, word in enumerate(data):
        if i % 5000 == 0:
            print(f"Processing {i}/{len(data)}...")
        
        converted = word_to_dart_map(word)
        if converted is None:
            skipped += 1
            continue
        
        # Count words with harfi_cer
        if '||HARFI_CER:' in (converted.get('anlam') or ''):
            harfi_cer_count += 1
        
        dart_words.append(converted)
    
    print(f"Converted: {len(dart_words)}, Skipped: {skipped}")
    print(f"Words with harfi_cer: {harfi_cer_count}")
    
    # Generate Dart file
    print(f"Writing {output_file}...")
    
    now = datetime.now().isoformat()
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(f'// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY\n')
        f.write(f'// Generated from SON_GUNCEL_VERITABANI.json\n')
        f.write(f'// Total words: {len(dart_words)}\n')
        f.write(f'// Generated on: {now}\n')
        f.write(f'// Harfi_cer format: anlam||HARFI_CER:harf=anlamlar\n')
        f.write(f'\n')
        f.write(f'const embeddedWordsData = <Map<String, dynamic>>[\n')
        
        for i, word in enumerate(dart_words):
            # Write comment with Arabic word
            harekeli = word.get('harekeliKelime') or word.get('kelime', '')
            anlam = word.get('anlam', '')
            # Short summary for comment
            anlam_short = anlam.split('||')[0][:50] if anlam else ''
            f.write(f'\n  // {harekeli} - {anlam_short}\n')
            
            # Write the map
            f.write('  {')
            
            parts = []
            
            kelime = word.get('kelime', '')
            harekeli_k = word.get('harekeliKelime', '')
            anlam_v = word.get('anlam', '')
            koku = word.get('koku', '')
            dilbilgisel = word.get('dilbilgiselOzellikler', {})
            ornekler = word.get('ornekCumleler', [])
            fiil = word.get('fiilCekimler', {})
            tarih = word.get('eklenmeTarihi', 0)
            
            parts.append(f'"kelime":"{escape_dart_string(kelime)}"')
            parts.append(f'"harekeliKelime":"{escape_dart_string(harekeli_k)}"')
            parts.append(f'"anlam":"{escape_dart_string(anlam_v)}"')
            parts.append(f'"koku":"{escape_dart_string(koku)}"')
            
            # dilbilgiselOzellikler
            dilbilgisel_dart = dict_to_dart_literal(dilbilgisel, 2)
            parts.append(f'"dilbilgiselOzellikler":{dilbilgisel_dart}')
            
            # ornekCumleler
            ornekler_parts = []
            for ornek in ornekler:
                arapca = escape_dart_string(ornek.get('arapcaCumle', ''))
                turkce = escape_dart_string(ornek.get('turkceCeviri', ''))
                ornekler_parts.append(f'{{"arapcaCumle":"{arapca}","turkceCeviri":"{turkce}"}}')
            ornekler_dart = '[' + ','.join(ornekler_parts) + ']'
            parts.append(f'"ornekCumleler":{ornekler_dart}')
            
            # fiilCekimler
            fiil_dart = dict_to_dart_literal(fiil, 2)
            parts.append(f'"fiilCekimler":{fiil_dart}')
            
            parts.append(f'"eklenmeTarihi":{tarih}')
            
            f.write(','.join(parts))
            f.write('},\n')
        
        f.write('];\n')
    
    print(f"\nDone! Output: {output_file}")
    print(f"File size: {__import__('os').path.getsize(output_file) / 1024 / 1024:.1f} MB")

if __name__ == '__main__':
    main()
