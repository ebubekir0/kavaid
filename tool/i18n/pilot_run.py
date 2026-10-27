"""Yerelleştirme pilotu: 50 kelimeyi birkaç Gemini modeliyle üretir, karşılaştırma
raporu ve 54.971 kelimelik tam üretimin maliyet tahminini çıkarır.

Kullanım (kavaid klasöründen):
    python tool/i18n/pilot_run.py --dry-run          # API çağrısı yok, yalnız tahmin
    $env:GEMINI_API_KEY = "..."                      # PowerShell
    python tool/i18n/pilot_run.py                    # 50 kelime x 2 dil x 4 model
    python tool/i18n/pilot_run.py --models gemini-3.1-flash-lite:minimal   # tek model
    python tool/i18n/pilot_run.py --size 200 --models gemini-3.1-flash-lite:minimal \
        --langs en,ar=gemini-3.1-flash-lite:low,id,ms,ur,fr     # dile özel ayar: dil=model:düşünme
    python tool/i18n/pilot_run.py --report-only      # raporu yeniden üret

Çıktılar content/pilot/ (50 kelime) ya da content/pilot/n<boyut>/ altına yazılır:
out_<dil>_<model>_<düşünme>.jsonl, rapor.html, kor_eslesme.json (raporda A/B/C
harflerinin hangi modele karşılık geldiği).

Fiyatlar: ai.google.dev/gemini-api/docs/pricing, 24 Ekim 2026 itibarıyla,
1 M token başına USD (girdi, çıktı). Düşünme token'ları çıktı fiyatından sayılır.
"""
import argparse
import concurrent.futures
import html
import json
import os
import random
import re
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pilot_prompts import build_request, split_anlam, word_payload  # noqa: E402

SAMPLE = 'content/pilot/sample_50.jsonl'
OUT_DIR = 'content/pilot'
TOTAL_WORDS = 54971
# "model:düşünme" çiftleri. 3.1-flash-lite eski hattaki ayarıyla (minimal) ve low ile denenir.
DEFAULT_MODELS = ['gemini-3.1-flash-lite:minimal', 'gemini-3.1-flash-lite:low', 'gemini-3.5-flash-lite:low',
                  'gemini-3.8-flash:low', 'gemini-4-argon:low']
API = 'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent'

PRICES = {
    'gemini-3.5-flash-lite': {'std': (0.30, 2.50), 'batch': (0.15, 1.25)},
    'gemini-3.8-flash': {'std': (0.75, 3.75), 'batch': (0.375, 1.875),
                         'change': ('1 Ocak 2027', (0.75, 3.75))},
    'gemini-4-argon': {'std': (2.00, 10.00), 'batch': (1.00, 5.00),
                       'change': ('1 Aralık 2026', (2.00, 10.00))},
    'gemini-3.1-pro-preview': {'std': (2.00, 12.00), 'batch': (1.00, 6.00)},
    'gemini-3.1-flash-lite': {'std': (0.25, 1.50), 'batch': (0.125, 0.75)},
}

# Eski batch'lerden ölçüldü: ~3,9 karakter = 1 token (Arapça ve Latin aynı).
TOKENS_PER_CHAR = 0.257

AR_RE = re.compile(r'[؀-ۿ]')
LATIN_RE = re.compile(r'[A-Za-z]')
TR_RE = re.compile(r'[ğĞşŞıİ]|\b(ve|bir|etmek|olmak|için)\b')
ARABIC_SCRIPT_LANGS = {'ar', 'ur', 'fa'}
LANG_TITLES = {'en': 'İngilizce', 'ar': 'Arapça–Arapça', 'id': 'Endonezce', 'ms': 'Malayca',
               'ur': 'Urduca', 'fr': 'Fransızca', 'ru': 'Rusça', 'bn': 'Bengalce', 'de': 'Almanca'}


def load_sample():
    with open(SAMPLE, encoding='utf-8') as f:
        return [json.loads(line) for line in f if line.strip()]


def split_spec(spec):
    """'gemini-3.8-flash:low' -> ('gemini-3.8-flash', 'low')."""
    name, _, level = spec.partition(':')
    return name, level


def out_path(lang, spec):
    name, level = split_spec(spec)
    return os.path.join(OUT_DIR, f'out_{lang}_{name}_{level}.jsonl')


def load_results(lang, spec):
    path = out_path(lang, spec)
    if not os.path.exists(path):
        return {}
    results = {}
    with open(path, encoding='utf-8') as f:
        for line in f:
            if line.strip():
                row = json.loads(line)
                results[row['pid']] = row
    return results


# ---------------------------------------------------------------- tahmin

def estimate_output_chars(rec, lang):
    """Görünür çıktı uzunluğunu Türkçe veriden kabaca tahmin eder."""
    meanings, preps = split_anlam(rec.get('anlam'))
    if lang == 'ar':
        return 420 + sum(len(m) for m in preps.values()) * 1.5
    tr_examples = sum(
        len(o.get('turkceCeviri') or o.get('turkceAnlam') or '')
        for o in rec.get('ornekCumleler') or [] if isinstance(o, dict))
    return len(meanings) + sum(len(m) for m in preps.values()) + tr_examples + 120


def dry_run(sample, plan):
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f'{len(sample)} kelime, diller: {", ".join(plan)}\n')
    for lang, specs in plan.items():
        reqs = [build_request(s['rec'], lang, 'low') for s in sample]
        with open(os.path.join(OUT_DIR, f'ornek_istek_{lang}.json'), 'w', encoding='utf-8') as f:
            json.dump(reqs[0], f, ensure_ascii=False, indent=2)
        in_tok = sum(len(json.dumps(r, ensure_ascii=False)) for r in reqs) / len(reqs) * TOKENS_PER_CHAR
        out_tok = sum(estimate_output_chars(s['rec'], lang) for s in sample) / len(sample) * TOKENS_PER_CHAR
        print(f'[{lang}] kelime başına tahmini girdi ~{in_tok:.0f} token, görünür çıktı ~{out_tok:.0f} token')
        print('  düşünme yükü bilinmiyor; 0 ve +300 token senaryosu:')
        for spec in specs:
            p = PRICES.get(split_spec(spec)[0])
            if not p:
                continue
            for extra in (0, 300):
                cost = TOTAL_WORDS * (in_tok * p['batch'][0] + (out_tok + extra) * p['batch'][1]) / 1e6
                line = f'    {spec:32s} +{extra:3d} düşünme: tam batch ≈ ${cost:,.0f}'
                if 'change' in p:
                    date, new = p['change']
                    new_cost = TOTAL_WORDS * (in_tok * new[0] + (out_tok + extra) * new[1]) / 1e6
                    line += f'  ({date} sonrası ≈ ${new_cost:,.0f})'
                print(line)
        print()
    print(f'Örnek istekler: {OUT_DIR}/ornek_istek_<dil>.json')


# ---------------------------------------------------------------- çalıştırma

def call(model, body, key, retries=5):
    data = json.dumps(body, ensure_ascii=False).encode('utf-8')
    req = urllib.request.Request(
        API.format(model=model), data=data, method='POST',
        headers={'Content-Type': 'application/json', 'x-goog-api-key': key})
    delay = 4
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                return json.loads(resp.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            detail = e.read().decode('utf-8', 'replace')[:300]
            if e.code in (429, 500, 503) and attempt < retries - 1:
                time.sleep(delay)
                delay *= 2
                continue
            raise RuntimeError(f'HTTP {e.code}: {detail}') from None
        except (urllib.error.URLError, TimeoutError):
            if attempt < retries - 1:
                time.sleep(delay)
                delay *= 2
                continue
            raise
    raise RuntimeError('tekrar denemeleri tükendi')


def parse_response(resp):
    cand = (resp.get('candidates') or [{}])[0]
    parts = (cand.get('content') or {}).get('parts') or []
    text = ''.join(p.get('text', '') for p in parts if not p.get('thought'))
    usage = resp.get('usageMetadata') or {}
    return text, {
        'in': usage.get('promptTokenCount', 0),
        'out': usage.get('candidatesTokenCount', 0),
        'think': usage.get('thoughtsTokenCount', 0),
        'finish': cand.get('finishReason'),
    }


def run_one(model, lang, thinking, item, key):
    body = build_request(item['rec'], lang, thinking)
    row = {'pid': item['pid'], 'model': model, 'lang': lang, 'thinking': thinking}
    started = time.time()
    try:
        text, usage = parse_response(call(model, body, key))
        row['usage'] = usage
        row['result'] = json.loads(text)
    except Exception as e:  # sonucu kaydet, raporda hata olarak görünsün
        row['error'] = str(e)[:500]
    row['seconds'] = round(time.time() - started, 1)
    return row


def run(sample, plan, workers):
    key = os.environ.get('GEMINI_API_KEY')
    if not key:
        sys.exit('GEMINI_API_KEY ortam değişkeni yok. PowerShell: $env:GEMINI_API_KEY = "..."')
    os.makedirs(OUT_DIR, exist_ok=True)
    for lang, specs in plan.items():
        for spec in specs:
            model, level = split_spec(spec)
            done = {pid for pid, r in load_results(lang, spec).items() if 'result' in r}
            todo = [s for s in sample if s['pid'] not in done]
            if not todo:
                print(f'[{lang}] {spec}: zaten tamam')
                continue
            print(f'[{lang}] {spec}: {len(todo)} istek...')
            with open(out_path(lang, spec), 'a', encoding='utf-8') as out, \
                    concurrent.futures.ThreadPoolExecutor(workers) as pool:
                futures = [pool.submit(run_one, model, lang, level, s, key) for s in todo]
                for n, fut in enumerate(concurrent.futures.as_completed(futures), 1):
                    row = fut.result()
                    out.write(json.dumps(row, ensure_ascii=False) + '\n')
                    out.flush()
                    mark = 'HATA ' + row['error'][:80] if 'error' in row else 'ok'
                    print(f'  {n:2d}/{len(todo)} pid={row["pid"]} {mark}')


# ---------------------------------------------------------------- rapor

def flags(rec, lang, result):
    found = []
    if lang == 'ar':
        text = ' '.join(
            [result.get('sh', ''), result.get('note', '')]
            + result.get('syn', []) + result.get('ant', [])
            + [p.get('m', '') for p in result.get('preps', [])])
        if LATIN_RE.search(text):
            found.append('Latin harf')
        if not result.get('syn'):
            found.append('eş anlamlı yok')
    else:
        text = ' '.join(result.get('senses', []) + result.get('examples', []))
        if lang in ARABIC_SCRIPT_LANGS:
            if LATIN_RE.search(text):
                found.append('Latin harf')
        else:
            if AR_RE.search(text):
                found.append('Arap harfi')
            if TR_RE.search(text):
                found.append('Türkçe sızıntı?')
        if len(result.get('senses', [])) > 12:
            found.append('12+ anlam')
        n_ex = len(word_payload(rec)['examples'])
        if len(result.get('examples', [])) != n_ex:
            found.append(f'örnek sayısı {len(result.get("examples", []))}/{n_ex}')
    tr_preps = set(word_payload(rec)['editor_prepositions'])
    if tr_preps and not result.get('preps'):
        found.append('harf-i cer eksik')
    return found


def render_result(lang, result):
    e = html.escape
    if lang == 'ar':
        rows = [f'<p><b>الشرح:</b> {e(result.get("sh", ""))}</p>']
        if result.get('syn'):
            rows.append(f'<p><b>المرادفات:</b> {e("، ".join(result["syn"]))}</p>')
        if result.get('ant'):
            rows.append(f'<p><b>الأضداد:</b> {e("، ".join(result["ant"]))}</p>')
        if result.get('note'):
            rows.append(f'<p><b>ملاحظة:</b> {e(result["note"])}</p>')
        for p in result.get('preps', []):
            rows.append(f'<p class="prep">{"＋ " if p.get("added") else ""}<b>{e(p.get("h", ""))}</b>: {e(p.get("m", ""))}</p>')
        return '\n'.join(rows)
    rows = [f'<p class="senses">{e(", ".join(result.get("senses", [])))}</p>']
    for p in result.get('preps', []):
        rows.append(f'<p class="prep">{"＋ " if p.get("added") else ""}<b class="ar">{e(p.get("h", ""))}</b> {e(", ".join(p.get("m", [])))}</p>')
    if result.get('examples'):
        rows.append('<ol class="ex">' + ''.join(f'<li>{e(x)}</li>' for x in result['examples']) + '</ol>')
    return '\n'.join(rows)


def report(sample, plan):
    e = html.escape
    rng = random.Random(7)
    letters = {}
    for lang, models in plan.items():
        order = models[:]
        rng.shuffle(order)
        letters[lang] = {m: chr(ord('A') + i) for i, m in enumerate(order)}
    with open(os.path.join(OUT_DIR, 'kor_eslesme.json'), 'w', encoding='utf-8') as f:
        json.dump({lang: {v: k for k, v in m.items()} for lang, m in letters.items()}, f, indent=2)

    cost_rows = []
    sections = []
    for lang, models in plan.items():
        results = {m: load_results(lang, m) for m in models}
        for m in models:
            ok = [r for r in results[m].values() if 'result' in r]
            if not ok:
                continue
            avg_in = sum(r['usage']['in'] for r in ok) / len(ok)
            avg_out = sum(r['usage']['out'] for r in ok) / len(ok)
            avg_think = sum(r['usage']['think'] for r in ok) / len(ok)
            errors = len(results[m]) - len(ok)
            p = PRICES.get(split_spec(m)[0])
            pilot = sum((r['usage']['in'] * p['std'][0] + (r['usage']['out'] + r['usage']['think']) * p['std'][1]) / 1e6 for r in ok) if p else 0
            full = TOTAL_WORDS * (avg_in * p['batch'][0] + (avg_out + avg_think) * p['batch'][1]) / 1e6 if p else 0
            later = ''
            if p and 'change' in p:
                date, new = p['change']
                later = f'${TOTAL_WORDS * (avg_in * new[0] + (avg_out + avg_think) * new[1]) / 1e6:,.0f} ({date} sonrası)'
            n_flags = sum(1 for s in sample if s['pid'] in results[m] and 'result' in results[m][s['pid']]
                          and flags(s['rec'], lang, results[m][s['pid']]['result']))
            cost_rows.append(
                f'<tr><td>{lang}</td><td>{e(m)}</td><td>{letters[lang][m]}</td><td>{len(ok)}</td><td>{errors}</td>'
                f'<td>{avg_in:.0f}</td><td>{avg_out:.0f}</td><td>{avg_think:.0f}</td><td>{n_flags}</td>'
                f'<td>${pilot:.3f}</td><td><b>${full:,.0f}</b></td><td>{later}</td></tr>')

        head = ''.join(f'<th>Model {letters[lang][m]}</th>' for m in sorted(models, key=lambda m: letters[lang][m]))
        body = []
        for s in sample:
            rec = s['rec']
            pay = word_payload(rec)
            tr = [f'<p class="senses">{e(pay["turkish_meanings"])}</p>']
            for h, m in pay['turkish_preposition_meanings'].items():
                tr.append(f'<p class="prep"><b class="ar">{e(h)}</b> {e(m)}</p>')
            if lang != 'ar':
                tr_ex = [o.get('turkceCeviri') or o.get('turkceAnlam') or '' for o in rec.get('ornekCumleler') or [] if isinstance(o, dict)]
                tr.append('<ol class="ex">' + ''.join(f'<li>{e(x)}</li>' for x in tr_ex) + '</ol>')
            cells = []
            for m in sorted(models, key=lambda m: letters[lang][m]):
                r = results[m].get(s['pid'])
                if not r:
                    cells.append('<td class="empty">—</td>')
                elif 'error' in r:
                    cells.append(f'<td class="err">{e(r["error"][:200])}</td>')
                else:
                    fl = flags(rec, lang, r['result'])
                    badge = ''.join(f'<span class="flag">{e(x)}</span>' for x in fl)
                    cls = ' class="rtl"' if lang in ARABIC_SCRIPT_LANGS else ''
                    cells.append(f'<td{cls}>{badge}{render_result(lang, r["result"])}</td>')
            examples_ar = ''.join(f'<li>{e(x)}</li>' for x in pay['examples'])
            body.append(
                f'<tr><td class="word"><div class="ar big">{e(pay["headword"])}</div>'
                f'<div class="meta">{e(pay["part_of_speech"])} · {e(pay["root"])} · {e(s["stratum"])}</div>'
                f'<ol class="ex ar">{examples_ar}</ol></td>'
                f'<td class="tr">{"".join(tr)}</td>{"".join(cells)}</tr>')
        title = LANG_TITLES.get(lang, lang)
        sections.append(
            f'<h2>{title}</h2><table class="cmp"><thead><tr><th>Kelime</th><th>Türkçe (referans)</th>{head}</tr></thead>'
            f'<tbody>{"".join(body)}</tbody></table>')

    page = f'''<!doctype html><html lang="tr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Kavaid pilot</title>
<style>
:root {{ --bg:#fff; --fg:#1d1d1f; --muted:#6e6e73; --line:#e5e5ea; --soft:#f5f5f7; --flag:#b42318; --flagbg:#fef3f2; }}
@media (prefers-color-scheme: dark) {{ :root {{ --bg:#1c1c1e; --fg:#f2f2f7; --muted:#a1a1a6; --line:#3a3a3c; --soft:#2c2c2e; --flag:#ffb4a9; --flagbg:#4a1d18; }} }}
body {{ background:var(--bg); color:var(--fg); font:14px/1.5 system-ui, sans-serif; margin:0 16px 48px; }}
h1 {{ font-size:22px; margin:24px 0 4px; }} h2 {{ font-size:18px; margin:32px 0 8px; }}
.note {{ color:var(--muted); max-width:900px; }}
table {{ border-collapse:collapse; width:100%; }} th, td {{ border:1px solid var(--line); padding:8px; vertical-align:top; text-align:start; }}
th {{ background:var(--soft); position:sticky; top:0; }}
.cmp td {{ min-width:220px; }} .word {{ min-width:180px; }}
.ar {{ font-family:"Scheherazade New", "Noto Naskh Arabic", serif; direction:rtl; }} .big {{ font-size:26px; }}
.rtl {{ direction:rtl; font-family:"Noto Naskh Arabic", serif; font-size:16px; }}
.meta {{ color:var(--muted); font-size:12px; }} p {{ margin:2px 0 6px; }} .senses {{ font-weight:600; }}
.prep {{ font-size:13px; }} ol.ex {{ margin:4px 0; padding-inline-start:18px; color:var(--muted); font-size:13px; }}
.flag {{ display:inline-block; background:var(--flagbg); color:var(--flag); border-radius:4px; padding:0 6px; margin:0 4px 4px 0; font-size:12px; }}
.err {{ color:var(--flag); }} .empty {{ color:var(--muted); }}
.wrap {{ overflow-x:auto; }}
</style></head><body>
<h1>Kavaid yerelleştirme pilotu — {len(sample)} kelime</h1>
<p class="note">Modeller kör karşılaştırma için A/B/C harfleriyle gösterilir (eşleşme: kor_eslesme.json).
Her hücre için doğru / eksik / yanlış diye puan verin. "＋" işareti modelin eklediği harf-i ceri gösterir.
Kırmızı etiketler otomatik kontrol uyarılarıdır.</p>
<h2>Token ve maliyet</h2>
<div class="wrap"><table><thead><tr><th>Dil</th><th>Model</th><th>Harf</th><th>Başarılı</th><th>Hata</th>
<th>Ort. girdi</th><th>Ort. çıktı</th><th>Ort. düşünme</th><th>Uyarılı</th><th>Pilot maliyeti (standart)</th>
<th>Tam üretim, {TOTAL_WORDS:,} kelime (batch)</th><th>Fiyat artışından sonra</th></tr></thead>
<tbody>{"".join(cost_rows)}</tbody></table></div>
<p class="note">Fiyatlar 24 Ekim 2026'daki Gemini fiyat sayfasından; düşünme token'ları çıktı fiyatından sayılır.
Tam üretim tahmini yeniden üretim payını (%5–10) içermez.</p>
<div class="wrap">{"".join(sections)}</div>
</body></html>'''
    path = os.path.join(OUT_DIR, 'rapor.html')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(page)
    print(f'Rapor: {path}')


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--models', default=','.join(DEFAULT_MODELS))
    ap.add_argument('--langs', default='en,ar')
    ap.add_argument('--thinking', default='low', choices=['minimal', 'low', 'medium', 'high'],
                    help='düşünme seviyesi belirtilmeyen modeller için')
    ap.add_argument('--size', type=int, default=50, help='örneklem boyutu (sample_<n>.jsonl)')
    ap.add_argument('--limit', type=int, default=0, help='yalnız ilk N kelime')
    ap.add_argument('--workers', type=int, default=4)
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--report-only', action='store_true')
    args = ap.parse_args()

    global SAMPLE, OUT_DIR
    SAMPLE = f'content/pilot/sample_{args.size}.jsonl'
    OUT_DIR = 'content/pilot' if args.size == 50 else f'content/pilot/n{args.size}'

    sample = load_sample()
    if args.limit:
        sample = sample[:args.limit]

    def parse_specs(text):
        specs = []
        for spec in text.split('+' if '+' in text else ','):
            name, level = split_spec(spec.strip())
            if name:
                specs.append(f'{name}:{level or args.thinking}')
        return specs

    default_specs = parse_specs(args.models)
    plan = {}
    for item in args.langs.split(','):
        lang, _, override = item.strip().partition('=')
        if lang:
            plan[lang] = parse_specs(override) if override else default_specs

    if args.dry_run:
        dry_run(sample, plan)
        return
    if not args.report_only:
        run(sample, plan, args.workers)
    report(sample, plan)


if __name__ == '__main__':
    main()
