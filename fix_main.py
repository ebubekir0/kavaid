with open(r'c:\Users\kul\Desktop\kavaid1111\kavaid\lib\main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Line 352 and 353 are empty (indices 351, 352), line 354 starts main body (index 353)
# We need to insert the main() header between line 353 and 354

insert_idx = 353  # 0-indexed, this is where the body starts ("    // 🚀 ÖNCELİK 1...")

# Insert the main function header before this line
header_lines = [
    'Future<void> main() async {\n',
    '  await runZonedGuarded<Future<void>>(() async {\n',
]

lines = lines[:insert_idx] + header_lines + lines[insert_idx:]

with open(r'c:\Users\kul\Desktop\kavaid1111\kavaid\lib\main.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print(f"Done! Total lines now: {len(lines)}")
# Verify
for i, line in enumerate(lines[349:362], start=350):
    print(f"{i}: {repr(line[:80])}")
