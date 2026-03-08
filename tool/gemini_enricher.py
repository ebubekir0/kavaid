#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gemini API ile Arapça Kelime Zenginleştirici
============================================
Bu script, Gemini API kullanarak Arapça kelimeleri zenginleştirir.
- Kelime listesinden okur
- Gemini API'ye istek atar
- JSON formatında kaydeder
- Kaldığı yerden devam edebilir

Kullanım:
    python gemini_enricher.py --start 0 --count 100
    python gemini_enricher.py --resume  # Kaldığı yerden devam et
"""

import os
import json
import time
import argparse
import requests
from pathlib import Path
from datetime import datetime

# ==================== YAPILANDIRMA ====================
# Gemini API anahtarınızı buraya yazın veya ortam değişkeninden alın
API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyB6v5JGqHXTJ3OtmtYtkM7UGHwGMCCmDYE")

# Gemini API endpoint (Gemini 1.5 Flash - hızlı ve ekonomik)
API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

# Dosya yolları
BASE_DIR = Path(r"c:\Users\kul\Desktop\kavaid1111\kavaid\tool")
WORD_LIST_FILE = BASE_DIR / "cleaned_unique_words_only.txt"
OUTPUT_DIR = BASE_DIR / "enriched_output"
PROGRESS_FILE = BASE_DIR / "enrichment_progress.json"
BATCH_SIZE = 10  # Her batch'te işlenecek kelime sayısı
RATE_LIMIT_DELAY = 1.5  # İstekler arası bekleme süresi (saniye)

# ==================== PROMPT ŞABLONU ====================
ENRICHMENT_PROMPT = """YAPAY ZEKA İÇİN GÜNCEL VE KESİN TALİMATLAR

Sen bir Arapça sözlük uygulamasısın. Kullanıcıdan Arapça veya Türkçe bir kelime al ve detaylı bir kelime bilgisi oluştur.

⚠️ KRİTİK KURALLAR:
1. Sadece kesin olarak bildiğin bilgileri sun. ASLA UYDURMA!
2. Tüm Arapça kelimeler TAM HAREKELİ olmalı (kelime ve koku alanları hariç)
3. JSON formatına TAM uy.
4. ASLA PARANTEZ () KULLANMA. Ek açıklamaları parantez içine alma, direkt yaz veya çıkar. Sadece harfi cerler için köşeli parantez [] kullanılır.
5. Bilgi yoksa veya alan uygulanamıyorsa "" (boş string) veya [] (boş dizi) kullan.

📝 TÜR KURALLARI (dilbilgiselOzellikler.tur):
Kelimenin tam türünü belirt:
- Fiiller: "Mazi Fiil", "Muzari Fiil", "Emir Fiil", "Nehiy Fiil"
- Mastarlar: "Mastar"
- İsimler: "İsim", "İsmi Fail", "İsmi Meful", "İsmi Zaman", "İsmi Mekan", "İsmi Alet", "Özel İsim"
- Sıfatlar: "Sıfat", "Mübalağa Sıfat", "Nisbet Sıfatı", "İsmi Tafdil"
- Zamirler: "Şahıs Zamiri", "İşaret Zamiri", "İlgi Zamiri", "Soru Zamiri"
- Harfler: "Harf (Harfi Cer)", "Harf (Harfi Atıf)", "Harf (Harfi Nefiy)"
- Diğer: "Zarf", "Zarf (Zaman)", "Zarf (Mekan)", "Bağlaç", "Ünlem", "Sayı"

📝 ANLAM KURALLARI (ÇOK ÖNEMLİ):
- Tek string, virgülle ayrılmış.
- ⚠️ YAKINLIK SIRASI: En yaygın ve sık kullanılan anlamdan başla.
- ⚠️ SADELİK: Sadece yaygın kullanılan anlamları yaz. Nadir, arkaik veya çok spesifik teknik anlamları ekleme.
- Anlam sayısı: Kelimenin zenginliğine ve yaygınlığına göre ayarla. Zorlama yapma.
- ⚠️ ZAMAN UYUMU: Anlam, kelimenin zamanına/türüne UYGUN olmalı.
- ⚠️ HARFİ CER KURALI: 
  • Format: Temel anlamlar, [harfi cer1] o harfi cerle gelen yaygın anlamlar, [harfi cer2] o harfi cerle gelen yaygın anlamlar.
  • Sadece anlamı belirgin şekilde DEĞİŞTİREN harfi cerler olmalı.

📝 EŞ VE ZIT ANLAM KURALLARI:
- Virgülle ayrılmış TAM HAREKELİ Arapça kelimeler.
- Aynı türden kelimeler olmalı (mazi ise mazi, mastar ise mastar).

📝 FİİL ÇEKİMLERİ:
- Fiil köklü kelimeler için doldur (fiil, mastar, ismi fail, ismi meful dahil). İsimler için "" bırak.

📝 ÖRNEK CÜMLE KURALLARI:
- 3 adet cümle.
- Seviyeler: Kolay, Orta, Zor.
- ⚠️ HER CÜMLE MAKSİMUM 5 KELİME OLMALI.
- TAM HAREKELİ Arapça.

Kelime: "{word}"

SADECE aşağıdaki JSON formatında yanıt ver, başka hiçbir açıklama ekleme:

{{
  "bulunduMu": true,
  "kelimeBilgisi": {{
    "kelime": "{word}",
    "harekeliKelime": "",
    "koku": "",
    "anlam": "",
    "esAnlamlilar": "",
    "zitAnlamlilar": "",
    "dilbilgiselOzellikler": {{
      "tur": "",
      "cogulForm": ""
    }},
    "fiilCekimler": {{
      "maziForm": "",
      "muzariForm": "",
      "mastarForm": "",
      "emirForm": ""
    }},
    "ornekCumleler": [
      {{"arapcaCumle": "", "turkceCeviri": ""}},
      {{"arapcaCumle": "", "turkceCeviri": ""}},
      {{"arapcaCumle": "", "turkceCeviri": ""}}
    ]
  }}
}}
"""

# ==================== FONKSİYONLAR ====================

def load_words():
    """Kelime listesini yükle"""
    if not WORD_LIST_FILE.exists():
        print(f"❌ Kelime dosyası bulunamadı: {WORD_LIST_FILE}")
        return []
    
    with open(WORD_LIST_FILE, 'r', encoding='utf-8') as f:
        words = [line.strip() for line in f if line.strip()]
    
    print(f"✅ {len(words)} kelime yüklendi")
    return words


def load_progress():
    """İlerleme durumunu yükle"""
    if PROGRESS_FILE.exists():
        with open(PROGRESS_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {"last_index": 0, "processed_count": 0, "last_batch": 0}


def save_progress(progress):
    """İlerleme durumunu kaydet"""
    with open(PROGRESS_FILE, 'w', encoding='utf-8') as f:
        json.dump(progress, f, ensure_ascii=False, indent=2)


def call_gemini_api(word):
    """Gemini API'ye istek at"""
    if API_KEY == "BURAYA_API_ANAHTARINIZI_YAZIN":
        print("❌ API anahtarı ayarlanmamış! GEMINI_API_KEY ortam değişkenini ayarlayın.")
        return None
    
    prompt = ENRICHMENT_PROMPT.format(word=word)
    
    headers = {
        "Content-Type": "application/json"
    }
    
    payload = {
        "contents": [{
            "parts": [{
                "text": prompt
            }]
        }],
        "generationConfig": {
            "temperature": 0.0,
            "maxOutputTokens": 2048,
            "responseMimeType": "application/json"
        }
    }
    
    url = f"{API_URL}?key={API_KEY}"
    
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        
        result = response.json()
        
        # Gemini yanıtından metni çıkar
        if 'candidates' in result and len(result['candidates']) > 0:
            text = result['candidates'][0]['content']['parts'][0]['text']
            
            # JSON'u parse et
            # Markdown kod bloğu varsa temizle
            text = text.strip()
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]
            text = text.strip()
            
            try:
                return json.loads(text)
            except json.JSONDecodeError as e:
                print(f"⚠️ JSON parse hatası ({word}): {e}")
                print(f"   Ham yanıt: {text[:200]}...")
                return None
        else:
            print(f"⚠️ Beklenmeyen API yanıtı: {result}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"❌ API isteği başarısız ({word}): {e}")
        return None
    except Exception as e:
        print(f"❌ Beklenmeyen hata ({word}): {e}")
        return None


def process_batch(words, start_index, batch_num):
    """Bir batch kelimeyi işle"""
    results = []
    
    for i, word in enumerate(words):
        current_index = start_index + i
        print(f"  🔄 [{current_index + 1}] {word}...", end=" ")
        
        result = call_gemini_api(word)
        
        if result:
            results.append(result)
            print("✅")
        else:
            # Hata durumunda temel yapı oluştur
            results.append({
                "bulunduMu": False,
                "kelimeBilgisi": {
                    "kelime": word,
                    "harekeliKelime": "",
                    "koku": "",
                    "anlam": "API hatası - manuel kontrol gerekli",
                    "esAnlamlilar": "",
                    "zitAnlamlilar": "",
                    "dilbilgiselOzellikler": {"tur": "", "cogulForm": ""},
                    "fiilCekimler": {"maziForm": "", "muzariForm": "", "mastarForm": "", "emirForm": ""},
                    "ornekCumleler": []
                }
            })
            print("⚠️ (Hatalı)")
        
        # Rate limiting
        time.sleep(RATE_LIMIT_DELAY)
    
    return results


def save_batch(results, batch_num):
    """Batch sonuçlarını kaydet"""
    OUTPUT_DIR.mkdir(exist_ok=True)
    
    output_file = OUTPUT_DIR / f"gemini_enriched_batch_{batch_num}.json"
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    print(f"💾 Batch {batch_num} kaydedildi: {output_file}")
    return output_file


def main():
    parser = argparse.ArgumentParser(description="Gemini API ile Arapça kelime zenginleştirici")
    parser.add_argument("--start", type=int, default=0, help="Başlangıç indeksi")
    parser.add_argument("--count", type=int, default=100, help="İşlenecek kelime sayısı")
    parser.add_argument("--resume", action="store_true", help="Kaldığı yerden devam et")
    parser.add_argument("--batch-size", type=int, default=BATCH_SIZE, help="Batch boyutu")
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("🚀 Gemini API Kelime Zenginleştirici")
    print("=" * 60)
    
    # Kelime listesini yükle
    words = load_words()
    if not words:
        return
    
    # İlerleme durumunu kontrol et
    progress = load_progress()
    
    if args.resume:
        start_index = progress["last_index"]
        print(f"📍 Kaldığı yerden devam ediliyor: index {start_index}")
    else:
        start_index = args.start
    
    end_index = min(start_index + args.count, len(words))
    batch_size = args.batch_size
    
    print(f"📊 Toplam kelime: {len(words)}")
    print(f"📍 Başlangıç: {start_index}, Bitiş: {end_index}")
    print(f"📦 Batch boyutu: {batch_size}")
    print("-" * 60)
    
    # API anahtarı kontrolü
    if API_KEY == "BURAYA_API_ANAHTARINIZI_YAZIN":
        print("\n❌ HATA: API anahtarı ayarlanmamış!")
        print("   Şu yöntemlerden birini kullanın:")
        print("   1. GEMINI_API_KEY ortam değişkenini ayarlayın")
        print("   2. Script içindeki API_KEY değişkenini düzenleyin")
        print("\n   API anahtarı almak için: https://aistudio.google.com/app/apikey")
        return
    
    current_batch = progress.get("last_batch", 0) + 1
    processed_total = 0
    
    try:
        for batch_start in range(start_index, end_index, batch_size):
            batch_end = min(batch_start + batch_size, end_index)
            batch_words = words[batch_start:batch_end]
            
            print(f"\n📦 Batch {current_batch}: kelime {batch_start + 1} - {batch_end}")
            print("-" * 40)
            
            # Batch'i işle
            results = process_batch(batch_words, batch_start, current_batch)
            
            # Kaydet
            save_batch(results, current_batch)
            
            # İlerlemeyi güncelle
            progress["last_index"] = batch_end
            progress["processed_count"] += len(results)
            progress["last_batch"] = current_batch
            progress["last_update"] = datetime.now().isoformat()
            save_progress(progress)
            
            processed_total += len(results)
            current_batch += 1
            
            # İlerleme bilgisi
            total_done = batch_end
            percent = (total_done / len(words)) * 100
            print(f"📈 İlerleme: {total_done}/{len(words)} (%{percent:.2f})")
            
    except KeyboardInterrupt:
        print("\n\n⚠️ İşlem kullanıcı tarafından durduruldu.")
        print(f"   Son işlenen index: {progress['last_index']}")
        print("   'python gemini_enricher.py --resume' ile devam edilebilir.")
    
    print("\n" + "=" * 60)
    print(f"✅ Tamamlandı! {processed_total} kelime işlendi.")
    print(f"📁 Çıktılar: {OUTPUT_DIR}")
    print("=" * 60)


if __name__ == "__main__":
    main()
