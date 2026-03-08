#!/usr/bin/env python3
"""
Doğru Gemini Batch API - Resmi Dokümantasyona Göre (v1beta)
Eski job'u kontrol et, gerekirse yenisini başlat.
"""
import json
import time
from pathlib import Path
from google import genai

API_KEY = "AIzaSyB6v5JGqHXTJ3OtmtYtkM7UGHwGMCCmDYE"
BASE_DIR = Path(r"c:\Users\kul\Desktop\kavaid1111\kavaid\tool")
TEST_BATCH_FILE = BASE_DIR / "TEST_100_BATCH_INPUT.jsonl"
RESULTS_FILE    = BASE_DIR / "TEST_100_BATCH_OUTPUT.jsonl"
OLD_JOB         = "batches/pr5iq8mx2nh9aj56rh061gkn3sei9tjuj7zx"

MODEL = "gemini-3-flash-preview"

# Resmi dokümantasyona göre client - API key ile
client = genai.Client(api_key=API_KEY)

def check_old_job():
    """Eski job'un durumunu kontrol et"""
    print(f"🔍 Eski job kontrol ediliyor: {OLD_JOB}")
    try:
        job = client.batches.get(name=OLD_JOB)
        state = str(job.state)
        print(f"   Durum: {state}")
        return state, job
    except Exception as e:
        print(f"   ❌ Hata: {e}")
        return None, None

def build_requests():
    """JSONL dosyasından doğru formatta istek listesi oluştur"""
    requests = []
    with open(TEST_BATCH_FILE, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            entry = json.loads(line)
            req = entry["request"]
            prompt = req["contents"][0]["parts"][0]["text"]
            
            # SDK inline format: sadece contents (generationConfig ayrı)
            requests.append({
                "contents": [{
                    "parts": [{"text": prompt}],
                    "role": "user"
                }]
            })
    return requests

def save_results(job):
    """Tamamlanmış job'dan sonuçları al"""
    with open(TEST_BATCH_FILE, "r", encoding="utf-8") as f:
        originals = [json.loads(l) for l in f if l.strip()]

    results = []
    errors = 0
    
    # inline_responses listesine eriş
    try:
        responses = list(job.inline_responses)
    except Exception:
        responses = []
        print("⚠️ inline_responses erişilemedi, batch_stats kontrol ediliyor...")
        if hasattr(job, 'batch_stats'):
            print(f"   Stats: {job.batch_stats}")
        return

    print(f"\n{'='*55}")
    print(f"  📊 BATCH SONUÇLARI ({len(responses)} yanıt)")
    print(f"{'='*55}")

    for idx, resp in enumerate(responses):
        try:
            prompt_text = originals[idx]["request"]["contents"][0]["parts"][0]["text"]
            wl = [l for l in prompt_text.split('\n') if 'Kelime:' in l]
            word = wl[0].split('"')[1] if wl else f"kelime_{idx}"
        except Exception:
            word = f"kelime_{idx}"

        try:
            text = resp.candidates[0].content.parts[0].text
            text = text.replace("```json","").replace("```","").strip()
            parsed = json.loads(text)
            anlam = parsed.get("anlam","")
            results.append({"kelime": word, "anlam": anlam})
            print(f"\n[{idx+1:3d}] 📖 {word}")
            print(f"      {anlam}")
        except Exception as e:
            errors += 1
            print(f"\n[{idx+1:3d}] ⚠️  {word}: {e}")

    with open(RESULTS_FILE, "w", encoding="utf-8") as f:
        for r in results:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    print(f"\n✅ {len(results)} başarılı | ❌ {errors} hatalı")
    print(f"📁 Kaydedildi: {RESULTS_FILE}")

def new_batch_job():
    """Yeni batch job başlat (resmi dok formatında)"""
    print(f"\n🚀 Yeni batch job başlatılıyor...")
    print(f"   Model: {MODEL}")
    
    requests = build_requests()
    print(f"   {len(requests)} istek hazır")
    
    # Resmi dokümantasyona göre kullanım:
    # client.batches.create(model=..., src=[...inline requests...])
    batch_job = client.batches.create(
        model=MODEL,
        src=requests,
        config={"display_name": "kavaid-100-kelime-test"},
    )
    
    print(f"✅ Batch job oluşturuldu: {batch_job.name}")
    print(f"   Durum: {batch_job.state}")
    print(f"\n⏳ Tamamlanması bekleniyor (her 30sn kontrol)...")
    
    while True:
        time.sleep(30)
        job = client.batches.get(name=batch_job.name)
        state = str(job.state)
        from datetime import datetime
        print(f"   [{datetime.now().strftime('%H:%M:%S')}] {state}")
        
        if any(s in state for s in ["SUCCEEDED", "COMPLETED"]):
            print("✅ Tamamlandı!")
            save_results(job)
            break
        elif any(s in state for s in ["FAILED", "CANCELLED", "EXPIRED"]):
            print(f"❌ Job başarısız: {state}")
            break

def main():
    print("="*55)
    print("  🔧 GEMINI BATCH API - DOĞRU UYGULAMA (v1beta resmi)")
    print("="*55)
    
    # 1. Önce eski job'u kontrol et
    state, job = check_old_job()
    
    if state and "SUCCEEDED" in state:
        print("\n✅ Eski job tamamlanmış! Sonuçlar alınıyor...")
        save_results(job)
    elif state and "PENDING" in state:
        print("\n⏳ Eski job hâlâ bekliyor (24 saat SLO)")
        print("   Yeni bir job başlatılıyor (daha güvenilir)...")
        new_batch_job()
    elif state and "EXPIRED" in state:
        print("\n⚠️ Eski job süresi dolmuş! Yeni job başlatılıyor...")
        new_batch_job()
    else:
        print("\n🆕 Yeni job başlatılıyor...")
        new_batch_job()

if __name__ == "__main__":
    main()
