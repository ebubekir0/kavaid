"""make_batch.py'nin ürettiği parçaları Gemini Batch API'ye gönderir, durumu izler ve
sonuçları indirir. google-genai SDK'sı gerekir (Desktop\\batch\\.venv içinde 1.65 kurulu).

Kullanım (kavaid klasöründen):
    $env:GEMINI_API_KEY = "..."
    ..\\..\\batch\\.venv\\Scripts\\python tool/i18n/submit_batch.py submit   --lang en --part 1
    ..\\..\\batch\\.venv\\Scripts\\python tool/i18n/submit_batch.py status   --lang en --part 1
    ..\\..\\batch\\.venv\\Scripts\\python tool/i18n/submit_batch.py download --lang en --part 1

Parçaları sırayla gönderin: kuyruktaki token sınırı (Tier 1'de gemini-3.1-flash-lite için
10 M) bütün işler için ortaktır. İş bilgisi content/batch/<dil>_<sürüm>_part<N>_job.json'a,
sonuç content/batch/<dil>_<sürüm>_results_part<N>.jsonl'a yazılır; ardından:
    python tool/i18n/validate.py --lang en --results content/batch/en_v1_results_part*.jsonl
"""
import argparse
import json
import os
import sys

from google import genai
from google.genai import types

DONE = {'JOB_STATE_SUCCEEDED', 'JOB_STATE_FAILED', 'JOB_STATE_CANCELLED', 'JOB_STATE_EXPIRED'}


def paths(lang, version, part):
    base = f'content/batch/{lang}_{version}'
    return f'{base}_part{part}.jsonl', f'{base}_part{part}_job.json', f'{base}_results_part{part}.jsonl'


def state_of(job):
    return job.state.name if hasattr(job.state, 'name') else str(job.state)


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('action', choices=['submit', 'status', 'download'])
    ap.add_argument('--lang', required=True)
    ap.add_argument('--version', default='v1')
    ap.add_argument('--part', type=int, required=True)
    args = ap.parse_args()
    key = os.environ.get('GEMINI_API_KEY') or sys.exit('GEMINI_API_KEY ortam değişkeni yok.')
    client = genai.Client(api_key=key)
    src, job_path, out_path = paths(args.lang, args.version, args.part)
    with open(f'content/batch/{args.lang}_{args.version}_manifest.json', encoding='utf-8') as f:
        model = json.load(f)['model']

    if args.action == 'submit':
        if os.path.exists(job_path):
            sys.exit(f'Bu parça zaten gönderilmiş: {job_path}')
        uploaded = client.files.upload(
            file=src, config=types.UploadFileConfig(display_name=os.path.basename(src), mime_type='jsonl'))
        job = client.batches.create(model=model, src=uploaded.name,
                                    config={'display_name': f'kavaid-{args.lang}-{args.version}-part{args.part}'})
        with open(job_path, 'w', encoding='utf-8') as f:
            json.dump({'job_name': job.name, 'uploaded_file': uploaded.name, 'model': model}, f)
        print(f'gönderildi: {job.name} ({state_of(job)})')
        return

    with open(job_path, encoding='utf-8') as f:
        job_name = json.load(f)['job_name']
    job = client.batches.get(name=job_name)
    state = state_of(job)
    stats = getattr(job, 'batch_stats', None)
    print(f'{job_name}: {state}' + (f' · {stats}' if stats else ''))
    if args.action == 'download':
        if state != 'JOB_STATE_SUCCEEDED':
            sys.exit('İş henüz tamamlanmadı.')
        content = client.files.download(file=job.dest.file_name)
        with open(out_path, 'wb') as f:
            f.write(content)
        print(f'indirildi: {out_path}')


if __name__ == '__main__':
    main()
