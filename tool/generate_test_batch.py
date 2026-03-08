import json
import re
import random
from pathlib import Path

BASE_DIR = Path(r"c:\Users\kul\Desktop\kavaid1111\kavaid\tool")
WORD_LIST_FILE = BASE_DIR / "firebase_word_list.txt"
TEST_BATCH_FILE = BASE_DIR / "TEST_100_BATCH_INPUT.jsonl"
TEST_SIZE = 100

def is_arabic(word):
    """Sadece Arapça karakterler içeren kelimeleri filtrele (en az 2 harf)"""
    arabic_pattern = re.compile(r'^[\u0600-\u06FF\u064B-\u065F\u0670\u0621-\u064A\s]{2,}$')
    return bool(arabic_pattern.match(word.strip()))

def generate_test_batch():
    if not WORD_LIST_FILE.exists():
        print(f"❌ Kelime listesi bulunamadı: {WORD_LIST_FILE}")
        return

    with open(WORD_LIST_FILE, "r", encoding="utf-8") as f:
        all_words = [line.strip() for line in f if line.strip()]

    # Sadece Arapça kelimeleri filtrele
    arabic_words = [w for w in all_words if is_arabic(w)]
    
    # Listeyi bone göre eşit aralıklı örneklem al (baştan, ortadan, sondan)
    random.seed(42)  # Tekrarlanabilir sonuç
    step = len(arabic_words) // TEST_SIZE
    test_words = [arabic_words[i * step] for i in range(TEST_SIZE)]
    
    print(f"📊 Toplam kelime: {len(all_words)}")
    print(f"📊 Arapça kelime: {len(arabic_words)}")
    print(f"🧪 Test seti: {len(test_words)} kelime")
    print(f"💵 Tahmini test maliyeti: ~${len(test_words) * 0.000024:.4f}")

    with open(TEST_BATCH_FILE, "w", encoding="utf-8") as out:
        for idx, word in enumerate(test_words):
            prompt = f'''Sen bir Arapça-Türkçe sözlüksün. Aşağıdaki kelimenin MODERN, KLASİK ve GÜNCEL tüm anlamlarını içeren KAPSAMLI bir karşılık vereceksin.

KURALLAR:
- ⚠️ SIRALAMA: Anlamları en yaygın ve en çok kullanılan temel anlamdan başla, giderek daha az yaygın olanlara doğru sırala.
- Anlamları 1, 2, 3 gibi NUMARALANDIRMA. Sadece VİRGÜL (,) kullanarak sırayla yaz.
- Kapsam: Gerekliyse ve gerçekte varsa 30 anlama kadar çıkabilirsin. Zorlama ve uydurma yapma.
- FİİL İSE: Yalın anlamlardan sonra harf-i cerleri <blue>[harf]</blue> formatıyla yaz, o harfle kazandığı anlamları virgülle ekle.
- İSİM İSE: Harf-i cer sadece o isimle kalıplaşmış bir tabir varsa ekle; yoksa sadece anlamları sırala.

Başka hiçbir açıklama yazma. Sadece JSON:

Kelime: "{word}"

{{
  "kelime": "{word}",
  "anlam": "..."
}}'''

            entry = {
                "custom_id": f"test_{idx:04d}",
                "request": {
                    "contents": [{"parts": [{"text": prompt}]}],
                    "generationConfig": {
                        "temperature": 0.3,
                        "thinkingConfig": {"thinkingLevel": "low"},
                        "response_mime_type": "application/json"
                    }
                }
            }
            out.write(json.dumps(entry, ensure_ascii=False) + "\n")

    print(f"\n✅ Test Batch dosyası hazır: {TEST_BATCH_FILE}")
    print(f"\n📋 İlk 10 test kelimesi:")
    for i, w in enumerate(test_words[:10]):
        print(f"   {i+1}. {w}")
    
    print(f"\n🚀 Kullanım:")
    print(f"   1. {TEST_BATCH_FILE} dosyasını AI Studio'ya yükle")
    print(f"   2. Model: gemini-3-flash-preview-001 seç")
    print(f"   3. Sonuçları TEST_100_BATCH_OUTPUT.jsonl olarak indir")

if __name__ == "__main__":
    generate_test_batch()
