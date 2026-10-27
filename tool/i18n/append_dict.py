"""Yeni eklenen kelimelerin sonuçlarını bir dilin son sözlüğüne (dict_final.jsonl) ekler.

Kullanım (kavaid klasöründen):
    python tool/i18n/append_dict.py --lang en --versions v1n v1nr

Sürümler sırayla okunur, sonraki sürüm öncekinin aynı wid'li sonucunu ezer (yeniden üretim düzeltmesi).
dict_final'de zaten olan wid'lere dokunulmaz; dosya değişmeden önce content/backup/ altına yedeklenir.
"""
import argparse
import datetime
import json
import os
import shutil
import sys


def read_jsonl(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding='utf-8') as f:
        return [json.loads(line) for line in f if line.strip()]


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--lang', required=True)
    ap.add_argument('--versions', nargs='+', required=True)
    args = ap.parse_args()
    d = f'content/lang/{args.lang}'
    final_path = f'{d}/dict_final.jsonl'
    final = read_jsonl(final_path)
    have = {r['wid'] for r in final}
    new = {}
    for v in args.versions:
        for r in read_jsonl(f'{d}/dict_{v}.jsonl'):
            if r['wid'] not in have:
                new[r['wid']] = r['result']
    backup = f'content/backup/{args.lang}_dict_final_{datetime.date.today().isoformat()}.jsonl'
    os.makedirs(os.path.dirname(backup), exist_ok=True)
    if not os.path.exists(backup):
        shutil.copyfile(final_path, backup)
    with open(final_path, 'w', encoding='utf-8') as f:
        for r in sorted(final + [{'wid': w, 'result': res} for w, res in new.items()], key=lambda r: r['wid']):
            f.write(json.dumps(r, ensure_ascii=False) + '\n')
    print(f'{final_path}: {len(final)} + {len(new)} = {len(final) + len(new)} (yedek: {backup})')


if __name__ == '__main__':
    main()
