"""Yerelleştirme pilotu 2. tur: tek istekte N kelime, önce İngilizce, diğer dillere
İngilizce ipucu, genişletilmiş otomatik kontroller.

Kullanım (kavaid klasöründen):
    $env:GEMINI_API_KEY = "..."
    python tool/i18n/pilot_round2.py --size 200 --pack 10
    python tool/i18n/pilot_round2.py --report-only

Çıktılar content/pilot/n<boyut>_r2/ altına 1. turla aynı satır biçiminde yazılır
(out_<dil>_<model>_<düşünme>.jsonl); rapor ve check_app_compat.py aynen çalışır.
İstek başına token kullanımı kelimelere eşit bölünerek her satıra yazılır.
"""
import argparse
import collections
import concurrent.futures
import gzip
import json
import lzma
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pilot_run as pr  # noqa: E402
from pilot_prompts_v2 import build_batch_request  # noqa: E402

TR_BLACKLIST = re.compile(
    r'\b(namaz|vacip|vacib|abdest|oruç|dalgın|yakarış|başkası|diğerleri|gayrısı|kıble|sevap|günah)\b',
    re.IGNORECASE)
HARAKAT = re.compile(r'[ً-ْٰـ]')


def norm_ar(word):
    w = HARAKAT.sub('', word).strip()
    w = re.sub('[أإآٱ]', 'ا', w).replace('ى', 'ي').replace('ة', 'ه')
    return w


def load_bare_headwords():
    with lzma.open('assets/data/sozluk.json.xz', 'rt', encoding='utf-8') as f:
        data = json.load(f)
    bare = set()
    for rec in data:
        for w in (rec.get('harekeliKelime'), rec.get('kelime')):
            if w:
                bare.add(norm_ar(w))
    return bare


def in_dictionary(word, bare):
    w = norm_ar(word)
    candidates = {w}
    for prefix in ('و', 'ف'):
        if w.startswith(prefix):
            candidates.add(w[1:])
    for c in list(candidates):
        if c.startswith('ال'):
            candidates.add(c[2:])
        else:
            candidates.add('ال' + c)
    return any(c in bare for c in candidates)


def extra_flags(lang, result, bare):
    found = []
    if lang == 'ar':
        missing = [w for w in result.get('syn', []) + result.get('ant', [])
                   if ' ' not in w.strip() and not in_dictionary(w, bare)]
        if missing:
            found.append('sözlükte yok: ' + '، '.join(missing))
    else:
        text = ' '.join(result.get('senses', []) + result.get('examples', [])
                        + [m for p in result.get('preps', []) for m in p.get('m', [])])
        hit = TR_BLACKLIST.findall(text)
        if hit:
            found.append('Türkçe kelime: ' + ', '.join(sorted(set(h.lower() for h in hit))))
    return found


def run_chunk(model, lang, level, chunk, hints, key):
    entries = [(s['pid'], s['rec'], hints.get(s['pid']) if hints else None) for s in chunk]
    body = build_batch_request(entries, lang, level)
    rows, missing = [], []
    try:
        text, usage = pr.parse_response(pr.call(model, body, key))
        items = {it.get('id'): it for it in json.loads(text).get('items', [])}
    except Exception as e:  # tüm parça yeniden denenecek
        return [], [s for s in chunk], str(e)[:200]
    share = {k: (v / len(chunk) if isinstance(v, (int, float)) else v) for k, v in usage.items()}
    for s in chunk:
        item = items.get(s['pid'])
        if item is None:
            missing.append(s)
            continue
        item = {k: v for k, v in item.items() if k != 'id'}
        rows.append({'pid': s['pid'], 'model': model, 'lang': lang, 'thinking': level,
                     'pack': len(chunk), 'usage': share, 'result': item})
    return rows, missing, None


def run_lang(model, lang, level, sample, hints, key, pack, workers):
    spec = f'{model}:{level}'
    done = {pid for pid, r in pr.load_results(lang, spec).items() if 'result' in r}
    todo = [s for s in sample if s['pid'] not in done]
    if not todo:
        print(f'[{lang}] zaten tamam')
        return
    print(f'[{lang}] {len(todo)} kelime, {pack} kelime/istek...')
    with open(pr.out_path(lang, spec), 'a', encoding='utf-8') as out:
        for size, items in ((pack, todo), (1, None)):
            if items is None:
                items = retry
                if not items:
                    break
                print(f'  eksik/başarısız {len(items)} kelime tek tek yeniden isteniyor')
            chunks = [items[i:i + size] for i in range(0, len(items), size)]
            retry = []
            with concurrent.futures.ThreadPoolExecutor(workers) as ex:
                for rows, missing, err in ex.map(lambda c: run_chunk(model, lang, level, c, hints, key), chunks):
                    for row in rows:
                        out.write(json.dumps(row, ensure_ascii=False) + '\n')
                    out.flush()
                    retry += missing
                    if err:
                        print('  hata:', err)
            if size == 1 and retry:
                for s in retry:
                    out.write(json.dumps({'pid': s['pid'], 'model': model, 'lang': lang, 'thinking': level,
                                          'error': 'tek tek istekte de alınamadı'}, ensure_ascii=False) + '\n')


def summary(sample, plan, bare):
    recs = {s['pid']: s['rec'] for s in sample}
    for lang, specs in plan.items():
        for spec in specs:
            res = pr.load_results(lang, spec)
            ok = [r for r in res.values() if 'result' in r]
            if not ok:
                continue
            name = pr.split_spec(spec)[0]
            p = pr.PRICES[name]
            tin = sum(r['usage']['in'] for r in ok) / len(ok)
            tout = sum(r['usage']['out'] for r in ok) / len(ok)
            tthink = sum(r['usage'].get('think', 0) for r in ok) / len(ok)
            spent = sum((r['usage']['in'] * p['std'][0] + (r['usage']['out'] + r['usage'].get('think', 0)) * p['std'][1]) / 1e6 for r in ok)
            full = pr.TOTAL_WORDS * (tin * p['batch'][0] + (tout + tthink) * p['batch'][1]) / 1e6
            flags = collections.Counter()
            for r in ok:
                for f in pr.flags(recs[r['pid']], lang, r['result']) + extra_flags(lang, r['result'], bare):
                    flags[f.split(':')[0]] += 1
            singles = sum(1 for r in ok if r.get('pack') == 1)
            print(f'{lang} {spec}: ok={len(ok)}/{len(sample)} tek-tek={singles} girdi={tin:.0f} çıktı={tout:.0f} '
                  f'düşünme={tthink:.0f} harcanan=${spent:.3f} tam≈${full:.1f} uyarılar={dict(flags)}')


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--size', type=int, default=200)
    ap.add_argument('--model', default='gemini-3.1-flash-lite')
    ap.add_argument('--pack', type=int, default=10)
    ap.add_argument('--langs', default='en,fr,id,ms,ur,ar')
    ap.add_argument('--ar-thinking', default='low')
    ap.add_argument('--thinking', default='minimal')
    ap.add_argument('--workers', type=int, default=8)
    ap.add_argument('--report-only', action='store_true')
    args = ap.parse_args()

    pr.SAMPLE = f'content/pilot/sample_{args.size}.jsonl'
    pr.OUT_DIR = f'content/pilot/n{args.size}_r2'
    os.makedirs(pr.OUT_DIR, exist_ok=True)
    sample = pr.load_sample()
    langs = [x.strip() for x in args.langs.split(',') if x.strip()]
    plan = {lang: [f'{args.model}:{args.ar_thinking if lang == "ar" else args.thinking}'] for lang in langs}
    bare = load_bare_headwords()

    if not args.report_only:
        key = os.environ.get('GEMINI_API_KEY')
        if not key:
            sys.exit('GEMINI_API_KEY ortam değişkeni yok.')
        order = (['en'] if 'en' in langs else []) + [x for x in langs if x != 'en']
        hints = None
        for lang in order:
            level = args.ar_thinking if lang == 'ar' else args.thinking
            if lang != 'en':
                en_rows = pr.load_results('en', f'{args.model}:{args.thinking}')
                hints = {pid: r['result'] for pid, r in en_rows.items() if 'result' in r} or None
            run_lang(args.model, lang, level, sample, hints, key, args.pack, args.workers)
    summary(sample, plan, bare)
    pr.report(sample, plan)


if __name__ == '__main__':
    main()
