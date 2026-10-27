"""Sola/sağa sabit yerleşimleri yön duyarlı karşılıklarına çevirir (Arapça/Urduca arayüz için).

Kullanım (kavaid klasöründen):
    python tool/i18n/rtl_convert.py             # dönüştür, dart analyze'da tür hatası veren satırları geri al

EdgeInsets.only(left/right) → EdgeInsetsDirectional.only(start/end), EdgeInsets.fromLTRB → fromSTEB,
Alignment.xLeft/xRight → AlignmentDirectional.xStart/xEnd, Positioned(left/right) → PositionedDirectional.
TextAlign ve TextDirection'a dokunmaz: Arapça içerik bilerek sağa yaslı, onlar elle incelenir.
Satır sayısı değişmediği için hata veren satır, dönüşüm öncesi hâline geri döndürülür.
"""
import os
import re
import subprocess
import sys

EXCLUDE = ['admin', 'debug', 'log_screen', 'learning_screen', 'book', 'quran_', '/l10n/', 'fps_counter']
ALIGN = {'centerLeft': 'centerStart', 'centerRight': 'centerEnd', 'topLeft': 'topStart', 'topRight': 'topEnd',
         'bottomLeft': 'bottomStart', 'bottomRight': 'bottomEnd'}


def call_span(src, open_paren):
    depth, i = 0, open_paren
    while i < len(src):
        if src[i] == '(':
            depth += 1
        elif src[i] == ')':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def rename_args(args, mapping):
    """Yalnız en dış düzeydeki `left:`/`right:` adlı argümanları yeniden adlandırır."""
    out, depth, i = [], 0, 0
    while i < len(args):
        c = args[i]
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        if depth == 0:
            m = re.match(r'\b(left|right)(\s*:)', args[i:])
            if m and (i == 0 or not (args[i - 1].isalnum() or args[i - 1] in '_.')):
                out.append(mapping[m.group(1)] + m.group(2))
                i += len(m.group(0))
                continue
        out.append(c)
        i += 1
    return ''.join(out)


def convert(src):
    for name, new in (('EdgeInsets.only(', 'EdgeInsetsDirectional.only('), ('Positioned(', 'PositionedDirectional(')):
        pos = 0
        while True:
            i = src.find(name, pos)
            if i < 0:
                break
            if i > 0 and (src[i - 1].isalnum() or src[i - 1] in '_.'):
                pos = i + 1
                continue
            open_paren = i + len(name) - 1
            close = call_span(src, open_paren)
            args = src[open_paren + 1:close]
            if re.search(r'(^|[\s,(])(left|right)\s*:', args):
                args = rename_args(args, {'left': 'start', 'right': 'end'})
                src = src[:i] + new + args + src[close:]
            pos = i + 1
    src = re.sub(r'\bEdgeInsets\.fromLTRB\(', 'EdgeInsetsDirectional.fromSTEB(', src)
    src = re.sub(r'\bAlignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)\b',
                 lambda m: 'AlignmentDirectional.' + ALIGN[m.group(1)], src)
    return src


def analyze_errors():
    out = subprocess.run(['dart', 'analyze', '--format=machine', 'lib'], capture_output=True,
                         text=True, encoding='utf-8', shell=True).stdout
    errs = {}
    for line in out.splitlines():
        f = line.split('|')
        if len(f) >= 8 and f[0] == 'ERROR':
            errs.setdefault(os.path.relpath(f[3]).replace('\\', '/'), set()).add(int(f[4]))
    return errs


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    originals = {}
    for root, _, files in os.walk('lib'):
        for name in files:
            path = os.path.join(root, name).replace('\\', '/')
            if not path.endswith('.dart') or any(x in path for x in EXCLUDE):
                continue
            with open(path, encoding='utf-8') as f:
                src = f.read()
            new = convert(src)
            if new != src:
                assert new.count('\n') == src.count('\n'), path
                originals[path] = src
                with open(path, 'w', encoding='utf-8', newline='') as f:
                    f.write(new)
    changed = sum(1 for p, s in originals.items()
                  for a, b in zip(s.split('\n'), open(p, encoding='utf-8').read().split('\n')) if a != b)
    print(f'{len(originals)} dosyada {changed} satır dönüştü')
    for round_no in range(5):
        errs = analyze_errors()
        reverted = 0
        for path, lines in errs.items():
            if path not in originals:
                continue
            old = originals[path].split('\n')
            cur = open(path, encoding='utf-8').read().split('\n')
            for ln in lines:
                # Hata çok satırlı bir çağrının içindeyse, çevresindeki dönüşmüş satırları da geri al
                for j in range(max(0, ln - 6), min(len(cur), ln + 1)):
                    if cur[j] != old[j]:
                        cur[j] = old[j]
                        reverted += 1
            with open(path, 'w', encoding='utf-8', newline='') as f:
                f.write('\n'.join(cur))
        print(f'tur {round_no + 1}: {sum(len(v) for v in errs.values())} hata, {reverted} satır geri alındı')
        if not reverted:
            break


if __name__ == '__main__':
    main()
