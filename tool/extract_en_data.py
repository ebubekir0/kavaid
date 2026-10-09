
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
    en_meanings = {}
    en_harficers = {}
    en_examples = {}

    # 1. Meanings
    if os.path.exists("ANLAM_BATCH_SONUCLAR_EN.jsonl"):
        with open("ANLAM_BATCH_SONUCLAR_EN.jsonl", "r", encoding="utf-8") as f:
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
                    meanings = res_json.get("meanings", "")
                    en_meanings[word] = meanings
                    # Also store normalized word for matching
                    en_meanings[normalize_arabic(word)] = meanings
                    
                    for p in res_json.get("prepositions", []):
                        prep_harf = p.get("prep")
                        prep_meanings = p.get("meanings")
                        if prep_harf and prep_meanings:
                            en_harficers[f"{word}_{prep_harf}"] = prep_meanings
                            en_harficers[f"{normalize_arabic(word)}_{normalize_arabic(prep_harf)}"] = prep_meanings
                except:
                    pass

    # 2. Examples
    if os.path.exists("ORNEK_EN_BATCH_SONUCLAR.jsonl"):
        with open("ORNEK_EN_BATCH_SONUCLAR.jsonl", "r", encoding="utf-8") as f:
            for line in f:
                try:
                    data = json.loads(line)
                    arabic_sent = data.get("_arabic")
                    if not arabic_sent: continue
                    
                    text = data.get("response", {}).get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
                    if "{" in text:
                        text = text[text.find("{"):text.rfind("}")+1]
                    
                    res_json = json.loads(text)
                    english = res_json.get("english", "")
                    if english:
                        # Original key
                        en_examples[arabic_sent] = english
                        # Normalized key for better matching
                        norm = normalize_arabic(arabic_sent)
                        if norm:
                            en_examples[norm] = english
                except:
                    pass

    # 3. Write
    with open("lib/data/en_translations.dart", "w", encoding="utf-8") as f:
        f.write("// ignore_for_file: constant_identifier_names\n\n")
        f.write("const Map<String, String> enMeaningsMap = {\n")
        for k, v in en_meanings.items():
            f.write(f"  {json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)},\n")
        f.write("};\n\n")

        f.write("const Map<String, String> enHarfiCerMap = {\n")
        for k, v in en_harficers.items():
            f.write(f"  {json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)},\n")
        f.write("};\n\n")
        
        f.write("const Map<String, String> enExamplesMap = {\n")
        for k, v in en_examples.items():
            f.write(f"  {json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)},\n")
        f.write("};\n")

if __name__ == "__main__":
    extract()
