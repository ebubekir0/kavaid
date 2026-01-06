import re
import csv
import json
import os

# Adjust path to absolute based on user workspace
input_path = r'c:\Users\kul\Desktop\kavaid1111\kavaid\lib\data\embedded_words_data.dart'
output_path = r'c:\Users\kul\Desktop\kavaid1111\kelimeler_genisletilmis.csv'

def extract_data_from_dart(file_path):
    print(f"📖 {file_path} okunuyor...")
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Cleaning comments
    content = re.sub(r'//.*', '', content)
    
    # Finding the list content between the first [ and the last ]
    start_index = content.find('[')
    end_index = content.rfind(']')
    
    if start_index == -1 or end_index == -1:
        print("❌ Liste sınırları bulunamadı.")
        return []
    
    list_content = content[start_index+1:end_index]
    
    # Basic cleanup to make it JSON-compliant
    # Remove trailing commas before closing braces/brackets if any (Regex: ,(\s*[}\]])) -> \1
    # But python json parser is strict.
    # The file has objects like {"key":...},
    
    json_str = f"[{list_content}]"
    
    # Python's json library might fail on trailing commas in lists.
    # Simple fix: Remove ",]" -> "]"
    json_str = re.sub(r',\s*\]', ']', json_str)
    
    try:
        data = json.loads(json_str)
        print(f"✅ {len(data)} kelime başarıyla yüklendi.")
        return data
    except json.JSONDecodeError as e:
        print(f"⚠️ Direkt JSON parse hatası: {e}")
        print("Alternatif yöntemle satır satır okunuyor...")
        
        objects = []
        # Fallback: Extract each {...} block manually
        # This relies on the file structure being formatted as one object per line or block
        level = 0
        current_obj_str = ""
        in_string = False
        
        for char in list_content:
            if char == '"' and (not current_obj_str or current_obj_str[-1] != '\\'):
                in_string = not in_string
            
            if not in_string:
                if char == '{':
                    if level == 0:
                        current_obj_str = "{"
                    else:
                        current_obj_str += char
                    level += 1
                elif char == '}':
                    level -= 1
                    current_obj_str += char
                    if level == 0:
                        try:
                            objects.append(json.loads(current_obj_str))
                        except:
                            pass
                elif level > 0:
                    current_obj_str += char
        
        print(f"✅ {len(objects)} kelime elle ayrıştırıldı.")
        return objects

def main():
    words = extract_data_from_dart(input_path)
    
    if not words:
        print("❌ Kelimeler çıkarılamadı.")
        return

    print("✍️ CSV dosyası hazırlanıyor...")
    
    with open(output_path, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['kelime', 'harekeliKelime', 'mevcut_anlam', 'yeni_anlamlar_1_15']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        
        for word_obj in words:
            writer.writerow({
                'kelime': word_obj.get('kelime', ''),
                'harekeliKelime': word_obj.get('harekeliKelime', ''),
                'mevcut_anlam': word_obj.get('anlam', ''),
                'yeni_anlamlar_1_15': '' # Boş bırakıyoruz
            })

    print(f"🎉 İşlem tamamlandı: {output_path}")

if __name__ == '__main__':
    main()
