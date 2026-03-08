import json
import os
from pathlib import Path

# Yapılandırma
BASE_DIR = Path(r"c:\Users\kul\Desktop\kavaid1111\kavaid\tool")
WORD_LIST_FILE = BASE_DIR / "firebase_word_list.txt"
BATCH_INPUT_FILE = BASE_DIR / "gemini_3_batch_input.jsonl"

def generate_gemini3_batch_file():
    if not WORD_LIST_FILE.exists():
        print(f"❌ Kelime listesi bulunamadı: {WORD_LIST_FILE}")
        return

    with open(WORD_LIST_FILE, "r", encoding="utf-8") as f:
        words = [line.strip() for line in f if line.strip()]

    print(f"🔄 {len(words)} kelime için Gemini 3 Flash Batch dosyası hazırlanıyor...")

    with open(BATCH_INPUT_FILE, "w", encoding="utf-8") as out:
        for idx, word in enumerate(words):
            # Gemini 3 Flash için optimize edilmiş prompt
            prompt = f'''Sen bir Arapça-Türkçe sözlüksün. Aşağıdaki kelimenin sadece en doğru, güvenilir ve yaygın kullanılan Türkçe anlamlarını vereceksin. 

KAPSAM VE SINIR KURALLARI:
- Anlamları en yaygın kullanımdan en az yaygın kullanıma doğru numaralandır.
- Maksimum limit: Gerekliyse ve gerçekten var olan anlamları taşıyorsa en fazla 20-25 anlama kadar genişletebilirsin.
- Harf-i cerleri doğrudan <blue>[harf]</blue> formatında belirt.

Kelime: "{word}"

Sadece aşağıdaki JSON formatında çıktı ver:
{{
  "kelime": "{word}",
  "anlam": "anlam metni"
}}'''

            # Gemini 3 API Yapısı (JSONL formatı)
            # request object içinde GenerateContentRequest olmalı
            request_payload = {
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {
                    "temperature": 0.2,
                    # Gemini 3 Flash için thinkingConfig (thinkingLevel) ekliyoruz
                    "thinkingConfig": {
                        "thinkingLevel": "low"
                    },
                    "response_mime_type": "application/json"
                }
            }
            
            # Google AI Studio Batch API formatı: 
            # Her satır bir JSON objesi ve 'request' anahtarı altında GenerateContentRequest içermeli
            batch_entry = {
                "custom_id": f"word_{idx}", # Takip için opsiyonel ID
                "request": request_payload
            }
            
            out.write(json.dumps(batch_entry, ensure_ascii=False) + "\n")

    print(f"✅ Gemini 3 Flash Batch dosyası hazır: {BATCH_INPUT_FILE}")
    print(f"💡 Önemli: Bu dosya v1alpha/Gemini 3 Flash parametrelerini içerir.")

if __name__ == "__main__":
    generate_gemini3_batch_file()
