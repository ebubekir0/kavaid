"""freq_gap.py adaylarını sınıflandırır (gerçek kelime / isim / lehçe / yabancı / yazım hatası) ve her gerçek
kelimenin sözlük biçimini (lemma) sözlüğümüzle karşılaştırıp gerçekten eksik olanları çıkarır.

Kullanım (kavaid klasöründen; GEMINI_API_KEY ortamda):
    python tool/i18n/freq_classify.py --name subs
Çıktı: content/lang/tr/freq_missing_<ad>.jsonl  {"lemma", "tr", "best_rank", "forms"} — sözlükte olmayan lemmalar,
sıklık sırasıyla. Eşzamanlı istek (gemini-3.8-flash, düşünme low, 60 kelime/istek).
"""
import argparse
import collections
import json
import os
import sys
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from freq_gap import known_forms, variants  # noqa: E402
from pilot_run import PRICES, call, parse_response  # noqa: E402
from syn_filter import norm  # noqa: E402

MODEL = 'gemini-3.8-flash'
PACK = 60

SYSTEM = """You classify Arabic tokens taken from a word frequency list (movie subtitles or Wikipedia), for a learner's dictionary of Modern Standard and Classical Arabic. Tokens are unvowelled and may be inflected or carry attached particles and pronouns.

For each token return:
- "kind":
  "word" = a standard Arabic word (or an inflected form of one, with attached particles or pronouns), including loanwords established in Modern Standard Arabic (دولار، تلفاز، بنك);
  "name" = a proper noun: person, place, organisation, brand, or a transliterated foreign name;
  "dialect" = a colloquial word not used in Modern Standard Arabic;
  "foreign" = a transliterated foreign word that is not an established Arabic loanword;
  "typo" = a misspelling, or two words written together;
  "other" = interjections, sounds, abbreviations, anything else.
- "lemma": for "word" and "typo", the fully vowelled dictionary form of the standard word (indefinite singular noun or adjective with tanween, masculine; verbs in the 3rd person masculine singular past). Otherwise "".
- "tr": for "word", a short Turkish meaning of the lemma (1–3 words). Otherwise "".

Return only JSON matching the schema, one item per token, same order."""

SCHEMA = {
    'type': 'OBJECT',
    'properties': {'items': {'type': 'ARRAY', 'items': {
        'type': 'OBJECT',
        'properties': {
            'token': {'type': 'STRING'},
            'kind': {'type': 'STRING', 'enum': ['word', 'name', 'dialect', 'foreign', 'typo', 'other']},
            'lemma': {'type': 'STRING'},
            'tr': {'type': 'STRING'},
        },
        'required': ['token', 'kind', 'lemma', 'tr'],
    }}},
    'required': ['items'],
}


def body(tokens):
    return {
        'systemInstruction': {'parts': [{'text': SYSTEM}]},
        'contents': [{'role': 'user', 'parts': [{'text': json.dumps(tokens, ensure_ascii=False)}]}],
        'generationConfig': {
            'responseMimeType': 'application/json',
            'responseSchema': SCHEMA,
            'thinkingConfig': {'thinkingLevel': 'low'},
        },
    }


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--name', required=True)
    args = ap.parse_args()
    key = os.environ.get('GEMINI_API_KEY') or sys.exit('GEMINI_API_KEY ortam değişkeni yok.')

    with open(f'content/lang/tr/freq_gap_{args.name}.jsonl', encoding='utf-8') as f:
        cands = [json.loads(line) for line in f]
    groups = [cands[i:i + PACK] for i in range(0, len(cands), PACK)]

    def run(group):
        text, usage = parse_response(call(MODEL, body([c['word'] for c in group]), key))
        try:
            items = json.loads(text)['items']
        except (ValueError, KeyError, TypeError):
            items = []
        return group, items, usage

    with ThreadPoolExecutor(8) as ex:
        results = list(ex.map(run, groups))

    with open('content/master/words.jsonl', encoding='utf-8') as f:
        recs = [json.loads(line)['rec'] for line in f]
    extra = 'content/lang/tr/firebase_missing_v1.jsonl'
    if os.path.exists(extra):
        with open(extra, encoding='utf-8') as f:
            recs += [json.loads(line)['rec'] for line in f]
    forms = known_forms(recs)

    kinds, missing, tin, tout, unmatched = collections.Counter(), {}, 0, 0, 0
    for group, items, usage in results:
        tin += usage['in']
        tout += usage['out'] + usage['think']
        if len(items) != len(group):
            unmatched += len(group)
            continue
        for c, it in zip(group, items):
            kinds[it['kind']] += 1
            if it['kind'] not in ('word', 'typo') or not it['lemma']:
                continue
            n = norm(it['lemma'])
            if not n or variants(n) & forms:
                continue
            m = missing.setdefault(n, {'lemma': it['lemma'], 'tr': it['tr'], 'best_rank': c['rank'], 'forms': []})
            m['best_rank'] = min(m['best_rank'], c['rank'])
            m['forms'].append(c['word'])
            if it['tr'] and not m['tr']:
                m['tr'] = it['tr']

    rows = sorted(missing.values(), key=lambda m: m['best_rank'])
    out = f'content/lang/tr/freq_missing_{args.name}.jsonl'
    with open(out, 'w', encoding='utf-8') as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + '\n')
    std = PRICES[MODEL]['std']
    print(f'aday {len(cands)} · türler {dict(kinds.most_common())} · yanıtı eşleşmeyen {unmatched}')
    print(f'sözlükte olmayan farklı kelime (lemma): {len(rows)}')
    for lim in (5000, 10000, 20000, 30000, 50000):
        print(f'  sıklıkta ilk {lim:>6} içinde: {sum(1 for r in rows if r["best_rank"] <= lim)}')
    print(f'maliyet ≈ ${(tin * std[0] + tout * std[1]) / 1e6:.2f} · çıktı: {out}')


if __name__ == '__main__':
    main()
