"""
Merge script v2: Line-by-line replacement of 'anlam' field in backup.

Strategy:
1. Read backup dart file line by line
2. For lines containing word entries (with "kelime":, "anlam":, etc.), 
   find the harekeliKelime and replace the anlam value with simplified one
3. Keep everything else (koku, fiilCekimler, ornekCumleler, etc.) intact
"""

import json
import re
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(BASE_DIR)

# 1. Load simplified meanings
kisa_path = os.path.join(PROJECT_DIR, 'SOZLUK_KISA_ANLAMLI.json')
with open(kisa_path, 'r', encoding='utf-8') as f:
    kisa_data = json.load(f)

print(f"✅ Loaded {len(kisa_data)} simplified meanings")

# 2. Read backup file
backup_path = os.path.join(PROJECT_DIR, 'lib', 'data', 'embedded_words_data.dart.backup')
with open(backup_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f"✅ Read {len(lines)} lines from backup")

# 3. Process each line
output_lines = []
updated_count = 0
total_entries = 0

for line in lines:
    stripped = line.strip()
    
    # Check if this is a word entry line (starts with { and contains "kelime":)
    if stripped.startswith('{') and '"kelime"' in stripped and '"anlam"' in stripped:
        total_entries += 1
        
        # Extract harekeliKelime value
        harekeli_match = re.search(r'"harekeliKelime"\s*:\s*"([^"]*)"', stripped)
        if harekeli_match:
            harekeli = harekeli_match.group(1)
            
            if harekeli in kisa_data:
                new_anlam = kisa_data[harekeli]
                if new_anlam:
                    # Escape the new anlam for JSON
                    escaped_anlam = new_anlam.replace('\\', '\\\\').replace('"', '\\"')
                    
                    # Replace the anlam field value
                    # Pattern: "anlam":"..." (value ends at next unescaped ")
                    old_line = stripped
                    new_line = re.sub(
                        r'"anlam"\s*:\s*"[^"]*(?:\\.[^"]*)*"',
                        f'"anlam":"{escaped_anlam}"',
                        stripped,
                        count=1
                    )
                    if new_line != old_line:
                        updated_count += 1
                        # Preserve original indentation
                        indent = line[:len(line) - len(line.lstrip())]
                        output_lines.append(indent + new_line + '\n')
                        continue
    
    output_lines.append(line)

print(f"✅ Processed {total_entries} word entries, updated {updated_count} meanings")

# 4. Update header comment
if output_lines and output_lines[0].startswith('//'):
    output_lines[0] = '// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY\r\n'
    if len(output_lines) > 1 and output_lines[1].startswith('//'):
        output_lines[1] = '// Restored from backup + SOZLUK_KISA_ANLAMLI.json (simplified meanings)\r\n'

# 5. Write output
output_path = os.path.join(PROJECT_DIR, 'lib', 'data', 'embedded_words_data.dart')
with open(output_path, 'w', encoding='utf-8') as f:
    f.writelines(output_lines)

print(f"✅ Written to {output_path}")
print(f"📊 Total entries: {total_entries}, Updated: {updated_count}")
