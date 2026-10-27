"""Yerelleştirme pilotu için istemler ve çıktı şemaları.

Çeviri dilleri (en, id, ur, fr...) tek bir İngilizce istemi {lang} ile paylaşır;
Arapça–Arapça (ar) için ayrı bir istem vardır. Talimatlar sistem mesajında,
kelime verisi kullanıcı mesajında JSON olarak gider.
"""
import json

LANG_NAMES = {
    'en': 'English',
    'id': 'Indonesian',
    'ms': 'Malay',
    'ur': 'Urdu',
    'fr': 'French',
    'ru': 'Russian',
    'bn': 'Bengali',
    'de': 'German',
}

POS_NOTE = (
    'part_of_speech uses Turkish grammar terms: "İsim" noun, "Sıfat" adjective, '
    '"Zarf" adverb, "Mastar" verbal noun (masdar), "Mazî Fiil" past-tense verb, '
    '"Muzari Fiil" present-tense verb, "Emir Fiil" imperative, "Meçhul" passive, '
    '"Nehiy" prohibition, "İsm-i Fail" active participle, "İsm-i Mef\'ul" passive '
    'participle, "İsm-i Tafdil" elative, "İsim Tamlaması" construct phrase, '
    '"Harf-i Cerli" with an attached preposition, "Edat"/"Harf" particle, '
    '"Deyim" idiom, "Özel İsim" proper noun, "Çoğul" plural. If the label '
    'conflicts with the Arabic form, trust the Arabic form.'
)

SYSTEM_TRANSLATION = """You are a senior Arabic lexicographer writing entries for an Arabic–{lang} learner's dictionary (the app "Kavaid"). Its users learn Modern Standard and Classical/Quranic Arabic. Accuracy matters more than coverage.

You receive one Arabic headword as JSON: the vowelled headword (it may be an inflected form: a plural, a case-marked noun, a conjugated verb, a word with an attached pronoun or preposition, or a multi-word phrase), its root, part of speech, plural, verb forms, the prepositions the editors listed, the Arabic example sentences and the Turkish meanings written by the Turkish editors.
{pos_note}

"senses"
1. Translate the headword in exactly the form shown. A plural stays plural, a word with an attached pronoun keeps it ("your book"), a noun with an attached preposition keeps it ("with joy"), a passive stays passive.
2. Verbs: translate the exact conjugation. For third person masculine singular give the plain form without a pronoun ("surrounded, encircled" / "deals with, interacts"); for other persons include the pronoun ("you opened", "they help"). Only gender or number markers may be added in parentheses: (f.), (pl.), (dual).
3. Order from the most common Modern Standard Arabic meaning to less common or classical ones. Usually 3–8 senses, never more than 12. Do not invent rare meanings.
4. Each sense is a short gloss of 1–4 words. No numbering, no explanations.
5. The Turkish meanings show which senses the editors meant. Use them only to choose senses. Do not translate Turkish idioms, and drop any Turkish sense that does not fit the Arabic word.
6. Words spelled alike but vowelled differently are different words (دِين religion, دَيْن debt). Translate only the vowelled headword given.
7. Use standard {lang} spelling.

"preps"
8. For each preposition the editors listed, give what the word means with it, as 1–3 short glosses in the base (infinitive) form with "…" for the object ("to wish for …", "to turn away from …"). You may add at most 2 very common missing prepositions with "added": true. Return [] if none apply.

"examples"
9. Translate each Arabic example sentence into natural, faithful {lang}, in the same order, one string per sentence. Keep proper names. Render religious terms the way {lang}-speaking Muslims usually do (keep "Allah").

Return only JSON that matches the schema."""

SYSTEM_ARABIC = """You are a senior Arab lexicographer writing a concise modern Arabic–Arabic learner's dictionary (معجم عربي–عربي ميسّر) for the app "Kavaid". Write everything in clear Modern Standard Arabic. Vowel the headword-related words you mention and any word a learner could misread.

You receive one Arabic headword as JSON: the vowelled headword (it may be an inflected form: a plural, a case-marked noun, a conjugated verb, a word with an attached pronoun or preposition, or a multi-word phrase), its root, part of speech, plural, verb forms, the prepositions the editors listed, the Arabic example sentences and Turkish meanings (use them only as a hint of which senses are meant).
{pos_note}

Fields
- "sh" (الشرح): one or two short sentences explaining the headword in the form shown (for an inflected form, name the form and explain it, e.g. «جَمْعُ عِقَابٍ، وَهُوَ ...»). Never define the word by itself or by a single word from the same root. Separate distinct senses with «؛».
- "syn" (المرادفات): 2–6 real synonyms in common use, vowelled, most common first. Single words or two-word phrases only.
- "ant" (الأضداد): 0–4 antonyms, vowelled. Return [] when there is no natural antonym.
- "note" (ملاحظة): at most 25 words of usage help: another notable sense, a common collocation, or the plural given in the input. Empty string if there is nothing useful.
- "preps": for each preposition the editors listed, the meaning with it, written as a short Arabic explanation («رَغِبَ فِيهِ: أَحَبَّهُ وَأَرَادَهُ»). You may add at most 2 very common missing prepositions with "added": true. Return [] if none apply.

Accuracy rules
- Never invent forms. Mention a plural, feminine, masdar or pattern only if it is given in the input (plural, verb_forms) or is a well-known form you are certain of. When unsure, leave it out.
- Do not add grammatical analysis (person, verb pattern, bāb, iʿrāb) unless you are certain of it. Wrong grammar is worse than no grammar.
- Words spelled alike but vowelled differently are different words (دِين religion, دَيْن debt; عِلْم knowledge, عَلَم flag). Explain only the vowelled headword given; never mix in the other word's meanings, synonyms or prepositions.
- Synonyms and antonyms must match the headword's main sense and part of speech (a verb gets verbs, a plural gets plurals).

Write original wording; do not copy published dictionaries. No Latin letters. Return only JSON that matches the schema."""

SCHEMA_TRANSLATION = {
    'type': 'OBJECT',
    'properties': {
        'senses': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
        'preps': {
            'type': 'ARRAY',
            'items': {
                'type': 'OBJECT',
                'properties': {
                    'h': {'type': 'STRING'},
                    'm': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
                    'added': {'type': 'BOOLEAN'},
                },
                'required': ['h', 'm', 'added'],
            },
        },
        'examples': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
    },
    'required': ['senses', 'preps', 'examples'],
}

SCHEMA_ARABIC = {
    'type': 'OBJECT',
    'properties': {
        'sh': {'type': 'STRING'},
        'syn': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
        'ant': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
        'note': {'type': 'STRING'},
        'preps': {
            'type': 'ARRAY',
            'items': {
                'type': 'OBJECT',
                'properties': {
                    'h': {'type': 'STRING'},
                    'm': {'type': 'STRING'},
                    'added': {'type': 'BOOLEAN'},
                },
                'required': ['h', 'm', 'added'],
            },
        },
    },
    'required': ['sh', 'syn', 'ant', 'note', 'preps'],
}


def split_anlam(anlam):
    """'a, b||HARFI_CER:على=x, y' -> ('a, b', {'على': 'x, y'})."""
    parts = (anlam or '').split('||')
    preps = {}
    for part in parts[1:]:
        part = part.strip()
        if part.startswith('HARFI_CER:') and '=' in part:
            harf, meaning = part[len('HARFI_CER:'):].split('=', 1)
            preps[harf.strip()] = meaning.strip()
    return parts[0].strip(), preps


def word_payload(rec):
    """sozluk.json.gz kaydını modele gidecek sade JSON'a çevirir."""
    gram = rec.get('dilbilgiselOzellikler') or {}
    fiil = rec.get('fiilCekimler') or {}
    meanings, preps = split_anlam(rec.get('anlam'))
    examples = []
    for o in rec.get('ornekCumleler') or []:
        if isinstance(o, dict):
            ar = o.get('arapcaCumle') or o.get('arapcaCümle') or ''
            if ar:
                examples.append(ar)
    verb_forms = {
        k: v for k, v in {
            'past': fiil.get('maziForm'),
            'present': fiil.get('muzariForm'),
            'masdar': fiil.get('mastarForm'),
            'imperative': fiil.get('emirForm'),
        }.items() if v
    }
    payload = {
        'headword': rec.get('harekeliKelime') or rec.get('kelime'),
        'root': rec.get('koku') or '',
        'part_of_speech': gram.get('tur') or '',
        'plural': gram.get('cogulForm') or '',
        'verb_forms': verb_forms,
        'editor_prepositions': list(preps.keys()),
        'examples': examples,
        'turkish_meanings': meanings,
        'turkish_preposition_meanings': preps,
    }
    return payload


def build_request(rec, lang, thinking_level):
    """generateContent REST gövdesi."""
    if lang == 'ar':
        system = SYSTEM_ARABIC.format(pos_note=POS_NOTE)
        schema = SCHEMA_ARABIC
    else:
        system = SYSTEM_TRANSLATION.format(lang=LANG_NAMES[lang], pos_note=POS_NOTE)
        schema = SCHEMA_TRANSLATION
    return {
        'systemInstruction': {'parts': [{'text': system}]},
        'contents': [{
            'role': 'user',
            'parts': [{'text': json.dumps(word_payload(rec), ensure_ascii=False)}],
        }],
        'generationConfig': {
            'responseMimeType': 'application/json',
            'responseSchema': schema,
            'thinkingConfig': {'thinkingLevel': thinking_level},
        },
    }
