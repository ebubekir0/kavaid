"""Çeviri dillerini (ör. id, ms, ur) sırayla ve gözetimsiz üretir: batch → doğrulama → tek kelimelik yeniden üretim
→ birleştirme. Her dil İngilizce son sözlüğü ipucu alır (gemini-3.1-flash-lite, 10 kelime/istek). Diller sırayla
gider: flash-lite'ın batch kuyruğu (Tier 1, 10 M token) bütün işler için ortak. Yarıda kalırsa aynı komutla
yeniden başlatmak güvenlidir (hazır manifest ve sonuçlar yeniden üretilmez).

Kullanım (kavaid klasöründen; GEMINI_API_KEY ortamda):
    ..\\..\\batch\\.venv\\Scripts\\python tool/i18n/lang_pipeline.py --langs id ms ur
Özet: content/lang/<dil>/pipeline_report.txt
"""
import argparse
import os
import re
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ar_pipeline import batch, log, read_jsonl, results_of, run  # noqa: E402

HINTS = 'content/lang/en/dict_final.jsonl'


def produce(lang):
    started = time.strftime('%Y-%m-%d %H:%M')
    report = []
    if not os.path.exists(f'content/batch/{lang}_v1_manifest.json'):
        run('make_batch.py', '--lang', lang, '--version', 'v1', '--hint-from', HINTS, capture=True)
    batch(lang, 'v1')
    report.append(('Ana üretim · gemini-3.1-flash-lite · 10 kelimelik istek',
                   run('validate.py', '--lang', lang, '--version', 'v1', '--results', *results_of(lang, 'v1'), capture=True)))
    requeue = f'content/lang/{lang}/requeue_v1.jsonl'
    if read_jsonl(requeue):
        if not os.path.exists(f'content/batch/{lang}_v1r_manifest.json'):
            run('make_batch.py', '--lang', lang, '--version', 'v1r', '--pack', '1', '--hint-from', HINTS,
                '--wids', requeue, capture=True)
        if batch(lang, 'v1r'):
            report.append(('Yeniden üretim · tek kelimelik istek',
                           run('validate.py', '--lang', lang, '--version', 'v1r', '--results',
                               *results_of(lang, 'v1r'), capture=True)))
    report.append(('Birleştirme', run('merge_dict.py', '--lang', lang, '--base', 'v1', '--fix', 'v1r', capture=True)))
    total = sum(float(m) for _, out in report for m in re.findall(r'maliyeti ≈ \$([0-9.]+)', out))
    with open(f'content/lang/{lang}/pipeline_report.txt', 'w', encoding='utf-8') as f:
        f.write(f'{lang} üretimi · başladı {started} · bitti {time.strftime("%Y-%m-%d %H:%M")}\n\n')
        for title, out in report:
            f.write(f'## {title}\n{out.strip()}\n\n')
        f.write(f'Toplam batch maliyeti (usageMetadata, batch fiyatı) ≈ ${total:.2f}\n')
    log(f'{lang} bitti · ≈ ${total:.2f}')


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--langs', nargs='+', required=True)
    args = ap.parse_args()
    os.environ.get('GEMINI_API_KEY') or sys.exit('GEMINI_API_KEY ortam değişkeni yok.')
    for lang in args.langs:
        os.makedirs(f'content/lang/{lang}', exist_ok=True)
        produce(lang)
    log('bütün diller tamam')


if __name__ == '__main__':
    main()
