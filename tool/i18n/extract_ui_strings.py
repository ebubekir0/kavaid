"""Koddaki sabit Türkçe arayüz metinlerini bulur, ARB anahtarı önerir ve (isteğe bağlı) yerine `l10n.anahtar` yazar.

Kullanım (kavaid klasöründen):
    python tool/i18n/extract_ui_strings.py --survey            # dosya başına aday sayısı
    python tool/i18n/extract_ui_strings.py --list FILE...       # adayları satırıyla göster
    python tool/i18n/extract_ui_strings.py --apply FILE...      # metinleri app_tr.arb'ye yaz, kodda değiştir

Aday: en az bir Türkçe harf ya da iki kelime içeren, log/hata/karşılaştırma/harita anahtarı
bağlamında olmayan dize. Ara değerler (`$x`, `${ifade}`) ARB yer tutucusu olur.
Değiştirmeden sonra `flutter analyze` ile kalan `const` hataları ayrıca düzeltilir (fix_const.py).
"""
import argparse
import json
import os
import re
import sys
import unicodedata
from collections import OrderedDict

ARB = 'lib/l10n/app_tr.arb'
IMPORT = "import 'package:kavaid/l10n/l10n.dart';"

# Çevrilmeyecek dosyalar: Öğren sekmesi (Türkçeye özel), yönetici/hata ayıklama, veri, yapay zekâ istemleri.
EXCLUDE = [
    'lib/l10n/', 'lib/data/', 'admin', 'debug', 'log_screen', 'firebase_options',
    'gemini', 'prompt', 'type_translations',
    # Öğren sekmesi ve Kuran sözlüğü Türkçeye özel (plan 3.3)
    'learning_screen', 'book_store_service', 'book_purchase_service', 'legacy_book_texts_screen',
    'interactive_book_screen', 'quran_',
    # SQL, istem, kullanıcı adı üretimi, sohbet içeriği gibi veri/mantık dizeleri
    'emsile_database_service', 'dialect_translation_service', 'search_ranking', '/database_service.dart',
    'saved_words_service', 'migrate_usernames', 'database_cleanup_utility', 'language_service',
    'community_chat_service', 'auth_service', 'dialect_language', 'fps_counter',
]

TURKISH = re.compile(r'[çğıöşüÇĞİÖŞÜ]')
WORDS2 = re.compile(r'[A-Za-zÀ-ɏ]{2,}[^\S\n]+[A-Za-zÀ-ɏ]{2,}')
# Bu bağlamlarda dize kullanıcıya gösterilmez ya da mantığa bağlıdır
SKIP_BEFORE = re.compile(
    r'(debugPrint|print|log|developer\.log|Exception|Error|assert|RegExp|logEvent|setCustomKey|recordError|'
    r'==|!=|case|contains|startsWith|endsWith|indexOf|split|replaceAll|replaceFirst|getString|setString|'
    r'getBool|setBool|getInt|setInt|remove|containsKey|collection|doc|child|ref|where|orderBy|'
    r'Key|ValueKey|PageStorageKey|name)\s*\(?\s*$')
SKIP_AFTER = re.compile(r'^\s*(:(?!:)|==|!=|\])')
CODEISH = re.compile(r'^(https?:|assets/|package:|[\w.]+\.(dart|json|png|jpg|webp|mp3|db|gz)$|SELECT |CREATE |INSERT |UPDATE |DELETE |ALTER )', re.I)


def lex(src):
    """Kaynaktaki dize sabitlerini (iç içe olmayan) döndürür: {start, end, raw, parts}."""
    out = []
    i, n = 0, len(src)

    def string_at(i):
        start = i
        is_raw = False
        if src[i] in 'rR':
            is_raw = True
            i += 1
        q = src[i:i + 3] if src[i:i + 3] in ("'''", '"""') else src[i]
        i += len(q)
        parts, buf = [], []
        while i < n:
            if src.startswith(q, i):
                i += len(q)
                if buf:
                    parts.append(('t', ''.join(buf)))
                return {'start': start, 'end': i, 'parts': parts, 'raw': is_raw, 'q': q}
            c = src[i]
            if c == '\\' and not is_raw:
                buf.append(src[i:i + 2])
                i += 2
                continue
            if c == '$' and not is_raw:
                if src.startswith('${', i):
                    j = code(i + 2, True)
                    if buf:
                        parts.append(('t', ''.join(buf)))
                        buf = []
                    parts.append(('e', src[i + 2:j - 1].strip()))
                    i = j
                    continue
                m = re.match(r'\$([A-Za-z_]\w*)', src[i:])
                if m:
                    if buf:
                        parts.append(('t', ''.join(buf)))
                        buf = []
                    parts.append(('e', m.group(1)))
                    i += len(m.group(0))
                    continue
            buf.append(c)
            i += 1
        raise ValueError(f'kapanmayan dize @{start}')

    def code(i, until_brace):
        depth = 0
        while i < n:
            c = src[i]
            if src.startswith('//', i):
                i = src.find('\n', i)
                i = n if i < 0 else i
                continue
            if src.startswith('/*', i):
                d, i = 1, i + 2
                while i < n and d:
                    if src.startswith('/*', i):
                        d, i = d + 1, i + 2
                    elif src.startswith('*/', i):
                        d, i = d - 1, i + 2
                    else:
                        i += 1
                continue
            if c in '\'"' or (c in 'rR' and i + 1 < n and src[i + 1] in '\'"' and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] == '_'))):
                s = string_at(i)
                if not until_brace:
                    out.append(s)
                i = s['end']
                continue
            if until_brace:
                if c == '{':
                    depth += 1
                elif c == '}':
                    if depth == 0:
                        return i + 1
                    depth -= 1
            i += 1
        return i

    code(0, False)
    return out


def unescape(t):
    t = re.sub(r'\\u\{([0-9a-fA-F]+)\}|\\u([0-9a-fA-F]{4})', lambda m: chr(int(m.group(1) or m.group(2), 16)), t)
    return (t.replace("\\'", "'").replace('\\"', '"').replace('\\$', '$')
             .replace('\\n', '\n').replace('\\t', '\t').replace('\\\\', '\\'))


def static_text(s):
    return ''.join(unescape(v) for k, v in s['parts'] if k == 't')


UI_CONTEXT = re.compile(r'(Text\(|label:|title:|tooltip:|hintText:|labelText:|helperText:|content:|message:|'
                        r'semanticLabel:|text:|errorText:)\s*(const\s+)?(Text\()?\s*$')
SINGLE_WORD = re.compile(r"[A-ZÇĞİÖŞÜ][\w'’-]*[.!?…:]*")
SEEDS = {}
if os.path.exists('content/ui/seeds.json'):
    with open('content/ui/seeds.json', encoding='utf-8') as _f:
        SEEDS = json.load(_f)


def is_candidate(src, s):
    text = static_text(s)
    if not text.strip() or CODEISH.search(text.strip()):
        return False
    literal = src[s['start']:s['end']]
    line_start = src.rfind('\n', 0, s['start']) + 1
    ui_context = UI_CONTEXT.search(src[max(line_start - 200, 0):s['start']].rstrip() + ' ')
    if literal in SEEDS or (SINGLE_WORD.fullmatch(text.strip()) and ui_context):
        return True
    if not (TURKISH.search(text) or WORDS2.search(text)):
        return False
    # Türkçe harfsiz, tamamı küçük harf ya da köşeli parantezli dizeler geliştirici etiketidir
    if not TURKISH.search(text) and (text == text.lower() or text.lstrip().startswith('[')):
        return False
    line_start = src.rfind('\n', 0, s['start']) + 1
    before = src[max(line_start - 200, 0):s['start']]
    before_line = src[line_start:s['start']]
    if SKIP_BEFORE.search(before_line) or SKIP_BEFORE.search(before.rstrip()):
        return False
    if re.search(r'\b(debugPrint|print|log|Exception|developer\.log)\s*\($', before.rstrip().split(';')[-1].split('(')[0] + '('):
        pass
    stmt = before[before.rfind(';') + 1:]
    if re.search(r'\b(debugPrint|print|Exception|logEvent|log)\s*\(', stmt) and stmt.count('(') > stmt.count(')'):
        return False
    if src.lstrip().startswith(('import', 'export', 'part')) and before_line.lstrip().startswith(('import', 'export', 'part')):
        return False
    after = src[s['end']:s['end'] + 10]
    if SKIP_AFTER.search(after):
        return False
    return True


ASCII = str.maketrans('çğıöşüÇĞİÖŞÜâîûÂÎÛ', 'cgiosuCGIOSUaiuAIU')
KEYWORDS = {'is', 'in', 'as', 'if', 'do', 'for', 'new', 'var', 'try', 'get', 'set', 'on', 'of',
            'case', 'else', 'this', 'true', 'false', 'null', 'with', 'class', 'enum', 'final', 'const',
            'return', 'switch', 'default', 'void', 'super', 'import', 'part', 'show', 'hide'}


def make_key(text, used):
    t = unicodedata.normalize('NFKD', text.translate(ASCII))
    words = re.findall(r'[A-Za-z0-9]+', t)[:5] or ['metin']
    key = words[0].lower() + ''.join(w[:1].upper() + w[1:].lower() for w in words[1:])
    if key[0].isdigit() or key in KEYWORDS:
        key = 'm' + key[:1].upper() + key[1:]
    base, k = key, 2
    while key in used and used[key] != text:
        key, k = f'{base}{k}', k + 1
    return key


def placeholder_names(s):
    names, seen = [], set()
    for k, v in s['parts']:
        if k != 'e':
            continue
        m = re.fullmatch(r'(?:[A-Za-z_]\w*[.!?]*\.)*([A-Za-z_]\w*)', v)
        name = m.group(1) if m else f'p{len(names) + 1}'
        name = re.sub(r'^_+', '', name) or f'p{len(names) + 1}'
        while name in seen:
            name += '2'
        seen.add(name)
        names.append((name, v))
    return names


def message(s, names):
    it = iter(names)
    out = []
    for k, v in s['parts']:
        out.append(unescape(v) if k == 't' else '{' + next(it)[0] + '}')
    return ''.join(out)


def files_in_scope(args_files):
    if args_files:
        return args_files
    res = []
    for root, _, fs in os.walk('lib'):
        for f in fs:
            p = os.path.join(root, f).replace('\\', '/')
            if p.endswith('.dart') and not any(x in p for x in EXCLUDE):
                res.append(p)
    return sorted(res)


def load_arb():
    if os.path.exists(ARB):
        with open(ARB, encoding='utf-8') as f:
            return json.load(f, object_pairs_hook=OrderedDict)
    return OrderedDict([('@@locale', 'tr')])


def library_of(path, src):
    m = re.search(r"^part of '([^']+)';", src, re.M)
    return os.path.normpath(os.path.join(os.path.dirname(path), m.group(1))).replace('\\', '/') if m else path


def add_import(path):
    with open(path, encoding='utf-8') as f:
        src = f.read()
    if IMPORT in src:
        return
    imports = list(re.finditer(r'^import .*;$', src, re.M))
    pos = imports[-1].end() if imports else 0
    src = src[:pos] + ('\n' if imports else '') + IMPORT + ('\n' if not imports else '') + src[pos:]
    with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(src)


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--survey', action='store_true')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--skip-lines', default='', help='atlanacak satırlar: dosya:satır,dosya:satır')
    ap.add_argument('files', nargs='*')
    a = ap.parse_args()
    skip = {tuple(x.rsplit(':', 1)) for x in a.skip_lines.split(',') if x}

    arb = load_arb()
    used = {k: v for k, v in arb.items() if not k.startswith('@')}
    by_text = {v: k for k, v in used.items()}
    total = 0
    for path in files_in_scope(a.files):
        with open(path, encoding='utf-8') as f:
            src = f.read()
        cands = []
        for s in lex(src):
            line = src.count('\n', 0, s['start']) + 1
            if (path, str(line)) in skip or not is_candidate(src, s):
                continue
            cands.append((line, s))
        total += len(cands)
        if a.survey:
            if cands:
                print(f'{len(cands):4d}  {path}')
            continue
        if a.list:
            for line, s in cands:
                print(f'{path}:{line}: {src[s["start"]:s["end"]][:110]!s}')
            continue
        if a.apply and cands:
            edits = []
            for line, s in cands:
                names = placeholder_names(s)
                msg = message(s, names)
                key = by_text.get(msg) or make_key(msg, used)
                if key not in used:
                    used[key] = msg
                    by_text[msg] = key
                    arb[key] = msg
                    meta = {'description': f'{path}:{line}'}
                    if names:
                        meta['placeholders'] = {n: {'type': 'Object'} for n, _ in names}
                    arb['@' + key] = meta
                call = f'l10n.{key}' + (f'({", ".join(e for _, e in names)})' if names else '')
                edits.append((s['start'], s['end'], call))
            for start, end, call in sorted(edits, reverse=True):
                src = src[:start] + call + src[end:]
            with open(path, 'w', encoding='utf-8', newline='') as f:
                f.write(src)
            add_import(library_of(path, src))
            print(f'{len(edits):4d} değişti  {path}')
    if a.apply:
        os.makedirs(os.path.dirname(ARB), exist_ok=True)
        with open(ARB, 'w', encoding='utf-8') as f:
            json.dump(arb, f, ensure_ascii=False, indent=2)
            f.write('\n')
        print(f'{ARB}: {sum(1 for k in arb if not k.startswith("@"))} anahtar')
    print(f'toplam aday: {total}')


if __name__ == '__main__':
    main()
