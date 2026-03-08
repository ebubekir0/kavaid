#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SOZLUK_TEMIZ.json dosyasındaki anlamları embedded_words_data.dart'a aktarır.
Satır satır işler - 34MB büyük dosya için optimize edilmiş.
"""

import json
import os
import shutil
import re

SOZLUK_PATH = r"C:\Users\kul\Desktop\kavaid1111\kavaid\SOZLUK_TEMIZ.json"
DART_PATH = r"C:\Users\kul\Desktop\kavaid1111\kavaid\lib\data\embedded_words_data.dart"
DART_BACKUP = r"C:\Users\kul\Desktop\kavaid1111\kavaid\lib\data\embedded_words_data.dart.backup2"

def escape_for_dart_json(s):
    """String'i Dart kaynak dosyasındaki JSON string değeri olarak escape eder"""
    s = s.replace('\\', '\\\\')
    s = s.replace('"', '\\"')
    return s

def main():
    # 1. SOZLUK yükle
    print("SOZLUK_TEMIZ.json yukleniyor...")
    with open(SOZLUK_PATH, 'r', encoding='utf-8') as f:
        sozluk_data = json.load(f)
    print(f"  -> {len(sozluk_data)} kelime yuklendi")
    
    # Escape edilmiş anlam map'i hazırla
    sozluk_escaped = {}
    for harekeli, anlam in sozluk_data.items():
        sozluk_escaped[harekeli] = escape_for_dart_json(anlam)
    
    # 2. Yedek al
    if not os.path.exists(DART_BACKUP):
        print(f"\nYedek aliıyor: {DART_BACKUP}")
        shutil.copy2(DART_PATH, DART_BACKUP)
        print("  -> Yedek olusturuldu")
    else:
        print(f"\nYedek zaten mevcut: {DART_BACKUP}")
    
    # 3. Dart dosyasını satır satır oku ve güncelle
    print(f"\nDart dosyası işleniyor...")
    print(f"  Boyut: {os.path.getsize(DART_PATH) / 1024 / 1024:.1f} MB")
    
    updated_lines = 0
    total_lines = 0
    not_updated_samples = []
    sozluk_keys = set(sozluk_data.keys())
    
    output_lines = []
    
    with open(DART_PATH, 'r', encoding='utf-8') as f:
        for line in f:
            total_lines += 1
            if total_lines % 10000 == 0:
                print(f"  {total_lines} satır işlendi... ({updated_lines} güncellendi)")
            
            # Bu satırda "harekeliKelime":"..." var mı?
            # Satırda genellikle tüm bir kayıt var (tek satır)
            if '"harekeliKelime":"' not in line or '"anlam":"' not in line:
                output_lines.append(line)
                continue
            
            # harekeliKelime değerini çıkar
            hk_match = re.search(r'"harekeliKelime":"([^"\\]*(?:\\.[^"\\]*)*)"', line)
            if not hk_match:
                output_lines.append(line)
                continue
            
            hk_value = hk_match.group(1)
            # Unescape et (JSON string'den gerçek değeri al)
            # Dart dosyasında hk_value zaten JSON string formatında
            # Sadece \" -> " dönüşümü yeterli
            hk_real = hk_value.replace('\\"', '"').replace('\\\\', '\\')
            
            # Sozluk'ta bu kelime var mı?
            if hk_real in sozluk_escaped:
                yeni_anlam_escaped = sozluk_escaped[hk_real]
                
                # Mevcut anlam alanını değiştir
                # "anlam":"eski_anlam" -> "anlam":"yeni_anlam"
                # anlam değeri parse etmek zorundayız (çift tırnak + escape karakterleri)
                new_line = re.sub(
                    r'("anlam":")((?:[^"\\]|\\.)*)(")',
                    lambda m: m.group(1) + yeni_anlam_escaped + m.group(3),
                    line,
                    count=1
                )
                
                if new_line != line:
                    updated_lines += 1
                    output_lines.append(new_line)
                else:
                    output_lines.append(line)
            else:
                output_lines.append(line)
                if len(not_updated_samples) < 5:
                    not_updated_samples.append(hk_real)
    
    print(f"\nIslem tamamlandi:")
    print(f"  Toplam satir: {total_lines}")
    print(f"  Guncellenen satir: {updated_lines}")
    
    if not_updated_samples:
        print(f"  Sozlukte bulunmayan ornek harekeli kelimeler:")
        for k in not_updated_samples:
            print(f"    '{k}'")
    
    # 4. Yeni içeriği kaydet
    if updated_lines > 0:
        print(f"\nDosya kaydediliyor...")
        with open(DART_PATH, 'w', encoding='utf-8') as f:
            f.writelines(output_lines)
        print(f"  -> Kaydedildi! {updated_lines} satir guncellendi.")
    else:
        print("\nHic satir guncellenemedi!")
    
    return updated_lines

if __name__ == "__main__":
    main()
