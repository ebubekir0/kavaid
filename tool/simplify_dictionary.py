import json
import re
import os

def process_segment(segment_text, is_base):
    if not segment_text.strip():
        return ""
    
    items = [x.strip() for x in segment_text.split(',')]
    items = [x for x in items if x]
    
    result_items = []
    arabic_regex = re.compile(r'[\u0600-\u06FF]')
    
    current_limit = 6 if is_base else 2
    current_count = 0
    
    for item in items:
        # If it's the base part and contains Arabic characters, reset count and set limit to 2
        # So we keep the Arabic root/word and its first 2 translations
        if is_base and arabic_regex.search(item):
            current_limit = 2
            current_count = 0
            
        if current_count < current_limit:
            result_items.append(item)
            current_count += 1
            
    return ', '.join(result_items)

def simplify_meanings(text):
    parts = re.split(r'(<blue>\[.*?\]</blue>)', text)
    
    final_result = []
    
    # Process the first part (base meanings)
    base_segment = parts[0]
    processed_base = process_segment(base_segment, is_base=True)
    if processed_base:
        final_result.append(processed_base)
        
    # Process harf-i cer parts
    for i in range(1, len(parts), 2):
        tag = parts[i].strip()
        content = parts[i+1] if i+1 < len(parts) else ""
        
        processed_content = process_segment(content, is_base=False)
        
        if processed_content:
            final_result.append(f"{tag} {processed_content}")
        else:
            final_result.append(tag)
            
    return ", ".join(final_result)

def main():
    base_dir = r"c:\Users\kul\Desktop\kavaid1111\kavaid"
    input_file = os.path.join(base_dir, "SOZLUK_TEMIZ.json")
    output_file = os.path.join(base_dir, "SOZLUK_KISA_ANLAMLI.json")
    
    print(f"Reading {input_file}...")
    with open(input_file, "r", encoding="utf-8") as f:
        data = json.load(f)
        
    print(f"Total words before processing: {len(data)}")
    
    new_data = {}
    for key, value in data.items():
        if isinstance(value, str):
            new_data[key] = simplify_meanings(value)
        else:
            new_data[key] = value
            
    print(f"Total words after processing: {len(new_data)}")
        
    print(f"Writing {output_file}...")
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(new_data, f, ensure_ascii=False, indent=2)
        
    print("Optimization completed!")
    
    # Let's verify a few random examples to show in console
    samples = ["الْعَالِيَةُ", "الْعَامُّ", "الْعَدْلُ"]
    print("\n--- SAMPLES ---")
    for s in samples:
        if s in new_data:
            print(f"\nWord: {s}")
            print(f"Original: {data[s][:150]}...")
            print(f"Simplified: {new_data[s]}")

if __name__ == "__main__":
    main()
