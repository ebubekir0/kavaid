"""Arapça–Arapça üretiminin tamamını gözetimsiz çalıştırır: ana batch → doğrulama → hakem turu →
yeniden üretim → doğrulama → birleştirme. Batch adımları run_parts.py ile kaldığı yerden sürer,
hazır olan dosyalar yeniden üretilmez; yarıda kalırsa aynı komutla yeniden başlatmak güvenlidir.

Kullanım (kavaid klasöründen; GEMINI_API_KEY ortamda):
    ..\\..\\batch\\.venv\\Scripts\\python tool/i18n/ar_pipeline.py
Özet: content/lang/ar/pipeline_report.txt
"""
import json
import os
import re
import subprocess
import sys
import time

TOOLS = os.path.dirname(os.path.abspath(__file__))
AR = 'content/lang/ar'
REPORT = f'{AR}/pipeline_report.txt'
HINTS = 'content/lang/en/dict_final.jsonl'
# gemini-3.8-flash için Tier 1 batch kuyruğu 3 M token; ana üretimdeki pay korunur
REQUEUE_MAX_PART_TOKENS = 2_700_000


def log(msg):
    print(time.strftime('%H:%M:%S'), msg, flush=True)


def run(script, *args, capture=False, tries=1):
    cmd = [sys.executable, os.path.join(TOOLS, script), *args]
    for attempt in range(1, tries + 1):
        log(f'» {script} {" ".join(args[:6])}')
        proc = subprocess.run(cmd, text=True, encoding='utf-8', capture_output=capture)
        if capture:
            sys.stdout.write(proc.stdout + proc.stderr)
            sys.stdout.flush()
        if proc.returncode == 0:
            return proc.stdout if capture else ''
        if attempt < tries:
            log(f'{script} başarısız (deneme {attempt}/{tries}), 5 dk sonra yeniden')
            time.sleep(300)
    sys.exit(f'adım başarısız: {script} {args}')


def parts_of(lang, version):
    with open(f'content/batch/{lang}_{version}_manifest.json', encoding='utf-8') as f:
        return [str(i + 1) for i in range(len(json.load(f)['parts']))]


def results_of(lang, version):
    return [f'content/batch/{lang}_{version}_results_part{p}.jsonl' for p in parts_of(lang, version)]


def batch(lang, version):
    parts = parts_of(lang, version)
    if parts:
        run('run_parts.py', '--lang', lang, '--version', version, '--parts', *parts, tries=3)
    return parts


def read_jsonl(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding='utf-8') as f:
        return [json.loads(line) for line in f if line.strip()]


def combine_requeues():
    reasons = {}
    for path in (f'{AR}/requeue_v1.jsonl', f'{AR}/requeue_judge_v1.jsonl'):
        for row in read_jsonl(path):
            reasons.setdefault(row['wid'], []).extend(row['reasons'])
    with open(f'{AR}/requeue_all_v1.jsonl', 'w', encoding='utf-8') as f:
        for w in sorted(reasons):
            f.write(json.dumps({'wid': w, 'reasons': reasons[w]}, ensure_ascii=False) + '\n')
    return len(reasons)


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    os.environ.get('GEMINI_API_KEY') or sys.exit('GEMINI_API_KEY ortam değişkeni yok.')
    os.makedirs(AR, exist_ok=True)
    started = time.strftime('%Y-%m-%d %H:%M')
    report = []

    batch('ar', 'v1')
    report.append(('Ana üretim · gemini-3.8-flash · 10 kelimelik istek',
                   run('validate_ar.py', '--version', 'v1', '--results', *results_of('ar', 'v1'), capture=True)))

    if not os.path.exists('content/batch/arjudge_v1_manifest.json'):
        run('judge_ar.py', 'make', capture=True)
    batch('arjudge', 'v1')
    report.append(('Hakem turu · gemini-3.1-flash-lite',
                   run('judge_ar.py', 'read', '--results', *results_of('arjudge', 'v1'), capture=True)))

    if not os.path.exists('content/batch/ar_v1r_manifest.json'):
        log(f'yeniden üretilecek: {combine_requeues()} kelime')
        run('make_batch.py', '--lang', 'ar', '--version', 'v1r', '--model', 'gemini-3.8-flash', '--pack', '1',
            '--prompt', 'v5', '--hint-from', HINTS, '--wids', f'{AR}/requeue_all_v1.jsonl',
            '--max-part-tokens', str(REQUEUE_MAX_PART_TOKENS), capture=True)
    if batch('ar', 'v1r'):
        report.append(('Yeniden üretim · gemini-3.8-flash · tek kelimelik istek',
                       run('validate_ar.py', '--version', 'v1r', '--results', *results_of('ar', 'v1r'), capture=True)))
    report.append(('Birleştirme', run('merge_dict.py', '--lang', 'ar', '--base', 'v1', '--fix', 'v1r',
                                      '--also', f'{AR}/requeue_judge_v1.jsonl', capture=True)))

    total = sum(float(m) for _, out in report for m in re.findall(r'maliyeti ≈ \$([0-9.]+)', out))
    with open(REPORT, 'w', encoding='utf-8') as f:
        f.write(f'Arapça–Arapça üretim · başladı {started} · bitti {time.strftime("%Y-%m-%d %H:%M")}\n\n')
        for title, out in report:
            f.write(f'## {title}\n{out.strip()}\n\n')
        f.write(f'Toplam batch maliyeti (usageMetadata, batch fiyatı) ≈ ${total:.2f}\n')
    log(f'bitti · toplam ≈ ${total:.2f} · {REPORT}')


if __name__ == '__main__':
    main()
