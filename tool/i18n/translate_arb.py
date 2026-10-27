"""lib/l10n/app_tr.arb'deki arayüz metinlerini diğer dillere çevirir (gemini-3.1-flash-lite).

Kullanım (kavaid klasöründen, GEMINI_API_KEY ortam değişkeniyle):
    python tool/i18n/translate_arb.py --langs en,ar,id,ms,ur,fr,bn,ru,uz,az,de

Her anahtar, koddaki kullanım satırıyla (buton mu, başlık mı, uyarı mı) birlikte gönderilir.
Eski `isEnglish ? ... : ...` dallarından kalan İngilizce/Arapça metinler (content/ui/seeds*.json)
hazır öneri olarak verilir. Yer tutucular ({name}) ve yazı sistemi denetlenir; hatalılar tek tek
yeniden istenir. Var olan app_<dil>.arb korunur, yalnız eksik anahtarlar çevrilir.
"""
import argparse
import json
import os
import re
import subprocess
import sys
from collections import OrderedDict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pilot_run import call, parse_response  # noqa: E402
from extract_ui_strings import lex, placeholder_names, message  # noqa: E402

MODEL = 'gemini-3.1-flash-lite'
PRICE = (0.25, 1.50)  # standart istek, 1M token başına $ (giriş, çıkış)
CHUNK = 60

LANGS = {
    'en': 'English', 'ar': 'Arabic', 'id': 'Indonesian', 'ms': 'Malay', 'ur': 'Urdu',
    'fr': 'French', 'bn': 'Bengali', 'ru': 'Russian', 'uz': 'Uzbek (Latin script)',
    'az': 'Azerbaijani (Latin script)', 'de': 'German',
}
SCRIPT = {
    'ar': r'[؀-ۿ]', 'ur': r'[؀-ۿ]', 'bn': r'[ঀ-৿]', 'ru': r'[Ѐ-ӿ]',
}

SYSTEM = """You translate the user interface of "Kavaid", a mobile Arabic dictionary app, from Turkish into {lang}.
The app is used by {lang}-speaking learners of Arabic: word meanings, example translations and AI answers
are shown in {lang}. Write the way a native {lang} app would, short and natural, not word-for-word.

Rules:
1. Keep every placeholder in curly braces exactly as given, e.g. {{name}}. Do not translate or rename it.
2. Placeholders whose type is "int" may use ICU plural syntax when {lang} needs it, e.g.
   {{count, plural, =1{{1 word}} other{{{{count}} words}}}}. Otherwise keep the placeholder as is.
3. Match the role shown in "use": buttons and tabs stay short (1-3 words), titles in title style if
   {lang} uses it, messages as full sentences. Keep emojis, line breaks (\\n) and punctuation style.
4. Keep these names unchanged: Kavaid, Premium, Google Play, Apple ID, RevenueCat, EULA, Twitter, @ebubekr53, AI.
5. When the Turkish text means the user's own language (e.g. "Arapça–Türkçe sözlük", "Türkçe yaz"),
   use {lang} instead of Turkish. "Arapça" is Arabic.
6. Arabic grammar terms: use the standard term that {lang} learners of Arabic know
   (mazi = past tense/الماضي, müzari = present tense/المضارع, emir = imperative/الأمر, mastar = verbal noun/المصدر,
   harf-i cer = preposition/حرف الجر, ism-i fail = active participle/اسم الفاعل, ism-i mef'ul = passive participle/اسم المفعول,
   sığa = conjugation form, şahıs = person). "Emsile" is the name of the app's verb conjugation tables
   (Arabic: الأمثلة); keep "Emsile" in Latin-script languages.
7. Kur'an / Kuran = the Quran; ayet = verse (Arabic: آية); meal = translation of a verse.
8. "max_chars" means the text sits in a small chip, tab or table cell: never exceed it. Use the
   shortest natural label, or the abbreviation {lang} learners use (e.g. "act. part."). "note" explains the item.
9. "existing" is an older translation written by the developer; reuse it if it is correct and natural.
10. Return every id with its translation and nothing else.
"""

SCHEMA = {
    'type': 'object',
    'properties': {'items': {'type': 'array', 'items': {
        'type': 'object',
        'properties': {'id': {'type': 'string'}, 't': {'type': 'string'}},
        'required': ['id', 't'],
    }}},
    'required': ['items'],
}


def load(path):
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            return json.load(f, object_pairs_hook=OrderedDict)
    return OrderedDict()


def usage_context():
    """anahtar -> koddaki ilk kullanım satırı (bağlam için bir önceki satırla)."""
    out = subprocess.run(['git', 'grep', '-n', '-B1', r'l10n\.[A-Za-z0-9]*', '--', 'lib'],
                         capture_output=True, text=True, encoding='utf-8').stdout
    ctx, prev = {}, ''
    for line in out.splitlines():
        m = re.match(r'^(.+?)[:-](\d+)[:-](.*)$', line)
        if not m:
            continue
        code = m.group(3).strip()
        for key in re.findall(r'l10n\.([A-Za-z0-9]+)', code):
            ctx.setdefault(key, f'{os.path.basename(m.group(1))}: {prev[-60:]} {code}'[:220])
        prev = code
    return ctx


def seeds_by_key(tr):
    """Eski üçlülerden gelen en/ar metinleri, anahtara göre."""
    msg_to_key = {v: k for k, v in tr.items() if not k.startswith('@')}
    out = {}
    raw = load('content/ui/seeds.json')
    for tr_lit, langs in raw.items():
        s = lex(tr_lit)
        if not s:
            continue
        key = msg_to_key.get(message(s[0], placeholder_names(s[0])))
        if not key:
            continue
        for lang, lit in langs.items():
            ls = lex(lit)
            if ls:
                out.setdefault(key, {})[lang] = message(ls[0], placeholder_names(ls[0]))
    for key, v in load('content/ui/seeds_manual.json').items():
        for lang in LANGS:
            if lang in v:
                out.setdefault(key, {})[lang] = v[lang]
    return out


def placeholders(text):
    """Bir mesajın üst düzey yer tutucu adları (ICU çoğul gövdeleri hariç)."""
    names, depth, i = set(), 0, 0
    while i < len(text):
        if text[i] == '{':
            m = re.match(r'\{([A-Za-z_]\w*)\s*([,}])', text[i:])
            if m:
                names.add(m.group(1))
            depth += 1
        elif text[i] == '}':
            depth -= 1
        i += 1
    return names


def problems(lang, src, t, ph_types, max_len=None):
    if not t or not t.strip():
        return 'boş'
    if max_len and len(t) > max_len:
        return f'çok uzun ({len(t)} > {max_len})'
    if placeholders(t) != set(ph_types):
        return f'yer tutucu {sorted(placeholders(t))} != {sorted(ph_types)}'
    if t.count('{') != t.count('}'):
        return 'süslü parantez dengesiz'
    if lang in SCRIPT and t.strip() != src.strip() and re.search(r'[A-Za-zçğışöüÇĞİŞÖÜ]{3,}', src) and not re.search(SCRIPT[lang], t):
        return 'yazı sistemi'
    if lang != 'az' and re.search(r'[ğışĞİŞ]', t) and not re.search(r'[ğışĞİŞ]', src.replace('Kavaid', '')):
        return 'Türkçe harf sızdı'
    return None


def request(lang, items):
    body = {
        'systemInstruction': {'parts': [{'text': SYSTEM.format(lang=LANGS[lang])}]},
        'contents': [{'role': 'user', 'parts': [{'text': json.dumps({'items': items}, ensure_ascii=False)}]}],
        'generationConfig': {
            'responseMimeType': 'application/json',
            'responseSchema': SCHEMA,
            'thinkingConfig': {'thinkingLevel': 'low'},
        },
    }
    resp = call(MODEL, body, os.environ['GEMINI_API_KEY'])
    text, usage = parse_response(resp)
    try:
        got = {it['id']: it['t'] for it in json.loads(text)['items']}
    except (ValueError, KeyError, TypeError):
        got = {}
    return got, usage


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--langs', required=True)
    ap.add_argument('--refit', action='store_true', help='azami uzunluğu aşan çevirileri yeniden iste')
    args = ap.parse_args()
    max_len = load('tool/i18n/ui_max_len.json')

    tr = load('lib/l10n/app_tr.arb')
    keys = [k for k in tr if not k.startswith('@')]
    ph = {k: (tr.get('@' + k) or {}).get('placeholders', {}) for k in keys}
    ctx = usage_context()
    seeds = seeds_by_key(tr)
    total_in = total_out = 0

    for lang in args.langs.split(','):
        path = f'lib/l10n/app_{lang}.arb'
        arb = load(path)
        arb['@@locale'] = lang
        if args.refit:
            for k, n in max_len.items():
                if k in arb and len(arb[k]) > n:
                    del arb[k]
        todo = [k for k in keys if k not in arb]
        failed = []
        for attempt in range(3):
            batch_size = CHUNK if attempt == 0 else 1
            for i in range(0, len(todo), batch_size):
                chunk = todo[i:i + batch_size]
                items = []
                for k in chunk:
                    item = {'id': k, 'tr': tr[k], 'use': ctx.get(k, '')}
                    note = (tr.get('@' + k) or {}).get('description', '')
                    if note and not note.startswith('lib/'):
                        item['note'] = note
                    if k in max_len:
                        item['max_chars'] = max_len[k]
                    if ph[k]:
                        item['placeholders'] = {n: v.get('type', 'Object') for n, v in ph[k].items()}
                    if lang in seeds.get(k, {}):
                        item['existing'] = seeds[k][lang]
                    items.append(item)
                got, usage = request(lang, items)
                total_in += usage['in']
                total_out += usage['out'] + usage['think']
                for k in chunk:
                    t = got.get(k)
                    err = problems(lang, tr[k], t, ph[k], max_len.get(k))
                    if err:
                        failed.append((k, err, t))
                    else:
                        arb[k] = t
            todo = [k for k, _, _ in failed]
            if not todo:
                break
            if attempt < 2:
                failed = []
        ordered = OrderedDict([('@@locale', lang)] + [(k, arb[k]) for k in keys if k in arb])
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(ordered, f, ensure_ascii=False, indent=2)
            f.write('\n')
        print(f'{lang}: {len(ordered) - 1}/{len(keys)} çevrildi, sorunlu {len(failed)}')
        for k, err, t in failed:
            print(f'   {k}: {err} -> {t!r}')
    cost = (total_in * PRICE[0] + total_out * PRICE[1]) / 1e6
    print(f'token: giriş {total_in:,}, çıkış+düşünme {total_out:,}, maliyet ≈ ${cost:.3f}')


if __name__ == '__main__':
    main()
