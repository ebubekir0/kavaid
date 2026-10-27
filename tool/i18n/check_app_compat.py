"""Pilot çıktılarının JSON yapısını ve uygulamanın bugünkü okuma kurallarına
uygunluğunu denetler.

Kullanım (kavaid klasöründen):
    python tool/i18n/check_app_compat.py --size 200

Uygulamanın kuralları (lib/models/word_model.dart, lib/services/search_ranking.dart):
  - anlam = "a, b, c||HARFI_CER:harf=x, y"; arama anlamları [,،;] ile böler
  - sadeAnlam parantez içini siler
  - harfiCerler her bölümü '=' ile ikiye böler (tam 2 parça olmalı)
  - ornekCumleler çevirileri Arapça örneklerle sırayla eşleşir
"""
import argparse
import collections
import glob
import gzip
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pilot_prompts import word_payload  # noqa: E402

HARAKAT = re.compile(r'[ً-ْٰـ]')
SPLIT = re.compile(r'[,،;]')
PAREN = re.compile(r'\([^()]*\)')


def norm_harf(h):
    """'بِـ', 'بـ', 'ب' -> 'ب'"""
    return HARAKAT.sub('', h).replace('ـ', '').strip()


def to_app_anlam(result):
    """Çeviri dili çıktısını uygulamanın bugünkü anlam metnine çevirir."""
    text = ', '.join(s.strip() for s in result['senses'])
    for p in result['preps']:
        text += f"||HARFI_CER:{p['h'].strip()}={', '.join(m.strip() for m in p['m'])}"
    return text


def parse_like_app(anlam):
    """word_model.dart'taki sadeAnlam ve harfiCerler mantığının Python karşılığı."""
    parts = anlam.split('||')
    sade = re.sub(r'\s{2,}', ' ', PAREN.sub('', parts[0])).strip()
    preps = []
    for part in parts[1:]:
        part = part.strip()
        if part.startswith('HARFI_CER:'):
            sub = part[len('HARFI_CER:'):].split('=')
            preps.append(tuple(x.strip() for x in sub) if len(sub) == 2 else None)
    return sade, preps


def check_translation(rows, recs):
    c = collections.Counter()
    sample_issues = collections.defaultdict(list)
    for r in rows:
        c['toplam'] += 1
        if 'result' not in r:
            c['hata/ayrıştırılamadı'] += 1
            continue
        x = r['result']
        pay = word_payload(recs[r['pid']])
        if not isinstance(x.get('senses'), list) or not isinstance(x.get('preps'), list) \
                or not isinstance(x.get('examples'), list):
            c['şema dışı'] += 1
            continue
        c['geçerli JSON + şema'] += 1
        if not x['senses']:
            c['boş anlam listesi'] += 1
        for s in x['senses']:
            if SPLIT.search(s):
                c['anlam içinde virgül (aramada bölünür)'] += 1
                sample_issues['virgül'].append(s)
            if PAREN.search(s):
                c['parantezli anlam (ekranda parantez silinir)'] += 1
                sample_issues['parantez'].append(s)
        all_text = ' '.join(x['senses'] + [m for p in x['preps'] for m in p['m']] + x['examples'])
        if '||' in all_text or 'HARFI_CER' in all_text:
            c['ayraç çakışması (||)'] += 1
        if any('=' in m for p in x['preps'] for m in p['m']) or any('=' in s for s in x['senses']):
            c["'=' içeren metin (harf-i cer bozulur)"] += 1
        if len(x['examples']) != len(pay['examples']):
            c['örnek sayısı uyuşmuyor'] += 1
        editor = {norm_harf(h) for h in pay['editor_prepositions']}
        given = {norm_harf(p['h']) for p in x['preps'] if not p.get('added')}
        added = [p for p in x['preps'] if p.get('added')]
        c['editör harf-i cer'] += len(editor)
        c['editör harf-i cer karşılandı'] += len(editor & given)
        c['eklenen harf-i cer'] += len(added)
        if given - editor:
            c["'added' işaretsiz fazla harf"] += len(given - editor)
        if any('...' in m for p in x['preps'] for m in p['m']):
            c["'...' (üç nokta, '…' yerine)"] += 1
        sade, preps = parse_like_app(to_app_anlam(x))
        if None in preps or len(preps) != len(x['preps']) or not sade:
            c['uygulama biçimine dönüşmüyor'] += 1
    return c, sample_issues


def check_arabic(rows):
    c = collections.Counter()
    for r in rows:
        c['toplam'] += 1
        if 'result' not in r:
            c['hata/ayrıştırılamadı'] += 1
            continue
        x = r['result']
        ok = isinstance(x.get('sh'), str) and isinstance(x.get('syn'), list) and \
            isinstance(x.get('ant'), list) and isinstance(x.get('note'), str) and isinstance(x.get('preps'), list)
        if not ok:
            c['şema dışı'] += 1
            continue
        c['geçerli JSON + şema'] += 1
        if not x['sh'].strip():
            c['boş şerh'] += 1
        if not x['syn']:
            c['eş anlamlı yok'] += 1
        if not x['ant']:
            c['zıt anlamlı yok (normal olabilir)'] += 1
        if re.search(r'[A-Za-z]', json.dumps([x['sh'], x['note'], x['syn'], x['ant']], ensure_ascii=False)):
            c['Latin harf'] += 1
        if any(SPLIT.search(s) for s in x['syn'] + x['ant']):
            c['eş/zıt anlam içinde virgül'] += 1
    return c


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--size', type=int, default=200)
    args = ap.parse_args()
    out_dir = 'content/pilot' if args.size == 50 else f'content/pilot/n{args.size}'
    with open(f'content/pilot/sample_{args.size}.jsonl', encoding='utf-8') as f:
        recs = {row['pid']: row['rec'] for row in map(json.loads, f)}

    for path in sorted(glob.glob(os.path.join(out_dir, 'out_*.jsonl'))):
        with open(path, encoding='utf-8') as f:
            rows = [json.loads(line) for line in f if line.strip()]
        if not rows:
            continue
        lang = rows[0]['lang']
        print(f'\n=== {os.path.basename(path)}')
        if lang == 'ar':
            c = check_arabic(rows)
            issues = {}
        else:
            c, issues = check_translation(rows, recs)
        for k, v in c.items():
            print(f'  {k}: {v}')
        for k, vals in issues.items():
            print(f'  örnek ({k}): {vals[:4]}')
        packed = json.dumps([r.get('result') for r in rows], ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        per_word = len(gzip.compress(packed)) / len(rows)
        print(f'  paket boyutu tahmini (54.971 kelime, gzip): ~{per_word * 54971 / 1e6:.1f} MB')


if __name__ == '__main__':
    main()
