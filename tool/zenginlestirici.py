import csv
import time
import os
import json
import requests

# ---------------- CONFIGURATION ----------------
# Buraya OpenAI veya Gemini API anahtarınızı girin
API_KEY = "BURAYA_API_ANAHTARINIZI_YAZIN"
# Kullanılacak model (gpt-3.5-turbo, gpt-4, gemini-pro vb.)
MODEL = "gpt-3.5-turbo" 

INPUT_CSV = r'c:\Users\kul\Desktop\kavaid1111\kelimeler_genisletilmis.csv'
OUTPUT_CSV = r'c:\Users\kul\Desktop\kavaid1111\kelimeler_zenginlesmis_final.csv'
# -----------------------------------------------

def get_rich_meanings_from_ai(word, current_meaning):
    if API_KEY == "BURAYA_API_ANAHTARINIZI_YAZIN":
        return "API Anahtarı Eksik - Lütfen script dosyasını düzenleyin."
    
    prompt = f"""
    Aşağıdaki Arapça kelime için Türkçe anlamlar listesi oluştur.
    Kelime: {word}
    Mevcut Anlam: {current_meaning}
    
    İstekler:
    1. En yaygın ve temel anlamdan başlayarak en az 10, en fazla 15 farklı Türkçe karşılık veya eşanlamlı ver.
    2. Anlamları önem sırasına göre virgülle ayırarak tek bir satırda yaz.
    3. Sadece anlamları yaz, numara veya açıklama ekleme.
    Örnek Çıktı: kitap, yazılı eser, mecmua, defter, yapıt...
    """
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }
    
    payload = {
        "model": MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.3
    }
    
    try:
        response = requests.post("https://api.openai.com/v1/chat/completions", headers=headers, json=payload)
        response_json = response.json()
        if 'choices' in response_json:
            return response_json['choices'][0]['message']['content'].strip()
        else:
            print(f"Hata: {response_json}")
            return ""
    except Exception as e:
        print(f"İstek hatası: {e}")
        return ""

def main():
    if not os.path.exists(INPUT_CSV):
        print(f"❌ Girdi dosyası bulunamadı: {INPUT_CSV}")
        return

    print("🚀 Kelime zenginleştirme işlemi başlıyor...")
    
    with open(INPUT_CSV, 'r', encoding='utf-8') as infile, \
         open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as outfile:
        
        reader = csv.DictReader(infile)
        fieldnames = reader.fieldnames
        # Ensure our target column exists
        if 'yeni_anlamlar_1_15' not in fieldnames:
            fieldnames.append('yeni_anlamlar_1_15')
            
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        
        count = 0
        for row in reader:
            word = row['kelime']
            current_meaning = row['mevcut_anlam']
            
            # Sadece boş olanları veya hepsini güncellemek için mantık
            # Şimdilik hepsini güncelliyoruz
            
            print(f"🔄 İşleniyor ({count+1}): {word}")
            
            rich_meanings = get_rich_meanings_from_ai(word, current_meaning)
            row['yeni_anlamlar_1_15'] = rich_meanings
            
            writer.writerow(row)
            outfile.flush() # Her satırda kaydet
            
            count += 1
            # Rate limit önlemi
            time.sleep(0.5)

    print(f"✅ Tamamlandı. Dosya: {OUTPUT_CSV}")

if __name__ == '__main__':
    main()
