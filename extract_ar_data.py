
import json
import os
import re

def normalize_arabic(text):
    if not text: return ""
    # Remove diacritics
    text = re.sub(r'[\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]', '', text)
    # Remove punctuation and extra whitespace
    text = re.sub(r'[.,!?;:،؛؟]', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def extract():
    ar_meanings = {}
    ar_harficers = {}
    ar_examples = {}

    # 1. Meanings
    if os.path.exists("ANLAM_BATCH_SONUCLAR_AR.jsonl"):
        with open("ANLAM_BATCH_SONUCLAR_AR.jsonl", "r", encoding="utf-8") as f:
            for line in f:
                try:
                    data = json.loads(line)
                    word = data.get("_word")
                    if not word: continue
                    
                    response = data.get("response", {})
                    candidates = response.get("candidates", [])
                    if not candidates: continue
                    
                    text = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "")
                    if "{" in text:
                        text = text[text.find("{"):text.rfind("}")+1]
                    
                    res_json = json.loads(text)
                    meanings = res_json.get("meanings_ar") or res_json.get("meanings", "")
                    if not meanings: continue
                    
                    ar_meanings[word] = meanings
                    ar_meanings[normalize_arabic(word)] = meanings
                    
                    for p in res_json.get("prepositions", []):
                        prep_harf = p.get("prep")
                        prep_meanings = p.get("meanings")
                        if prep_harf and prep_meanings:
                            ar_harficers[f"{word}_{prep_harf}"] = prep_meanings
                            ar_harficers[f"{normalize_arabic(word)}_{normalize_arabic(prep_harf)}"] = prep_meanings
                except:
                    pass

    # 2. Examples
    if os.path.exists("ORNEK_AR_BATCH_SONUCLAR.jsonl"):
        with open("ORNEK_AR_BATCH_SONUCLAR.jsonl", "r", encoding="utf-8") as f:
            for line in f:
                try:
                    data = json.loads(line)
                    arabic_sent = data.get("_arabic")
                    if not arabic_sent: continue
                    
                    text = data.get("response", {}).get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
                    if "{" in text:
                        text = text[text.find("{"):text.rfind("}")+1]
                    
                    res_json = json.loads(text)
                    ar_text = res_json.get("arabic", "") or res_json.get("meaning", "")
                    if ar_text:
                        ar_examples[arabic_sent] = ar_text
                        norm = normalize_arabic(arabic_sent)
                        if norm:
                            ar_examples[norm] = ar_text
                except:
                    pass

    # 3. Write
    with open("lib/data/ar_translations.dart", "w", encoding="utf-8") as f:
        f.write("// ignore_for_file: constant_identifier_names\n\n")
        f.write("const Map<String, String> arMeaningsMap = {\n")
        for k, v in ar_meanings.items():
            f.write(f"  {json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)},\n")
        f.write("};\n\n")

        f.write("const Map<String, String> arHarfiCerMap = {\n")
        for k, v in ar_harficers.items():
            f.write(f"  {json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)},\n")
        f.write("};\n\n")
        
        f.write("const Map<String, String> arExamplesMap = {\n")
        for k, v in ar_examples.items():
            f.write(f"  {json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)},\n")
        f.write("};\n")

if __name__ == "__main__":
    extract()
