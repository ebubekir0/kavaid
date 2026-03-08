import json
import firebase_admin
from firebase_admin import credentials, db
from pathlib import Path

# Firebase Ayarları
BASE_DIR = Path(r"c:\Users\kul\Desktop\kavaid1111\kavaid\tool")
CRED_PATH = r"c:\Users\kul\Desktop\kavaid1111\kavaid\serviceAccountKey.json" # Yolunuzu doğrulayın
RESULTS_FILE = BASE_DIR / "gemini_batch_output.jsonl" # İndirdiğiniz sonuç dosyası ismi

def sync_batch_results_to_firebase():
    if not RESULTS_FILE.exists():
        print(f"❌ Sonuç dosyası henüz mevcut değil: {RESULTS_FILE}")
        print("💡 Lütfen AI Studio'dan indirdiğiniz dosyayı bu isimle 'tool' klasörüne koyun.")
        return

    # Firebase'i initialize et
    if not firebase_admin._apps:
        cred = credentials.Certificate(CRED_PATH)
        firebase_admin.initialize_app(cred, {
            'databaseURL': 'https://kavaid-2f778-default-rtdb.europe-west1.firebasedatabase.app'
        })

    ref = db.reference('kelimeler')
    
    print("🔄 Batch sonuçları Firebase'e aktarılıyor...")
    
    success_count = 0
    with open(RESULTS_FILE, "r", encoding="utf-8") as f:
        for line in f:
            try:
                data = json.loads(line)
                # Gemini yanıtını parse et
                response_text = data['response']['candidates'][0]['content']['parts'][0]['text']
                
                # Markdown temizle ve JSON'a çevir
                clean_json = response_text.replace('```json', '').replace('```', '').strip()
                parsed = json.loads(clean_json)
                
                kelime = parsed['kelime']
                yeni_anlam = parsed['anlam']
                
                # Firebase'de sadece kelimeyi bul ve anlamı güncelle
                # Not: Firebase key'iniz harekeli hali ise arama mantığı değişebilir.
                # Burada kelimeyi bulmak için query kullanıyoruz:
                words_query = ref.order_by_child('kelime').equal_to(kelime).get()
                
                if words_query:
                    for key in words_query.keys():
                        ref.child(key).update({
                            'anlam': yeni_anlam,
                            'last_batch_update': 'gemini-3-flash-batch'
                        })
                    success_count += 1
                    if success_count % 100 == 0:
                        print(f"✅ {success_count} kelime güncellendi...")
                
            except Exception as e:
                print(f"⚠️ Satır işlenirken hata: {e}")

    print(f"\n🎉 BİTTİ! Toplam {success_count} kelime güncellendi.")

if __name__ == "__main__":
    sync_batch_results_to_firebase()
