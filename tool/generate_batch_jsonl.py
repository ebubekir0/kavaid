import json
import os
from pathlib import Path

# Yapılandırma
BASE_DIR = Path(r"c:\Users\kul\Desktop\kavaid1111\kavaid\tool")
WORD_LIST_FILE = BASE_DIR / "firebase_word_list.txt"
BATCH_INPUT_FILE = BASE_DIR / "gemini_batch_input.jsonl"

def generate_batch_file():
    if not WORD_LIST_FILE.exists():
        print(f"❌ Kelime listesi bulunamadı: {WORD_LIST_FILE}")
        return

    with open(WORD_LIST_FILE, "r", encoding="utf-8") as f:
        words = [line.strip() for line in f if line.strip()]

    print(f"🔄 {len(words)} kelime için Batch dosyası hazırlanıyor...")

    with open(BATCH_INPUT_FILE, "w", encoding="utf-8") as out:
        for word in words:
            # Sizin en son onayladığınız kapsamlı prompt
            prompt = f'''Sen bir Arapça-Türkçe sözlüksün. Aşağıdaki kelimenin sadece en doğru, güvenilir ve yaygın kullanılan Türkçe anlamlarını vereceksin. 

KAPSAM VE SINIR KURALLARI:
- Anlamları en yaygın kullanımdan en az yaygın kullanıma doğru numaralandır.
- Maksimum limit: Gerekliyse ve gerçekten var olan anlamları taşıyorsa en fazla 20-25 anlama kadar genişletebilirsin.
- ZORLAMA YASAK: Her kelime için 20 anlam uydurmak ZORUNDA DEĞİLSİN!
- Harf-i cerleri doğrudan <blue>[harf]</blue> formatında belirt.

Kelime: "{word}"

Sadece aşağıdaki JSON formatında çıktı ver:
{{
  "kelime": "{word}",
  "anlam": "anlam metni"
}}'''

            # Batch API JSONL Formatı
            request_data = {
                "request": {
                    "contents": [{"parts": [{"text": prompt}]}],
                    "generationConfig": {
                        "temperature": 0.2,
                        "response_mime_type": "application/json"
                    }
                }
            }
            # Her satıra bir JSON objesi
            out.write(json.dumps(request_data, ensure_ascii=False) + "\n")

    print(f"✅ Batch dosyası hazır: {BATCH_INPUT_FILE}")
    print(f"💡 Bu dosyayı Google AI Studio üzerinden 'Batch Jobs' kısmına yükleyebilirsiniz.")

if __name__ == "__main__":
    generate_batch_file()
