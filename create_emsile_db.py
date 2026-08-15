import json, re, os, sqlite3

def remove_diacritics(text):
    if not text: return ""
    return re.sub(r'[\u064B-\u065F\u0670\u0653-\u0655]', '', text)

def fix_cekim_list(cekim_list, type_hint=''):
    if not cekim_list:
        return []
        
    cleaned_list = []
    
    # Check if this is a single string containing multiple arabic words (the old bug)
    if len(cekim_list) == 1:
        sahis = cekim_list[0].get('sahis', '')
        arabic_words = re.findall(r'[\u0600-\u06FF\u064B-\u065F\u0670\u0653-\u0655]+', sahis)
        clean_parts = [p.strip() for p in arabic_words if len(p.strip()) >= 1]
        target_count = 15 if type_hint in ['mazi', 'muzari'] else 6
        if len(clean_parts) >= target_count:
            return [{"sahis": p, "arapca": p} for p in clean_parts[:target_count]]
    
    # Regular multiple-item list
    for item in cekim_list:
        arapca = item.get('arapca', '')
        sahis = item.get('sahis', '')
        
        # We assume the user wants ONLY arabic in both fields now. Look at both fields.
        text_to_search = "%s %s" % (arapca, sahis)
        arabic_words = re.findall(r'[\u0600-\u06FF\u064B-\u065F\u0670\u0653-\u0655]+', text_to_search)
        if arabic_words:
            # Reconstruct the arabic phrase inside it
            clean_word = " ".join([p.strip() for p in arabic_words if len(p.strip()) >= 1])
            if clean_word:
                cleaned_list.append({"sahis": clean_word, "arapca": clean_word})
                continue
                
        # Fallback if no arabic found
        cleaned_list.append({"sahis": sahis, "arapca": arapca})
        
    target_count = 15 if type_hint in ['mazi', 'muzari'] else 6
    if len(cleaned_list) < target_count:
        return cleaned_list
    return cleaned_list[:target_count]

print("Starting DB creation with emir from parsed1...")

# Load both files
with open('emsile_tamamlanmis_veri.json', 'r', encoding='utf-8') as f:
    data2 = json.load(f)

with open('emsile_sonuclar_parsed.json', 'r', encoding='utf-8') as f:
    data1 = json.load(f)

# Build lookup for emir from parsed1 by mazi+muzari
emir_lookup = {}
for v in data1:
    cid = v.get('custom_id', '')
    d = v.get('data', {})
    cekimler = d.get('cekimler', {})
    emir_list = cekimler.get('emir', [])
    mazi_list = cekimler.get('mazi', [])
    muzari_list = cekimler.get('muzari', [])
    
    emsile_24 = d.get('emsile_24', [])
    mazi_v1 = ''
    muzari_v1 = ''
    emir_24_text = ''
    for e in emsile_24:
        sira = e.get('sira')
        if sira == 1: mazi_v1 = remove_diacritics(e.get('arapca', ''))
        if sira == 2: muzari_v1 = remove_diacritics(e.get('arapca', ''))
        if e.get('isim') == 'Emr-i Hazır':
            emir_24_text = e.get('arapca', '')
    
    if emir_list or emir_24_text or mazi_list or muzari_list:
        key = f"{mazi_v1}|{muzari_v1}"
        emir_lookup[key] = {
            'list': emir_list,
            'text': emir_24_text,
            'mazi': mazi_list,
            'muzari': muzari_list
        }

print(f"  Loaded {len(emir_lookup)} emir info from parsed1")

# Merge: for each entry in data2, if emir is empty, try to get from parsed1
merged_count = 0
for v in data2:
    idx = v.get('index', '')
    d = v.get('emsile', {})
    if not d: continue
    
    cekimler = d.get('cekimler', {})
    if not cekimler:
        cekimler = {}
        d['cekimler'] = cekimler
    
    # Get identity for lookup
    emsile_24 = d.get('emsile_24', [])
    mazi_v2 = ''
    muzari_v2 = ''
    for e in emsile_24:
        sira = e.get('sira')
        if sira == 1: mazi_v2 = remove_diacritics(e.get('arapca', ''))
        if sira == 2: muzari_v2 = remove_diacritics(e.get('arapca', ''))
    
    lookup_key = f"{mazi_v2}|{muzari_v2}"
    
    if lookup_key in emir_lookup:
        # Her zaman emir çekimini parsed1'den (eski veriden) al
        if emir_lookup[lookup_key]['list']:
            cekimler['emir'] = emir_lookup[lookup_key]['list']
            merged_count += 1
            
        if not cekimler.get('mazi') and emir_lookup[lookup_key].get('mazi'):
            cekimler['mazi'] = emir_lookup[lookup_key]['mazi']
            
        if not cekimler.get('muzari') and emir_lookup[lookup_key].get('muzari'):
            cekimler['muzari'] = emir_lookup[lookup_key]['muzari']
        
        # Also update emsile_24 sira 13 (Emr-i Hâzır) if empty
        for e in emsile_24:
            if e.get('sira') == 13:
                if not e.get('arapca', '') and emir_lookup[lookup_key]['text']:
                    e['arapca'] = emir_lookup[lookup_key]['text']
                    break

print(f"  Merged/Updated {merged_count} emir entries into new data structure")

# Now create DB
os.makedirs('assets/data', exist_ok=True)
db_path = 'assets/data/emsile.db'
if os.path.exists(db_path):
    os.remove(db_path)

conn = sqlite3.connect(db_path)
c = conn.cursor()

c.execute('''
    CREATE TABLE IF NOT EXISTS emsile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        custom_id TEXT,
        mazi TEXT,
        muzari TEXT,
        anlamlar TEXT,
        emsile_24 TEXT,
        cekim_mazi TEXT,
        cekim_muzari TEXT,
        cekim_emir TEXT,
        search_text TEXT,
        search_text_arabic TEXT
    )
''')

c.execute('CREATE INDEX IF NOT EXISTS idx_search_text ON emsile(search_text)')
c.execute('CREATE INDEX IF NOT EXISTS idx_search_text_arabic ON emsile(search_text_arabic)')
c.execute('CREATE INDEX IF NOT EXISTS idx_mazi ON emsile(mazi)')

seen_verbs = set()
skipped_dupes = 0
inserted = 0

for row in data2:
    custom_id = str(row.get('index', ''))
    d = row.get('emsile', {})
    
    if not d.get('gecerli_mi', True):
        continue
    
    emsile_24_list = d.get('emsile_24', [])
    if not emsile_24_list:
        continue
    
    mazi = ''
    muzari = ''
    for e in emsile_24_list:
        sira = e.get('sira')
        if sira == 1:
            mazi = e.get('arapca', '')
        if sira == 2:
            muzari = e.get('arapca', '')
    
    dedup_key = remove_diacritics(mazi) + '|' + remove_diacritics(muzari)
    if dedup_key in seen_verbs and dedup_key != '|':
        skipped_dupes += 1
        continue
    seen_verbs.add(dedup_key)
    
    anlamlar_list = d.get('anlamlar', [])
    anlamlar = json.dumps(anlamlar_list, ensure_ascii=False)
    emsile_24 = json.dumps(emsile_24_list, ensure_ascii=False)
    
    cekimler = d.get('cekimler', {})
    
    list_mazi = fix_cekim_list(cekimler.get('mazi', []), 'mazi')
    list_muzari = fix_cekim_list(cekimler.get('muzari', []), 'muzari')
    list_emir = fix_cekim_list(cekimler.get('emir', []), 'emir')
    
    cekim_mazi = json.dumps(list_mazi, ensure_ascii=False)
    cekim_muzari = json.dumps(list_muzari, ensure_ascii=False)
    cekim_emir = json.dumps(list_emir, ensure_ascii=False)
    
    search_text = " ".join(anlamlar_list).lower()
    
    tum_sigalar_arapca = []
    for e in emsile_24_list:
        arapca = e.get('arapca', '')
        if arapca:
            tum_sigalar_arapca.append(remove_diacritics(arapca))
    search_text_arabic = " ".join(tum_sigalar_arapca)
    
    c.execute('''
        INSERT INTO emsile (custom_id, mazi, muzari, anlamlar, emsile_24, cekim_mazi, cekim_muzari, cekim_emir, search_text, search_text_arabic)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (custom_id, mazi, muzari, anlamlar, emsile_24, cekim_mazi, cekim_muzari, cekim_emir, search_text, search_text_arabic))
    inserted += 1

conn.commit()
conn.close()

db_size_mb = os.path.getsize(db_path) / (1024 * 1024)
print(f"\nemsile.db created successfully:")
print(f"  Inserted: {inserted}")
print(f"  Skipped dupes: {skipped_dupes}")
print(f"  Size: {db_size_mb:.2f} MB")
