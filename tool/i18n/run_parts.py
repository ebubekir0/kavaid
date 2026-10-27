"""Batch parçalarını sırayla gönderir: her parça bitip indirilmeden sonrakini göndermez
(kuyruktaki token sınırı bütün işler için ortak). Yarıda kalırsa yeniden çalıştırmak
güvenlidir: gönderilmiş parçanın iş bilgisini okuyup kaldığı yerden devam eder.

Kullanım (kavaid klasöründen; google-genai gerekir):
    $env:GEMINI_API_KEY = "..."
    ..\\..\\batch\\.venv\\Scripts\\python tool/i18n/run_parts.py --lang en --parts 1 2 3
"""
import argparse
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from google import genai  # noqa: E402
from google.genai import types  # noqa: E402
from submit_batch import DONE, paths, state_of  # noqa: E402

POLL_SECONDS = 60


def log(msg):
    print(time.strftime('%H:%M:%S'), msg, flush=True)


def run_part(client, model, lang, version, part):
    src, job_path, out_path = paths(lang, version, part)
    if os.path.exists(out_path):
        log(f'parça {part}: sonuç zaten indirilmiş ({out_path})')
        return True
    if os.path.exists(job_path):
        with open(job_path, encoding='utf-8') as f:
            job_name = json.load(f)['job_name']
        log(f'parça {part}: önceden gönderilmiş iş izleniyor ({job_name})')
    else:
        uploaded = client.files.upload(
            file=src, config=types.UploadFileConfig(display_name=os.path.basename(src), mime_type='jsonl'))
        job = client.batches.create(model=model, src=uploaded.name,
                                    config={'display_name': f'kavaid-{lang}-{version}-part{part}'})
        job_name = job.name
        with open(job_path, 'w', encoding='utf-8') as f:
            json.dump({'job_name': job_name, 'uploaded_file': uploaded.name, 'model': model,
                       'submitted': time.strftime('%Y-%m-%d %H:%M:%S')}, f)
        log(f'parça {part}: gönderildi ({job_name})')

    started, last = time.time(), None
    while True:
        try:
            job = client.batches.get(name=job_name)
        except Exception as e:  # uyku/ağ kopması: iş Google'da sürüyor, izlemeye devam
            log(f'parça {part}: durum alınamadı ({type(e).__name__}), yeniden denenecek')
            time.sleep(POLL_SECONDS)
            continue
        state = state_of(job)
        if state != last:
            log(f'parça {part}: {state}')
            last = state
        if state in DONE:
            break
        time.sleep(POLL_SECONDS)
    if state != 'JOB_STATE_SUCCEEDED':
        log(f'parça {part}: başarısız — {getattr(job, "error", None)}')
        return False
    for attempt in range(10):
        try:
            content = client.files.download(file=job.dest.file_name)
            break
        except Exception as e:
            log(f'parça {part}: indirilemedi ({type(e).__name__}), yeniden denenecek')
            time.sleep(POLL_SECONDS)
    else:
        return False
    with open(out_path, 'wb') as f:
        f.write(content)
    log(f'parça {part}: indirildi ({out_path}, {len(content) / 1e6:.1f} MB, {(time.time() - started) / 60:.0f} dk)')
    return True


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--lang', required=True)
    ap.add_argument('--version', default='v1')
    ap.add_argument('--parts', type=int, nargs='+', required=True)
    args = ap.parse_args()
    key = os.environ.get('GEMINI_API_KEY') or sys.exit('GEMINI_API_KEY ortam değişkeni yok.')
    client = genai.Client(api_key=key)
    with open(f'content/batch/{args.lang}_{args.version}_manifest.json', encoding='utf-8') as f:
        model = json.load(f)['model']
    for part in args.parts:
        if not run_part(client, model, args.lang, args.version, part):
            sys.exit(1)
    log('bütün parçalar tamam')


if __name__ == '__main__':
    main()
