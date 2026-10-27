"""Eski `LanguageService().isEnglish ? 'EN' : (isArabic ? 'AR' : 'TR')` üçlülerini Türkçe dizeye indirir.

Kullanım (kavaid klasöründen):
    python tool/i18n/resolve_lang_ternaries.py

isEnglish/isArabic bugün hep false döndüğü için davranış değişmez. İngilizce/Arapça dizeler
çeviri tohumu olarak content/ui/seeds.json'a yazılır ({Türkçe kaynak dize: {en, ar}}); ARB
anahtarları oluşunca translate_arb.py bunları hazır çeviri olarak kullanır.
"""
import json
import os
import re
import sys

LIT = r"""(?:'(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")"""
OBJ = r"(?:LanguageService\(\)|_?languageService|_?langService|\blang)"
EN = OBJ + r"\s*\.isEnglish"
AR = OBJ + r"\s*\.isArabic"
S = r"\s*"


def alt(inner):
    """İç üçlü parantezli ya da parantezsiz olabilir."""
    return rf"(?P<open>\({S})?{inner}(?(open){S}\))"


PATTERNS = [
    # isEnglish ? EN : (isArabic ? AR : TR)
    (re.compile(rf"{EN}{S}\?{S}(?P<en>{LIT}){S}:{S}" + alt(rf"{AR}{S}\?{S}(?P<ar>{LIT}){S}:{S}(?P<tr>{LIT})")), ),
    # isArabic ? AR : (isEnglish ? EN : TR)
    (re.compile(rf"{AR}{S}\?{S}(?P<ar>{LIT}){S}:{S}" + alt(rf"{EN}{S}\?{S}(?P<en>{LIT}){S}:{S}(?P<tr>{LIT})")), ),
    # isEnglish ? EN : TR
    (re.compile(rf"{EN}{S}\?{S}(?P<en>{LIT}){S}:{S}(?P<tr>{LIT})"), ),
    # isArabic ? AR : TR
    (re.compile(rf"{AR}{S}\?{S}(?P<ar>{LIT}){S}:{S}(?P<tr>{LIT})"), ),
]


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    seeds_path = 'content/ui/seeds.json'
    seeds = {}
    if os.path.exists(seeds_path):
        with open(seeds_path, encoding='utf-8') as f:
            seeds = json.load(f)
    total = 0
    for root, _, files in os.walk('lib'):
        for name in files:
            path = os.path.join(root, name).replace('\\', '/')
            if not path.endswith('.dart'):
                continue
            with open(path, encoding='utf-8') as f:
                src = f.read()
            count = 0
            for (pat,) in PATTERNS:
                def repl(m):
                    nonlocal count
                    count += 1
                    tr = m.group('tr')
                    entry = seeds.setdefault(tr, {})
                    for lang in ('en', 'ar'):
                        if m.groupdict().get(lang):
                            entry[lang] = m.group(lang)
                    return tr
                src = pat.sub(repl, src)
            if count:
                with open(path, 'w', encoding='utf-8', newline='') as f:
                    f.write(src)
                print(f'{count:4d}  {path}')
                total += count
    os.makedirs(os.path.dirname(seeds_path), exist_ok=True)
    with open(seeds_path, 'w', encoding='utf-8') as f:
        json.dump(seeds, f, ensure_ascii=False, indent=1)
    print(f'toplam {total} üçlü sadeleşti, {len(seeds)} tohum')


if __name__ == '__main__':
    main()
