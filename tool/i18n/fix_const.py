"""extract_ui_strings.py sonrası `l10n.x` ifadelerini saran `const` anahtar sözcüklerini kaldırır.

Kullanım (kavaid klasöründen):
    python tool/i18n/fix_const.py      # dart analyze çalıştırır, düzeltir, hata kalmayana kadar tekrarlar

`const Text(l10n.x)` → `Text(l10n.x)`; `const liste = [l10n.x]` → `final liste = [...]`.
Çözemediklerini (ör. `static const` alanlar) dosya:satır olarak yazar; onlar elle düzeltilir.
"""
import re
import subprocess
import sys

CODES = {'INVALID_CONSTANT', 'NON_CONSTANT_LIST_ELEMENT', 'NON_CONSTANT_MAP_VALUE',
         'NON_CONSTANT_MAP_KEY', 'NON_CONSTANT_SET_ELEMENT', 'CONST_WITH_NON_CONSTANT_ARGUMENT',
         'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE', 'CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH'}
OPENER_CONST = re.compile(r'\bconst\s+(?:[\w.]+\s*)?(?:<[^<>;]*>\s*)?$')
DECL_CONST = re.compile(r'\bconst(\s+(?:[\w<>?,\s]+\s+)?\w+\s*=\s*)$')


def analyze():
    out = subprocess.run(['dart', 'analyze', '--format=machine', 'lib'], capture_output=True,
                         text=True, encoding='utf-8', shell=True).stdout + ''
    errs = []
    for line in out.splitlines():
        f = line.split('|')
        if len(f) >= 8 and f[0] == 'ERROR':
            errs.append((f[2], f[3], int(f[4]), int(f[5])))
    return errs


def offset(src, line, col):
    pos = 0
    for _ in range(line - 1):
        pos = src.index('\n', pos) + 1
    return pos + col - 1


def enclosing_const(src, pos):
    """pos'u saran const ifadesinin `const` sözcüğünün (başlangıç, bitiş) aralığı."""
    depth, i = 0, pos - 1
    while i >= 0:
        c = src[i]
        if c in ')]}':
            depth += 1
        elif c in '([{':
            if depth == 0:
                head = src[max(0, i - 120):i]
                m = OPENER_CONST.search(head)
                if m:
                    start = i - len(head) + m.start()
                    return start, start + len('const'), 'remove'
                m = DECL_CONST.search(head)
                if m:
                    start = i - len(head) + m.start()
                    return start, start + len('const'), 'final'
            else:
                depth -= 1
        elif c == ';' and depth == 0:
            break
        i -= 1
    # `const x = l10n.y;` gibi parantezsiz bildirim
    line_start = src.rfind('\n', 0, pos) + 1
    m = DECL_CONST.search(src[line_start:pos])
    if m:
        start = line_start + m.start()
        return start, start + len('const'), 'final'
    return None


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    manual = set()
    for round_no in range(1, 15):
        errs = [e for e in analyze() if e[0] in CODES]
        if not errs:
            break
        by_file = {}
        for code, path, line, col in errs:
            by_file.setdefault(path, []).append((line, col, code))
        fixed = 0
        for path, items in by_file.items():
            with open(path, encoding='utf-8') as f:
                src = f.read()
            edits = {}
            for line, col, code in items:
                r = enclosing_const(src, offset(src, line, col))
                if r and not src[max(0, r[0] - 7):r[0]].strip().endswith('static'):
                    edits[r[0]] = r
                else:
                    manual.add(f'{path}:{line} {code}')
            for start in sorted(edits, reverse=True):
                s, e, how = edits[start]
                src = src[:s] + ('final' if how == 'final' else '') + src[e:]
                if how == 'remove' and src[s:s + 1] == ' ':
                    src = src[:s] + src[s + 1:]
                fixed += 1
            with open(path, 'w', encoding='utf-8', newline='') as f:
                f.write(src)
        print(f'tur {round_no}: {len(errs)} hata, {fixed} const düzeltildi')
        if not fixed:
            break
    for m in sorted(manual):
        print('ELLE:', m)


if __name__ == '__main__':
    main()
