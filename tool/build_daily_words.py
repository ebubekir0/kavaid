"""Ana sayfadaki "Günün Kelimesi" için küratörlü kelime listesini üretir.

Kullanım (proje kökünden):
    python tool/build_daily_words.py [kaynak.json]

Kaynak varsayılan olarak SON_GUNCEL_VERITABANI_V2.json'dur. Üretilen dosya:
  - assets/data/gunun_kelimeleri.json

Sözlükte 55 bin kayıt var ama çoğu çekimli biçim ("الْكِتَابِ"), cümle ya da
nadir kelime; ayrıca yapay zekâ üretimi kayıtlarda hatalı yazım, kök ya da anlam
olabiliyor. Bu yüzden kelimeleri otomatik seçmek yerine aşağıdaki NOUNS ve VERBS
listelerini elle tutuyoruz (gündelik, sık kullanılan, öğrenmesi güzel kelimeler).
Betik her kelime için sözlükteki temel biçimi bulur ve anlam / örnek cümleyi
oradan alır; böylece kart, aramada çıkan kayıtla birebir aynı olur.

Listeye kelime eklemek için harekesiz yazımını ekleyin. Bir kelime sözlükte yoksa
ya da kaydı hatalıysa (yanlış harekeli yazım, yanlış kök, anlam tutmuyor) atlanır
ve "eksik" olarak raporlanır; EXCLUDE'a eklenenler hiç denenmez.

Sonuç sabit bir tohumla karıştırılır; aynı girdi her zaman aynı dosyayı üretir.
"""
import json
import random
import re
import sys

SOURCE = sys.argv[1] if len(sys.argv) > 1 else 'SON_GUNCEL_VERITABANI_V2.json'
OUT = 'assets/data/gunun_kelimeleri.json'
SEED = 2026

# İsim ve sıfatlar: tanvinli ("كِتَابٌ") ya da yalın ("أَبْيَضُ") temel biçimleri aranır.
NOUNS = """
أب أم ابن أخ أخت جد زوج امرأة طفل ولد صديق معلم طالب طبيب ملك رسول نبي ضيف جار عدو سيد
عبد قوم أهل رأس وجه عين أذن أنف فم لسان قلب صدر ظهر بطن شمس قمر نجم سماء أرض بحر نهر
جبل شجرة زهرة نبات ريح مطر ثلج نار نور ليل نهار صباح مساء شهر أسبوع يوم وقت عام فجر ظل
سحاب تراب حجر رمل ذهب فضة حديد ماء هواء بحيرة غابة صحراء جزيرة أسد فيل حصان جمل كلب
قطة طير سمكة حمار بقرة غنم ذئب ثعلب نحلة عصفور حمامة بيت باب نافذة غرفة مفتاح كرسي
طاولة سرير كتاب قلم ورقة حقيبة سيارة طريق شارع مدينة قرية سوق مسجد مدرسة جامعة مستشفى
مطار حديقة بلد وطن خبز لحم لبن تمر عسل زيت ملح سكر فاكهة تفاح موز طعام شراب قهوة شاي
حياة موت علم عمل حب سلام حرب خير شر حق أمل خوف فرح حزن قوة صبر عدل ظلم حرية فكرة سؤال
جواب كلمة لغة اسم قصة حلم سر قدر عقل نفس رحمة نعمة أمانة ثقة صدق جمال مال تجارة سفر
رحلة لون صوت شكل ضوء قصر جسر برج ميدان متجر مكتبة مكتب مصنع شركة مطعم فندق محطة قطار
طائرة سفينة دراجة هاتف رسالة صورة خريطة هدية حفلة لعبة رياضة كرة فريق نجاح فشل سعادة
صحة مرض دواء جسم دم عظم جلد قدم إصبع شفة رقبة كتف ركبة عشب ثمرة غيمة برق رعد عاصفة
موج شاطئ سهل وادي تل كهف طين أمس غد دقيقة لحظة موسم شتاء صيف ربيع خريف سبب نتيجة
مشكلة حل فرصة تجربة هدف خطة قرار نظام قانون دولة شعب حكومة رئيس وزير جيش سلاح جندي
كبير صغير جميل طويل قصير جديد قديم قوي ضعيف سريع بطيء سهل صعب حار بارد غني فقير سعيد
حزين صادق كريم شجاع قريب بعيد واسع ضيق ثقيل خفيف نظيف مفتوح مغلق كثير قليل أبيض أسود
أحمر أخضر أزرق أصفر ذكي شاب عجوز مريض سليم مهم مشهور معروف مفيد خطير آمن عادل حر مشغول
فارغ ممتلئ رخيص غال مرتفع منخفض عميق عريض رقيق ناعم خشن حلو مالح طازج
""".split()

# Fiiller: 3. tekil geçmiş zaman ("كَتَبَ") biçimleri aranır.
VERBS = """
كتب قرأ ذهب أكل شرب نام قام جلس دخل خرج فتح أغلق سمع رأى قال فعل أخذ أعطى وجد علم فهم
سأل أجاب لعب درس سافر رجع وصل بدأ انتهى أحب كره ضحك بكى مشى ركض وقف ساعد ترك حمل بنى
كسر قطع غسل لبس سكن عاش مات نظر طلب شكر حفظ فكر تذكر نسي قرر اشترى باع دفع ربح خسر زار
التقى انتظر أرسل استخدم حاول نجح فاز صعد نزل سقط طار سبح ضرب رمى جمع زاد نقص بقي غاب
ظهر ضاع شعر نجا هرب خاف تعب استراح شفي كبر تعلم شرح رسم غنى رقص صلى صام دعا
""".split()

# Sözlük kaydı hatalı olduğu için bilerek dışarıda bırakılanlar (gözle incelendi):
#   يد (kök "يدد"), بنت (kök "بنت"), جاء (kök "جيا"), حب/حلم/شعب/روح/معلم/طالب/ساعة
#   (harekeli yazım ya da anlam istediğimiz kelimeyle uyuşmuyor), مباراة (yanlış kök),
#   فندق (anlamda "fındık"), عمل (fiil biçimi hatalı).
#   جار/جمال/مال/عبد/حل/قدم/جد/خير/عدو/ظلم/قدر/فضة/فعل/سبح/مشكلة (kayıt başka bir kelimeye
#   ait: "جارٍ" akan, "حِلٌّ" helal, "قِدْرٌ" tencere... ya da harekeli/kök yanlış).
# Her gün ana sayfada çıkmasını istemediğimiz ağır konular da (ölüm, savaş, ordu) listede yok.
# Sözlükteki örnek cümlesi dil bilgisi hatalı olanlar da çıkarıldı: دم (جُرِحَ يَدَهُ),
# عميق (هَذَا بِئْرٌ), قوم (هَذَا قَوْمٌ صَالِحُونَ), سلام, قرار (اِتَّخَذَ الْحُكُومَةُ),
# آمن, وقت (لِلْعَبِ), غاب (غَابَ الشَّمْسُ); أب'ın örneği ise bir Kur'an alıntısı.
EXCLUDE = set("""
يد بنت جاء حب حلم شعب روح معلم طالب ساعة مباراة فندق عمل
جار جمال مال عبد حل قدم جد خير عدو ظلم قدر فضة فعل سبح مشكلة
موت مات حرب جيش جندي
دم عميق قوم سلام قرار آمن وقت أب غاب
""".split())

# Sözlükteki karşılığı uzun ya da dağınık olan kelimeler için elle yazılmış kısa anlamlar
GLOSS_OVERRIDES = {
    'أسبوع': 'hafta, yedi günlük süre',
    'مساء': 'akşam, akşam vakti',
}

MARKS = re.compile('[ً-ٰٟـ]')
ARABIC_ONLY = re.compile('^[ء-ي]+$')
DAMMA_ENDINGS = ('ٌ', 'ُ')  # ٌ ُ
KASRATAN = 'ٍ'  # ٍ (sözlükte bazı isimler yalnızca ilgi halinde var)
DAMMATAN = 'ٌ'
FATHA = 'َ'
DAMMA = 'ُ'
SHADDA = 'ّ'
ALEF_MAQSURA = 'ى'
PAST_ENDING = re.compile(r'(dı|di|du|dü|tı|ti|tu|tü)$')
INFINITIVE_ENDING = re.compile(r'(mak|mek)$')


def plain(text):
    return MARKS.sub('', text or '')


def first_mark_after_letter(harekeli):
    """İlk harfin hemen ardındaki hareke (yoksa '')."""
    return harekeli[1] if len(harekeli) > 1 and MARKS.match(harekeli[1]) else ''


def wordkind(entry):
    """'N' (isim/sıfat temel biçimi), 'F' (etken geçmiş fiil temel biçimi) ya da None."""
    harekeli = (entry.get('harekeliKelime') or '').strip()
    tur = (entry.get('dilbilgiselOzellikler') or {}).get('tur', '')
    # "ال" takısı atılmış kalıntılar (ilk harf şeddeli: "طَّعَامُ") temel biçim değildir
    if len(harekeli) > 1 and harekeli[1] == SHADDA:
        return None
    if tur in ('İsim', 'Sıfat', 'Mastar') and harekeli.endswith(DAMMA_ENDINGS + (KASRATAN,)):
        return 'N'
    if tur in ('Mazî Fiil', 'Fiil') and (
        harekeli.endswith(FATHA) or harekeli.endswith(ALEF_MAQSURA)
    ):
        # Edilgen fiiller ("أُكِلَ", "جُمِعَ") ilk harfi dammeli olur
        if first_mark_after_letter(harekeli) == DAMMA:
            return None
        return 'F'
    return None


def first_example(entry):
    for ex in entry.get('ornekCumleler') or []:
        ar = (ex.get('arapcaCümle') or ex.get('arapcaCumle') or '').strip()
        tr = (ex.get('turkceAnlam') or ex.get('turkceCeviri') or '').strip()
        if ar and tr and len(plain(ar).split()) <= 8 and len(tr) <= 70:
            return {'ar': ar, 'tr': tr}
    return None


def build(entry, kind):
    senses = [s.strip() for s in (entry.get('anlamlar') or '').split('||')[0].split(',')]
    senses = [s for s in senses if s]
    if not senses or len(senses[0]) > 30:
        return None
    head = senses[0].lower()
    # Kelimenin temel anlamını taşımayan karşılıklar: belirsiz ("bir oda"),
    # iyelikli ("onun yemeği"), çoğul ("kitaplar")
    if head.startswith('bir ') or 'onun' in head or 'onların' in head:
        return None
    if kind == 'N' and (re.search(r'(lar|ler)$', head) or INFINITIVE_ENDING.search(head)):
        return None
    # Fiilin anlamı geçmiş zaman olmalı ("gitti"); mastar karşılığı ("gitmek") başka bir biçimdir
    if kind == 'F' and not PAST_ENDING.search(head):
        return None
    example = first_example(entry)
    kok = plain(entry.get('koku') or '').strip()
    if example is None or not ARABIC_ONLY.match(kok) or not 3 <= len(kok) <= 4:
        return None
    ar = entry['harekeliKelime'].strip()
    if ar.endswith(KASRATAN):
        ar = ar[:-1] + DAMMATAN  # ilgi hali -> yalın hal ("مَاءٍ" -> "مَاءٌ")
    return {
        'ar': ar,
        'kok': kok,
        'tur': entry['dilbilgiselOzellikler']['tur'],
        'anlam': GLOSS_OVERRIDES.get(plain(ar), ', '.join(senses[:2])),
        'ornek': example,
    }


def main():
    # Windows konsolunda (cp1254) Arapça yazdırabilmek için
    sys.stdout.reconfigure(encoding='utf-8')

    with open(SOURCE, encoding='utf-8') as f:
        records = json.load(f)

    by_plain = {}
    for entry in records:
        word = plain(entry.get('harekeliKelime') or '')
        kind = wordkind(entry)
        if kind and ARABIC_ONLY.match(word):
            by_plain.setdefault(word, []).append((kind, entry))

    picked, missing, seen = [], [], set()
    for kind, words in (('N', NOUNS), ('F', VERBS)):
        for word in words:
            if word in EXCLUDE or word in seen and kind == 'N':
                continue
            seen.add(word)
            # Yalın hal (ٌ) varsa ilgi halinden (ٍ) önce gelir
            options = sorted(
                by_plain.get(word, []),
                key=lambda ke: ke[1]['harekeliKelime'].strip().endswith(KASRATAN),
            )
            found = next(
                (b for k, e in options if k == kind and (b := build(e, kind))),
                None,
            )
            if found:
                picked.append(found)
            else:
                missing.append(f'{word}:{kind}')

    # Aynı kelime (yazım) ya da aynı kök iki kez çıkmasın; çeşitlilik için kök başına
    # en fazla iki kelime
    unique, per_root = [], {}
    for item in picked:
        if per_root.get(item['kok'], 0) >= 2:
            continue
        if any(plain(u['ar']) == plain(item['ar']) for u in unique):
            continue
        per_root[item['kok']] = per_root.get(item['kok'], 0) + 1
        unique.append(item)

    random.Random(SEED).shuffle(unique)
    print(f'{len(unique)} kelime yazıldı, {len(missing)} eksik')
    print('eksik:', ' '.join(missing))

    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(unique, f, ensure_ascii=False, indent=0, separators=(',', ':'))
        f.write('\n')


if __name__ == '__main__':
    main()
