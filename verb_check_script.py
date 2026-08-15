import json
filename = 'emsile_sonuclar_parsed2.json'
with open(filename, 'r', encoding='utf-8') as f:
    data = json.load(f)

matches = []
for v in data:
    d = v.get('data', {})
    if not d.get('gecerli_mi'): continue
    
    emsile = d.get('emsile_24', [])
    mazi = ''
    muzari = ''
    for e in emsile:
        if e.get('sira') == 1: mazi = e.get('arapca', '')
        if e.get('sira') == 2: muzari = e.get('arapca', '')
    
    # Check for فَعَلَ يَفْعُلُ (exactly or loosely)
    if (mazi == 'فَعَلَ' and muzari == 'يَفْعُلُ') or (mazi == 'فعل' and muzari == 'يفعل'):
        matches.append({'id': v.get('custom_id'), 'mazi': mazi, 'muzari': muzari, 'anlamlar': d.get('anlamlar')})

with open('verb_check.json', 'w', encoding='utf-8') as f:
    json.dump(matches, f, ensure_ascii=False, indent=2)
