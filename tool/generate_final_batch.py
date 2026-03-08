import json
import os
from pathlib import Path

# Yapılandırma
BASE_DIR = Path(r"c:\Users\kul\Desktop\kavaid1111\kavaid\tool")
WORD_LIST_FILE = BASE_DIR / "firebase_word_list.txt"
BATCH_INPUT_FILE = BASE_DIR / "GEMINI3_FINAL_BATCH_INPUT.jsonl"

def generate_final_batch_file():
    if not WORD_LIST_FILE.exists():
        print(f"❌ Kelime listesi bulunamadı: {WORD_LIST_FILE}")
        return

    with open(WORD_LIST_FILE, "r", encoding="utf-8") as f:
        words = [line.strip() for line in f if line.strip()]

    print(f"🔄 {len(words)} kelime için Gemini 3 Flash FINAL Batch dosyası hazırlanıyor...")
    print(f"📍 Hedef: Modern + Klasik kapsam, Numarasız, Max 30 Anlam, Gemini 3 Flash v1alpha")

    with open(BATCH_INPUT_FILE, "w", encoding="utf-8") as out:
        for idx, word in enumerate(words):
            # Gemini 3 Flash v1alpha için Final Optimize Edilmiş Prompt
            prompt = f'''Sen bir Arapça-Türkçe sözlüksün. Aşağıdaki kelimenin MODERN, KLASİK ve GÜNCEL tüm anlamlarını içeren oldukça KAPSAMLI ve uzman seviyesinde bir karşılık vereceksin. 

ANLAM KURALLARI:
- Anlamları en yaygın ve en alakalı olandan başlayarak az yaygın olana doğru sırala.
- Anlamları asla 1, 2, 3 gibi NUMARALANDIRMA. Sadece VİRGÜL (,) kullanarak sırayla yaz.
- Kapsam: Gerekliyse ve gerçekte varsa 30 anlama kadar çıkabilirsin. Ancak zorlama/uydurma yapma.
- FİİL İSE: Önce yalın halinin tüm (modern/klasik) anlamlarını yaz. Sonra bu fiilin en çok kullanıldığı harf-i cerleri <blue>[harf]</blue> formatında belirtip o harfle kazandığı tüm anlamları virgülle ekle.
- Format Örneği: Anlam1, Anlam2, Anlam3, <blue>[في]</blue> anlam4, <blue>[عن]</blue> anlam5, anlam6...

Başka hiçbir açıklama, örnek veya gramer bilgisi yazma. Sadece aşağıdaki JSON formatında çıktı ver:

Kelime: "{word}"

{{
  "kelime": "{word}",
  "anlam": "Ürettiğin tüm kapsamlı anlam metnini buraya tek bir string olarak yaz."
}}'''

            # Gemini 3 API Yapısı
            request_payload = {
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {
                    "temperature": 0.3, # Daha zengin kelime haznesi için 0.3
                    "thinkingConfig": {
                        "thinkingLevel": "low"
                    },
                    "response_mime_type": "application/json"
                }
            }
            
            batch_entry = {
                "custom_id": f"word_{idx}",
                "request": request_payload
            }
            
            out.write(json.dumps(batch_entry, ensure_ascii=False) + "\n")

    print(f"\n✅ FINAL BATCH DOSYASI HAZIR: {BATCH_INPUT_FILE}")
    print(f"📊 Toplam İstek Sayısı: {len(words)}")
    print(f"💡 Önemli: Bu dosyayı AI Studio Batch Jobs ekranına yükleyerek işlemi başlatabilirsiniz.")

if __name__ == "__main__":
    generate_final_batch_file()
