"""Arapça–Arapça 3. tur pilotu: zengin madde (numaralı anlamlar, harf-i cer, eş/zıt anlamlı, kalıplar).

Kullanım (kavaid klasöründen, GEMINI_API_KEY ortam değişkeniyle):
    python tool/i18n/pilot_ar3.py --models gemini-3.1-flash-lite,gemini-3.8-flash

Girdi : content/pilot/sample_200.jsonl (aynı 200 kelime), content/lang/en/dict_final.jsonl (İngilizce ipucu)
Çıktı : content/pilot/ar3/out_<model>.jsonl, ekrana maliyet
Biçim bilgisi (mastar, çoğul, çekim) modele ürettirilmez; kendi verimizden gelir. Ayet/şiir alıntısı yok.
"""
import argparse
import json
import os
import sys
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_master import record_key  # noqa: E402
from pilot_prompts import POS_NOTE  # noqa: E402
from pilot_prompts_v2 import word_payload_v2  # noqa: E402
from pilot_run import PRICES, call, parse_response  # noqa: E402

OUT_DIR = 'content/pilot/ar3'

SYSTEM_ARABIC_V3 = """You are a senior Arab lexicographer writing a modern Arabic–Arabic learner's dictionary (معجم عربي–عربي ميسّر) for the app "Kavaid", in the style of a good contemporary dictionary such as معجم اللغة العربية المعاصرة, but with your own original wording. Write everything in clear Modern Standard Arabic and vowel the words a learner could misread.

You receive a JSON array of Arabic headwords. Each entry has an "id", the vowelled headword (it may be an inflected form: a plural, a case-marked noun, a conjugated verb, a word with an attached pronoun or preposition, or a multi-word phrase), its root, part of speech, plural, verb forms, the prepositions the editors listed, the Arabic example sentences (numbered from 0) and English hint meanings (use them only to see which senses are meant).
{pos_note}

Return {{"items": [...]}} with exactly one item per entry, with the same "id", in the same order. Treat every entry independently.

Fields
- "senses" (المعاني): 1–4 distinct senses in modern use, most common first. Do not split one meaning into near-duplicates and do not add rare, archaic or dialect senses. Each sense:
  - "d": a short definition (at most 20 words) that explains the headword in the form shown: a past verb is defined with a past verb phrase in the same person («كَتَمْتُ»: أَخْفَيْتُ الْأَمْرَ…), a plural with a plural, a noun with a noun phrase. Never define the word by itself or only by another word from the same root.
  - "ex": the number of the given example sentence that shows this sense, or -1. Never write new example sentences.
- "preps": for each preposition the editors listed, its meaning as a short Arabic explanation («رَغِبَ فِيهِ: أَحَبَّهُ وَأَرَادَهُ»). You may add at most 2 very common missing prepositions that change the meaning, with "added": true. [] if none.
- "syn" (المرادفات): 0–4 synonyms of the main sense. Each is a single real word (or fixed two-word phrase) in common modern use, with the same part of speech and form (a past verb gets past verbs, a plural gets plurals), vowelled. Fewer is better than wrong; [] if unsure.
- "ant" (الأضداد): 0–3 clear antonyms with the same rules; [] when there is no natural antonym.
- "colloc" (تعابير): 0–3 very common fixed expressions or collocations that contain the word (كَتَمَ غَيْظَهُ، كَاتِمُ الصَّوْتِ). [] if none come to mind with certainty.
- "data_issue": true only if the editors' data is inconsistent with the vowelled headword (the examples or hints belong to another word, or the headword looks misspelled). Still write the best entry you can.

Accuracy rules
- Words spelled alike but vowelled differently are different words (دِين religion, دَيْن debt; آذَان ears, أَذَان call to prayer). Explain only the vowelled headword given.
- Never state plural, singular, feminine, root, pattern, bāb, iʿrāb or other grammar facts; the app shows them from its own data.
- Never quote the Quran, hadith or poetry, and never put text in ﴿ ﴾.
- Never output Turkish or English words, and no Latin letters.
- Write original wording; do not copy published dictionaries.

Return only JSON that matches the schema."""

# v4: kart diğer dillerdeki gibi en üstte kısa karşılık satırı (eş anlamlılar) gösterir; altında
# İngilizce ipucundaki her ayrı anlam için numaralı şerh (derinlik).
SYSTEM_ARABIC_V4 = SYSTEM_ARABIC_V3.replace(
    """- "senses" (المعاني): 1–4 distinct senses in modern use, most common first. Do not split one meaning into near-duplicates and do not add rare, archaic or dialect senses. Each sense:""",
    """- "senses" (المعاني): cover EVERY distinct sense listed in the hint meanings that fits the vowelled headword, most common first, at most 5 (عَيْنٌ: the eye, a water spring, a spy, the essence of a thing… each is its own sense). Merge only hints that are near-duplicates of one sense ("to say, to speak" is one sense). Give a single sense only when the word truly has one meaning. Do not add rare, archaic or dialect senses that the hints do not suggest. Each sense:""").replace(
    """- "syn" (المرادفات): 0–4 synonyms of the main sense.""",
    """- "syn" (المرادفات): 2–5 synonyms, shown at the top of the card as the quick meaning line, main sense first; they may cover several senses.""")

# v5 (kartın son hali, 25 Ekim 2026): yalnız numaralı anlamlar ve harf-i cer. Eş/zıt anlamlı ve
# kalıplar karttan kaldırıldı. Kelimenin kendi örneği uymayan anlama kısa bir örnek yazılır.
SYSTEM_ARABIC_V5 = """You are a senior Arab lexicographer writing a modern Arabic–Arabic learner's dictionary (معجم عربي–عربي ميسّر) for the app "Kavaid", in the style of a good contemporary dictionary such as معجم اللغة العربية المعاصرة, but with your own original wording. Write everything in clear Modern Standard Arabic and vowel the words a learner could misread.

You receive a JSON array of Arabic headwords. Each entry has an "id", the vowelled headword (it may be an inflected form: a plural, a case-marked noun, a conjugated verb, a word with an attached pronoun or preposition, or a multi-word phrase), its root, part of speech, plural, verb forms, the prepositions the editors listed, the Arabic example sentences (numbered from 0) and English hint meanings (use them only to see which senses are meant).
{pos_note}

Return {{"items": [...]}} with exactly one item per entry, with the same "id", in the same order. Treat every entry independently.

Fields
- "senses" (المعاني): cover EVERY distinct sense listed in the hint meanings that fits the vowelled headword, most common first, at most 5 (عَيْنٌ: the eye, a water spring, a spy, the essence of a thing… each is its own sense). Merge only hints that are near-duplicates of one sense ("to say, to speak" is one sense). Give a single sense only when the word truly has one meaning. Do not add rare, archaic or dialect senses that the hints do not suggest. Each sense:
  - "d": a short definition (at most 20 words) that explains the headword in the form shown: a past verb is defined with a past verb phrase in the same person («كَتَمْتُ»: أَخْفَيْتُ الْأَمْرَ…), a plural with a plural, a noun with a noun phrase. Never define the word by itself or only by another word from the same root.
  - "ex": the number of the given example sentence that shows this sense, or -1. Use each given example for at most one sense.
  - "ext": only when "ex" is -1: one short, natural, everyday example sentence (at most 8 words) in Modern Standard Arabic, fully vowelled, that uses the headword in this sense. Otherwise "".
- "preps": for each preposition the editors listed, write "m" as «usage: meaning», where the usage keeps the headword in the form shown with the preposition and the meaning is a short Arabic explanation in the same person and tense («فَاخْتَرْتُهُ عَلَى غَيْرِهِ: فَضَّلْتُهُ عَلَيْهِ», «رَغِبَ فِيهِ: أَحَبَّهُ وَأَرَادَهُ»). You may add at most 2 very common missing prepositions that change the meaning, with "added": true. [] if none.
- "data_issue": true only if the editors' data is inconsistent with the vowelled headword (the examples or hints belong to another word, or the headword looks misspelled). Still write the best entry you can.

Accuracy rules
- Words spelled alike but vowelled differently are different words (دِين religion, دَيْن debt; آذَان ears, أَذَان call to prayer). Explain only the vowelled headword given.
- Never state plural, singular, feminine, root, pattern, bāb, iʿrāb or other grammar facts; the app shows them from its own data.
- Never quote the Quran, hadith or poetry, and never put text in ﴿ ﴾. Example sentences are your own simple modern sentences.
- Never output Turkish or English words, and no Latin letters.
- Write original wording; do not copy published dictionaries.

Return only JSON that matches the schema."""

SCHEMA_ARABIC_V5 = {
    'type': 'OBJECT',
    'properties': {'items': {'type': 'ARRAY', 'items': {
        'type': 'OBJECT',
        'properties': {
            'id': {'type': 'INTEGER'},
            'senses': {'type': 'ARRAY', 'items': {
                'type': 'OBJECT',
                'properties': {'d': {'type': 'STRING'}, 'ex': {'type': 'INTEGER'}, 'ext': {'type': 'STRING'}},
                'required': ['d', 'ex', 'ext'],
            }},
            'preps': {'type': 'ARRAY', 'items': {
                'type': 'OBJECT',
                'properties': {'h': {'type': 'STRING'}, 'm': {'type': 'STRING'}, 'added': {'type': 'BOOLEAN'}},
                'required': ['h', 'm', 'added'],
            }},
            'data_issue': {'type': 'BOOLEAN'},
        },
        'required': ['id', 'senses', 'preps', 'data_issue'],
    }}},
    'required': ['items'],
}

SCHEMA_ARABIC_V3 = {
    'type': 'OBJECT',
    'properties': {'items': {'type': 'ARRAY', 'items': {
        'type': 'OBJECT',
        'properties': {
            'id': {'type': 'INTEGER'},
            'senses': {'type': 'ARRAY', 'items': {
                'type': 'OBJECT',
                'properties': {'d': {'type': 'STRING'}, 'ex': {'type': 'INTEGER'}},
                'required': ['d', 'ex'],
            }},
            'preps': {'type': 'ARRAY', 'items': {
                'type': 'OBJECT',
                'properties': {'h': {'type': 'STRING'}, 'm': {'type': 'STRING'}, 'added': {'type': 'BOOLEAN'}},
                'required': ['h', 'm', 'added'],
            }},
            'syn': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
            'ant': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
            'colloc': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
            'data_issue': {'type': 'BOOLEAN'},
        },
        'required': ['id', 'senses', 'preps', 'syn', 'ant', 'colloc', 'data_issue'],
    }}},
    'required': ['items'],
}


def build_request(entries, thinking_level, system=None, schema=None):
    payload = []
    for pid, rec, hint in entries:
        e = word_payload_v2(pid, rec, hint)
        e['examples'] = {str(i): s for i, s in enumerate(e.get('examples') or [])}
        payload.append(e)
    return {
        'systemInstruction': {'parts': [{'text': (system or SYSTEM_ARABIC_V3).format(pos_note=POS_NOTE)}]},
        'contents': [{'role': 'user', 'parts': [{'text': json.dumps(payload, ensure_ascii=False)}]}],
        'generationConfig': {
            'responseMimeType': 'application/json',
            'responseSchema': schema or SCHEMA_ARABIC_V3,
            'thinkingConfig': {'thinkingLevel': thinking_level},
        },
    }


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--models', default='gemini-3.1-flash-lite')
    ap.add_argument('--thinking', default='low')
    ap.add_argument('--pack', type=int, default=10)
    ap.add_argument('--prompt', default='v3', choices=['v3', 'v4', 'v5'])
    ap.add_argument('--sample', default='content/pilot/sample_200.jsonl')
    ap.add_argument('--out-dir', default=OUT_DIR)
    args = ap.parse_args()
    system = {'v3': SYSTEM_ARABIC_V3, 'v4': SYSTEM_ARABIC_V4, 'v5': SYSTEM_ARABIC_V5}[args.prompt]
    schema = SCHEMA_ARABIC_V5 if args.prompt == 'v5' else SCHEMA_ARABIC_V3
    key = os.environ['GEMINI_API_KEY']

    sample = [json.loads(l) for l in open(args.sample, encoding='utf-8')]
    wid_map = json.load(open('content/master/wid_map.json', encoding='utf-8'))
    en = {}
    for line in open('content/lang/en/dict_final.jsonl', encoding='utf-8'):
        r = json.loads(line)
        en[r['wid']] = r['result']
    entries = [(s['pid'], s['rec'], en.get(wid_map.get(record_key(s['rec'])))) for s in sample]
    chunks = [entries[i:i + args.pack] for i in range(0, len(entries), args.pack)]
    os.makedirs(args.out_dir, exist_ok=True)

    for model in args.models.split(','):
        def run(chunk):
            body = build_request(chunk, args.thinking, system, schema)
            text, usage = parse_response(call(model, body, key))
            try:
                items = {it['id']: it for it in json.loads(text)['items']}
            except (ValueError, KeyError, TypeError):
                items = {}
            share = {k: v / len(chunk) for k, v in usage.items() if isinstance(v, (int, float))}
            return [{'pid': pid, 'model': model, 'usage': share, 'result': items.get(pid)} for pid, _, _ in chunk]

        with ThreadPoolExecutor(4) as ex:
            rows = [r for part in ex.map(run, chunks) for r in part]
        path = f'{args.out_dir}/out_{model}.jsonl'
        with open(path, 'w', encoding='utf-8') as f:
            for r in rows:
                f.write(json.dumps(r, ensure_ascii=False) + '\n')
        tin = sum(r['usage'].get('in', 0) for r in rows)
        tout = sum(r['usage'].get('out', 0) + r['usage'].get('think', 0) for r in rows)
        std, batch = PRICES[model]['std'], PRICES[model]['batch']
        cost = (tin * std[0] + tout * std[1]) / 1e6
        full = 54962 / len(rows) * (tin * batch[0] + tout * batch[1]) / 1e6
        missing = sum(1 for r in rows if not r['result'])
        print(f'{model}: {len(rows)} kelime, eksik {missing}, kelime başı giriş {tin / len(rows):.0f} / çıkış {tout / len(rows):.0f} token, '
              f'pilot ${cost:.3f}, tam üretim (batch) ≈ ${full:.1f}')


if __name__ == '__main__':
    main()
