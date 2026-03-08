#!/usr/bin/env python3
"""
Batch Job Durum Kontrolü + Sonuç İndirme
Kullanım: python tool/check_batch.py
"""
import json
import requests
from pathlib import Path

API_KEY  = "AIzaSyB6v5JGqHXTJ3OtmtYtkM7UGHwGMCCmDYE"
JOB_NAME = "batches/in6wmjezkz79jfkejmrkcr322kk3umcq7o46"  # Yeni Gemini 3 Flash testi
BASE_DIR = Path(r"c:\Users\kul\Desktop\kavaid1111\kavaid\tool")
TEST_BATCH_FILE = BASE_DIR / "TEST_100_BATCH_INPUT.jsonl"
RESULTS_FILE    = BASE_DIR / "TEST_100_BATCH_OUTPUT.jsonl"

def check_and_save():
    url = f"https://generativelanguage.googleapis.com/v1beta/{JOB_NAME}?key={API_KEY}"
    r = requests.get(url, timeout=30)
    data = r.json()
    
    meta = data.get("metadata", {})
    state = meta.get("state", data.get("done", False))
    stats = meta.get("batchStats", {})
    
    print(f"📊 Batch Job Durumu")
    print(f"   Job: {JOB_NAME}")
    print(f"   Durum: {state}")
    if stats:
        print(f"   Toplam: {stats.get('requestCount', '?')}")
        print(f"   Başarılı: {int(stats.get('requestCount',0)) - int(stats.get('failedRequestCount',0))}")
        print(f"   Hatalı: {stats.get('failedRequestCount', '?')}")
    
    # Tamamlandıysa sonuçları çıkar
    done = data.get("done", False)
    response = data.get("response", {}) or meta.get("output", {})
    inlined = (response.get("inlinedResponses", {}) or {}).get("inlinedResponses", [])
    
    if not inlined:
        # metadata->output->inlinedResponses
        inlined = (meta.get("output", {}).get("inlinedResponses", {}) or {}).get("inlinedResponses", [])
    
    if done and inlined:
        # Orijinal kelimeleri oku
        with open(TEST_BATCH_FILE, "r", encoding="utf-8") as f:
            originals = [json.loads(l) for l in f if l.strip()]
        
        results = []
        errors = 0
        print(f"\n{'='*55}")
        print(f"  📖 SONUÇLAR ({len(inlined)} yanıt)")
        print(f"{'='*55}")
        
        for idx, resp in enumerate(inlined):
            if "error" in resp:
                errors += 1
                print(f"\n[{idx+1:3d}] ❌ Hata: {resp['error'].get('message','?')[:60]}")
                continue
            
            try:
                word_prompt = originals[idx]["request"]["contents"][0]["parts"][0]["text"]
                wl = [l for l in word_prompt.split('\n') if 'Kelime:' in l]
                word = wl[0].split('"')[1] if wl else f"kelime_{idx}"
            except Exception:
                word = f"kelime_{idx}"
            
            try:
                text = resp["candidates"][0]["content"]["parts"][0]["text"]
                text = text.replace("```json","").replace("```","").strip()
                parsed = json.loads(text)
                anlam = parsed.get("anlam","")
                results.append({"kelime": word, "anlam": anlam})
                print(f"\n[{idx+1:3d}] 📖 {word}")
                print(f"      {anlam}")
            except Exception as e:
                errors += 1
                print(f"\n[{idx+1:3d}] ⚠️  {word}: parse hatası ({e})")
        
        # Kaydet
        with open(RESULTS_FILE, "w", encoding="utf-8") as f:
            for res in results:
                f.write(json.dumps(res, ensure_ascii=False) + "\n")
        
        print(f"\n{'='*55}")
        print(f"✅ {len(results)} başarılı | ❌ {errors} hatalı")
        print(f"📁 Kaydedildi: {RESULTS_FILE}")
    elif not done:
        print("\n⏳ Henüz tamamlanmadı, biraz sonra tekrar deneyin.")
        print("   python tool/check_batch.py")

if __name__ == "__main__":
    check_and_save()
