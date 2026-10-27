"""Yerelleştirme pilotu 2. tur istemleri.

1. turdan farklar: tek istekte birden çok kelime (id'li dizi); sözlük biçimi fiil
mastarla; örnek cümleler kendi biçimiyle çevrilir; ipucu dili İngilizce (en
dışında); Türkçe kelime yasağı; Arapçada not alanından dil bilgisi çıkarıldı.
"""
import json

from pilot_prompts import LANG_NAMES, POS_NOTE, SCHEMA_ARABIC, SCHEMA_TRANSLATION, word_payload

SYSTEM_TRANSLATION_V2 = """You are a senior Arabic lexicographer writing entries for an Arabic–{lang} learner's dictionary (the app "Kavaid"). Its users learn Modern Standard and Classical/Quranic Arabic. Accuracy matters more than coverage.

You receive a JSON array of Arabic headwords. Each entry has an "id", the vowelled headword (it may be an inflected form: a plural, a case-marked noun, a conjugated verb, a word with an attached pronoun or preposition, or a multi-word phrase), its root, part of speech, plural, verb forms, the prepositions the editors listed, the Arabic example sentences and hint meanings written by the editors in {hint_lang}.
{pos_note}

Return {{"items": [...]}} with exactly one item per entry, with the same "id", in the same order. Treat every entry independently.

"senses"
1. Translate the headword in exactly the form shown: a plural stays plural, a word with an attached pronoun keeps it ("your book"), a noun with an attached preposition keeps it ("with joy"), a passive stays passive.
2. Verbs: if the headword is the dictionary form (third person masculine singular past, e.g. كَتَبَ), give {lang} infinitives ("to write"). For every other conjugation translate the exact form, with the pronoun when it is not third person masculine singular ("she loved", "they help", "you opened"). Only gender or number markers may be added in parentheses: (f.), (pl.), (dual).
3. Order from the most common Modern Standard Arabic meaning to less common or classical ones. Usually 3–8 senses, never more than 12. Do not invent rare meanings.
4. Each array element is ONE short gloss of 1–4 words. Never put two glosses in one element, no commas inside an element, no numbering, no explanations.
5. The hint meanings show which senses the editors meant. Use them only to choose senses. Do not copy hint words unless they are genuine {lang} words, and never output Turkish words. Drop any hint sense that does not fit the Arabic word.
6. Words spelled alike but vowelled differently are different words (دِين religion / دَيْن debt, آذَان ears / أَذَان call to prayer). Translate only the vowelled headword given.
7. Use standard {lang} spelling.

"preps"
8. For each preposition the editors listed, give what the word means with it, as 1–3 short glosses in the base (infinitive) form with "…" for the object ("to wish for …", "to turn away from …"). You may add at most 2 very common missing prepositions with "added": true. Return [] if none apply.

"examples"
9. Translate each Arabic example sentence into natural, faithful {lang}, in the same order, one string per sentence. A sentence may use a different person, tense or form of the word than the headword: translate the sentence as it is. Keep proper names. Render religious terms the way {lang}-speaking Muslims usually do (keep "Allah").

Return only JSON that matches the schema."""

SYSTEM_ARABIC_V2 = """You are a senior Arab lexicographer writing a concise modern Arabic–Arabic learner's dictionary (معجم عربي–عربي ميسّر) for the app "Kavaid". Write everything in clear Modern Standard Arabic. Vowel the words a learner could misread.

You receive a JSON array of Arabic headwords. Each entry has an "id", the vowelled headword (it may be an inflected form: a plural, a case-marked noun, a conjugated verb, a word with an attached pronoun or preposition, or a multi-word phrase), its root, part of speech, plural, verb forms, the prepositions the editors listed, the Arabic example sentences and English hint meanings (use them only to see which senses are meant).
{pos_note}

Return {{"items": [...]}} with exactly one item per entry, with the same "id", in the same order. Treat every entry independently.

Fields
- "sh" (الشرح): one or two short sentences explaining the headword's meaning in the form shown. Never define the word by itself or by a single word from the same root. Separate distinct senses with «؛».
- "syn" (المرادفات): 2–6 synonyms. Each one is a single real word (or a fixed two-word phrase) in common modern use, with the same sense and part of speech as the headword (a verb gets verbs, a plural gets plurals), vowelled. Fewer is better than wrong.
- "ant" (الأضداد): 0–3 antonyms with the same rules. Return [] when there is no natural antonym.
- "note" (ملاحظة): at most 20 words of usage help ONLY: a common collocation or idiom with the word, or another notable sense. Never mention plural, singular, feminine, root, pattern, verb form, bāb, iʿrāb or any other grammar. Empty string if there is nothing useful.
- "preps": for each preposition the editors listed, the meaning with it as a short Arabic explanation («رَغِبَ فِيهِ: أَحَبَّهُ وَأَرَادَهُ»). You may add at most 2 very common missing prepositions with "added": true. Return [] if none apply.

Accuracy rules
- Words spelled alike but vowelled differently are different words (دِين religion, دَيْن debt; آذَان ears, أَذَان call to prayer). Explain only the vowelled headword given; never mix in the other word's meanings or synonyms.
- Never output Turkish or English words, and no Latin letters.
- Write original wording; do not copy published dictionaries.

Return only JSON that matches the schema."""


def _items_schema(item_schema):
    item = {
        'type': 'OBJECT',
        'properties': {'id': {'type': 'INTEGER'}, **item_schema['properties']},
        'required': ['id', *item_schema['required']],
    }
    return {
        'type': 'OBJECT',
        'properties': {'items': {'type': 'ARRAY', 'items': item}},
        'required': ['items'],
    }


SCHEMA_TRANSLATION_V2 = _items_schema(SCHEMA_TRANSLATION)
SCHEMA_ARABIC_V2 = _items_schema(SCHEMA_ARABIC)


def word_payload_v2(pid, rec, hint=None):
    """Kelime verisi + id. hint verilirse Türkçe anlamların yerine İngilizce ipucu konur."""
    p = word_payload(rec)
    entry = {'id': pid, **{k: v for k, v in p.items()
                           if k not in ('turkish_meanings', 'turkish_preposition_meanings')}}
    if hint is None:
        entry['hint_meanings'] = p['turkish_meanings']
        entry['hint_preposition_meanings'] = p['turkish_preposition_meanings']
    else:
        entry['hint_meanings'] = ', '.join(hint.get('senses', []))
        entry['hint_preposition_meanings'] = {q['h']: ', '.join(q['m']) for q in hint.get('preps', [])}
    return entry


DATA_CHECK_RULE = """

"data_issue"
10. Set "data_issue" to true only when the editors' data is inconsistent with the vowelled headword: the example sentences use a different word or a different meaning, the hint meanings belong to another word, or the part of speech is clearly wrong. Otherwise false. Still translate the entry as well as you can."""


def with_data_check(system, schema):
    """İsteme ve şemaya veri hatası işaretini (data_issue) ekler; kaynak veriyi temizlemek için."""
    system = system.replace('\n\nReturn only JSON that matches the schema.',
                            DATA_CHECK_RULE + '\n\nReturn only JSON that matches the schema.')
    item = json.loads(json.dumps(schema['properties']['items']['items']))
    item['properties']['data_issue'] = {'type': 'BOOLEAN'}
    item['required'].append('data_issue')
    return system, {'type': 'OBJECT', 'properties': {'items': {'type': 'ARRAY', 'items': item}}, 'required': ['items']}


def build_batch_request(entries, lang, thinking_level, data_check=False):
    """entries: [(pid, rec, hint_or_None)] -> tek generateContent gövdesi."""
    hint_lang = 'Turkish' if all(h is None for _, _, h in entries) else 'English'
    if lang == 'ar':
        system = SYSTEM_ARABIC_V2.format(pos_note=POS_NOTE)
        schema = SCHEMA_ARABIC_V2
    else:
        system = SYSTEM_TRANSLATION_V2.format(lang=LANG_NAMES[lang], hint_lang=hint_lang, pos_note=POS_NOTE)
        schema = SCHEMA_TRANSLATION_V2
    if data_check:
        system, schema = with_data_check(system, schema)
    payload = [word_payload_v2(pid, rec, hint) for pid, rec, hint in entries]
    return {
        'systemInstruction': {'parts': [{'text': system}]},
        'contents': [{'role': 'user', 'parts': [{'text': json.dumps(payload, ensure_ascii=False)}]}],
        'generationConfig': {
            'responseMimeType': 'application/json',
            'responseSchema': schema,
            'thinkingConfig': {'thinkingLevel': thinking_level},
        },
    }
