# Kavaid Çok Dilli Sözlük — Yerelleştirme Planı

> Hazırlanma: 24 Ekim 2026 · Mevcut sürüm: 4.1.1+5018 · Hedef: 5.x serisi
>
> Amaç: Kavaid'i "Arapça–Türkçe sözlük"ten, Arapça öğrenenlerin en çok olduğu
> dillerde yerel anlam, örnek ve arayüz sunan **çok dilli bir Arapça sözlüğe**
> dönüştürmek. Türkçe kullanıcı deneyimi hiçbir aşamada bozulmayacak.

---

## 0. Kısa özet

| Karar | Öneri |
|---|---|
| Uygulama yapısı | **Tek uygulama** (com.onbir.kavaid), dil başına ayrı mağaza girişi. Ayrı uygulama yok. |
| Dil kavramı | İki ayrı ayar: **Arayüz dili** ve **Anlam dili** (varsayılan: ikisi aynı). |
| Kapsam | Her dilde: Sözlük, Emsile, AI, Çeviri, listeler, Profil/Premium. **Öğren sekmesi yalnız Türkçe; Kuran Sözlüğü şimdilik yalnız Türkçe (karar ertelendi).** (bkz. 3.3) |
| 1. dalga (v5.0) | Türkçe (mevcut) + **İngilizce** + **Arapça–Arapça** |
| 2. dalga (v5.1–5.2) | **Endonezce** (+ Malayca), **Urduca**, **Fransızca** |
| 3. dalga | Bengalce, Rusça, Özbekçe, Azerice, Almanca |
| 4. dalga (talebe göre) | Farsça, Hausa, Svahili, Somalice, Boşnakça, Arnavutça, İspanyolca, Peştuca… |
| Veri dağıtımı | Arapça çekirdek + Türkçe + İngilizce pakette; diğer diller **indirilebilir dil paketi** |
| İçerik üretimi | **Tüm diller sıfırdan**, yeni hatla: pilot → batch → otomatik kontrol → hakem model → insan incelemesi (bkz. 5.1–5.2). Eski İngilizce veri kullanılmaz. |
| Kuran mealleri | **Yapay zekâ ile üretilmez**; lisansı uygun, yerleşik mealler kullanılır |
| Takvim | v5.0 ≈ 7–9 hafta (Ocak 2027 ortası). 2. dalga Ramazan 2027 (≈ 8 Şubat) öncesine yetiştirilmeye çalışılır |

---

## 1. Mevcut durum (kod ve veri incelemesinden)

### 1.1 Uygulama
- Flutter 3.8+, Provider, sqflite, Firebase (RTDB, Firestore, Auth, Storage, Remote Config, Analytics, Crashlytics), RevenueCat, AdMob, Gemini.
- `lib/services/language_service.dart` yalnızca `Locale('tr')` döndürüyor; `isEnglish/isArabic` hep `false`.
  Bu getter'lar ve `LanguageService()` çağrıları **~200 yerde** kullanılıyor (word_card, search_result_card, home_screen, profile, translation_screen…).
- **l10n altyapısı yok.** Eskiden kullanılmayan bir `lib/l10n` (tr/en/ar/**id** ARB) vardı, `bf3f17c` (10 Ekim 2026) ile silindi.
- Arayüzde **~700 tekil kullanıcıya görünen metin** sabit Türkçe yazılmış (çok satırlı metinlerle ~1.000). En yoğun dosyalar: learning_screen, profile_screen, auth_service, email_auth_sheet, custom_words_screen, home_screen, emsile_view, app_intro_screen, subscription_screen, purchase_manager.
- RTL hazırlığı yok: 72 `EdgeInsets.only(left/right)/fromLTRB`, 28 sola/sağa sabit `Alignment`, 32 `Positioned`, 17 `TextAlign.left/right`, 21 yön oku ikonu, 51 açık `TextDirection`. Android manifest'te `supportsRtl` yok, iOS Info.plist'te `CFBundleLocalizations` yok.
- `word_model.dart` içinde not: *"İngilizce/Arapça yerel anlam verileri paket boyutu ve bellek maliyeti nedeniyle kaldırıldı."* → Yeni tasarım **her şeyi pakete gömmemeli**.

### 1.2 Veri envanteri (dil başına çevrilecek hacim)

| Modül | Kaynak | Hacim (Türkçe) | Not |
|---|---|---|---|
| Ana sözlük – anlamlar | `assets/data/sozluk.json.gz` | 54.971 kayıt, ~4,2 M karakter | 14.808 kayıtta `||HARFI_CER:` bölümü |
| Ana sözlük – örnek cümleler | aynı dosya | 109.926 cümle, ~3,4 M karakter | Alan adları karışık: `arapcaCumle/turkceCeviri` ve `arapcaCümle/turkceAnlam` |
| Kelime türleri | `dilbilgiselOzellikler.tur` | ~60+ farklı Türkçe yazım | "İsim", "Mazî Fiil", "İsm-i Fail", "İsim tamlaması"/"İsim Tamlaması"… |
| Emsile | `assets/data/emsile.db` | 5.596 fiil, ~0,48 M karakter anlam + 24 kalıp adı | Kalıp adları Osmanlı medrese terminolojisi |
| Kuran sözlüğü | `quran_sozluk_okunakli.csv` | 25.878 kelime, ~1,6 M karakter anlam + ~59.000 ayet/meal hücresi | **Şimdilik yalnız Türkçe** (karar ertelendi); açılırsa meal lisanslı kaynaktan |
| Kitaplar | `assets/books/*` (35 kitap) | ~75 K karakter kelime-kelime çeviri | **Yalnız Türkçe, çevrilmeyecek** (Öğren sekmesi) |
| Kitab'ul Kıraat 1–3 | `lib/data/books/*.dart` | ~560 KB | **Yalnız Türkçe, çevrilmeyecek** |
| Dersler | learning_screen, book_lessons_service | ~135 KB kaynak | **Yalnız Türkçe, çevrilmeyecek** |
| Günün kelimeleri | `gunun_kelimeleri.json` | 68 KB | Küçük |
| AI istemleri | gemini_service, ai_chat, ai_teacher, dialect_translation | — | Türkçe çıktı varsayıyor |

### 1.3 Elde hazır olanlar
- Eski İngilizce veri (`ANLAM_BATCH_SONUCLAR_EN.jsonl`, `ORNEK_EN_BATCH_SONUCLAR.jsonl`; flash-lite ile üretilmişti) **kullanılmayacak**. 24 Ekim 2026'da Windows geri dönüşüm kutusuna taşındı. İngilizce dahil tüm diller yeni hatla sıfırdan üretilir. `tool/extract_en_data.py` bu yüzden artık işe yaramıyor.
- Eski hat (`generate_*_batch.py`, `run_batch_auto.py`, `check_batch.py`): tek kelime = tek istek, Türkçe istem, Gemini 3 Flash, AI Studio'ya elle yükleme. Yeni hat bunun yerine geçer (bkz. 5.2).
- Eski batch anahtarları `word_9400` gibi sıra numarasına dayalıydı → kalıcı kelime kimliği şart (bkz. 4.4).
- **Güvenlik:** `tool/run_batch_auto.py`, `tool/check_batch.py`, `tool/gemini_enricher.py`, `tool/test_sadece_anlam.dart` içinde Gemini API anahtarı açık yazılı ve git ile GitHub'a (`ebubekir0/kavaid`) gönderilmiş. Anahtar yenilenmeli; yeni hat anahtarı ortam değişkeninden okur.
- Türkçe kaynak anlamlar temiz: kelime başına ortanca 4, en fazla 8 anlam. Başlıkların bir kısmı çekimli biçim (ör. أَمْرٍ, عِقَابَاتٌ) → hedef dilde de çekimli karşılık gerekir ("a matter", "penalties").
- Play Console'da en-US (Arapça–İngilizce) ve ar (Arapça–Arapça) mağaza metinleri **taslak** olarak bekliyor (`store_listing/en-US.txt`, `ar.txt`). Uygulama yerelleşince yayınlanacak.

---

## 2. Hedef diller ve önceliklendirme

### 2.1 Puanlama ölçütü
Her dil için: **Talep** (Arapça öğrenen kitle × akıllı telefon/Play erişimi) × **Gelir** (ARPU, Play/App Store ödeme altyapısı, reklam eCPM) ÷ **Maliyet** (AI çeviri kalitesi, yazı sistemi/RTL zorluğu, inceleyici bulma) ± **Rekabet** ve **eldeki hazır veri**.

> Karar vermeden önce kendi verimizle doğrulama: Play Console → İstatistikler (ülke/dil bazında yükleme),
> Firebase Analytics ülke dağılımı, Play "Arama terimleri" raporu, Google Trends ("kamus arab", "عربی اردو لغت",
> "dictionnaire arabe", "arabic dictionary") ve rakip uygulamaların yorum sayıları.

### 2.1.1 Play Store talep ölçümü (25 Ekim 2026)
Yöntem: her dilde 3 arama (sözlük, çevirici, "Arapça öğren"; o ülkenin mağazası), her aramanın ilk 10 uygulaması.
Yalnız başlığında hem "Arapça" hem o dil geçen uygulamalar sayıldı; 4+ dilde çıkan küresel uygulamalar, klavyeler ve
Google Translate gibi genel çeviriciler hariç. Sayı = indirme alt sınırlarının toplamı (1M+ → 1M). Kavaid bugün 10K+.

| Sıra | Dil | Toplam | ≥100K uygulama | Öne çıkanlar / not |
|---|---|---|---|---|
| 1 | Fransızca | 3,7M | 6 | Fransızca öğrenen Araplar da dahil; Batı Afrika ve Mağrip |
| 2 | İngilizce | 3,6M | 4 | İngilizce öğrenen Araplar da dahil |
| 3 | Endonezce | 3,4M | 6 | Kamus Arab Indonesia 1M+; 41 bin pesantren, Arapça müfredatta |
| 4 | Bengalce | 3,2M | 6 | Bangla Arabic Dictionary 1M+; ~4M Alia + 1,4M Kavmi medrese öğrencisi |
| — | Türkçe (kıyas) | 1,7M | 3 | Kavaid'in bugünkü pazarı |
| 5 | Malayca | 1,3M | 4 | Malezyalılar Endonezce uygulamaları da kullanıyor |
| 6 | Urduca | 1,25M | 8 | En çok sayıda orta boy uygulama; Pakistan'da 2,2M kayıtlı medrese öğrencisi |
| 7 | Hintçe | 1,1M | 6 | Learn Arabic From Hindi 500K+; Hindistan Müslümanları |
| 8 | Hausa | 1,1M | 1 | Tek uygulama 1M+; Kuzey Nijerya, ~10M almajiri tahmini |
| 9 | Özbekçe | 0,8M | 3 | |
| 10 | Farsça | 0,5M | 5 | İran'da Play yok; Afganistan |
| 11 | Rusça | 0,5M | 4 | Rusya'da Play ödemesi Mart 2022'den beri kapalı |
| 12+ | İspanyolca 0,36M · Svahili 0,24M · Malayalam 0,22M · Almanca 0,21M · Somalice 0,18M · Tamilce 0,17M · Peştuca 0,12M | | | |
| — | Azerice 0,02M · Tacikçe, Kazakça, Boşnakça ≈0 | | | Talep yok denecek kadar az |

Sonuç: anlam üretimi için ilk grup id, bn, ur, fr, en (+ ar–ar); ikinci grup ms, hi, ha, uz; sonra ru, fa.
de ve az yalnız arayüz (az → Türkçe anlam, de → İngilizce anlam).

### 2.2 Dalga tablosu

| Dalga | Dil (kod) | Ana pazarlar | Neden | Zorluk | Gelir notu |
|---|---|---|---|---|---|
| — | Türkçe (tr) | TR, Avrupa diasporası | Mevcut | — | Mevcut |
| **1** | İngilizce (en) | ABD, BK, Kanada, Avustralya, Hindistan, Pakistan, Nijerya, Malezya… | Küresel ortak dil; mühtediler, diaspora, Güney Asya ve Afrika'da İngilizce kullananlar. Anlamlar **hazır**. | Düşük | En yüksek ARPU |
| **1** | Arapça (ar) — *Arapça–Arapça* | Suudi Arabistan, Körfez, Mısır, Mağrip, Levant | Ana dili Arapça olanlar tek dilli sözlük (şerh) kullanır; öğrenciler. Mağaza taslağı hazır. Lehçe çeviri özelliğiyle güçlü sinerji. | Orta-Yüksek (RTL, çeviri değil **tanım** üretimi) | Körfez'de yüksek ARPU; rekabet yoğun |
| **2** | Endonezce (id) | Endonezya | Dünyanın en kalabalık Müslüman nüfusu; pesantren/medrese geleneğinde Arapça öğrenimi çok yaygın; Latin alfabesi, RTL yok. | Düşük | Düşük ARPU, yüksek hacim → reklam + uygun fiyat |
| **2** | Malayca (ms) | Malezya, Brunei, Singapur | Endonezceden türetilip ayrı incelenir (kelime farkları var). | Düşük | Orta ARPU |
| **2** | Urduca (ur) | Pakistan, Hindistan, Körfez'deki işçiler, BK | Çok büyük medrese kitlesi (Dars-ı Nizamî). | Yüksek (RTL + Nastaʿlīq yazı, aramada Arap harfi çakışması) | Düşük ARPU, yüksek hacim |
| **2** | Fransızca (fr) | Fransa/Belçika diasporası, Senegal, Mali, Gine, Nijer, Fildişi, Mağrip | Batı Afrika'da dinî Arapça öğrenimi; Fransa'da yüksek ARPU'lu diaspora. | Düşük | Orta-yüksek |
| 3 | Bengalce (bn) | Bangladeş, Batı Bengal | Kavmi/Alia medreseleri; çok büyük kitle. | Orta (Bengal yazısı, font) | Düşük ARPU |
| 3 | Rusça (ru) | Rusya Müslümanları (Tataristan, Kafkasya), Orta Asya | Arapça öğrenimine ilgi yüksek. | Düşük-orta | **Rusya'da Google Play ödemeleri ve Google reklamları 2022'den beri kısıtlı**; gelir Orta Asya/Kafkasya dışı kullanıcılardan |
| 3 | Özbekçe (uz), Azerice (az) | Özbekistan, Azerbaycan | Türk dilleri: **Türkçe anlamlardan yüksek kaliteyle uyarlanabilir**, ucuz. | Düşük | Düşük-orta |
| 3 | Almanca (de) | Almanya, Avusturya, İsviçre | Diaspora, mühtediler, akademi. | Düşük | Yüksek ARPU |
| 4 | Farsça (fa) | İran, Afganistan (Dari), Tacikistan | İran'da okullarda Arapça zorunlu → talep yüksek. | Orta (RTL) | **İran'da Google Play/App Store ödemesi yok** (yaptırımlar); dağıtım kısıtlı |
| 4 | Hausa (ha), Svahili (sw), Somalice (so) | Nijerya/Nijer, Doğu Afrika, Somali | Büyük Müslüman nüfus, güçlü Kur'an eğitimi. | Yüksek (AI kalitesi düşük, inceleyici zor) | Düşük ARPU |
| 4 | Boşnakça (bs), Arnavutça (sq) | Balkanlar, diaspora | Türk–Balkan bağı, küçük ama sadık kitle. | Orta | Orta |
| 4 | İspanyolca (es), Peştuca (ps), Kazakça (kk), Hintçe/Malayalam (hi/ml) | — | Talebe göre. | — | — |

Çin (Hui Müslümanları) Google Play erişimi olmadığı için kapsam dışı.

---

## 3. Ürün kararları

### 3.1 Arayüz dili ≠ Anlam dili
- **Arayüz dili** (`uiLocale`): menüler, butonlar, mesajlar.
- **Anlam dili** (`meaningLocale`): kelime anlamı, örnek cümle çevirisi, emsile anlamları, AI cevap dili.
- Varsayılan: cihaz dili desteklenen dillerdense ikisi de o; değilse arayüz **İngilizce**, anlam **İngilizce**.
- Örnek: Pakistanlı kullanıcı arayüzü İngilizce, anlamları Urduca isteyebilir; Arap kullanıcı Arapça arayüz + Arapça şerh ister.
- Ayar ekranında iki seçim + ilk açılışta tek adımlı "Dilini seç" ekranı (tanıtım ekranından önce).
- Anlam dili paketi henüz yoksa: Türkçe gösterme, **İngilizce'ye düş** ve "Urduca paketi hazırlanıyor" bilgisini göster.

### 3.2 Mevcut Türkçe kullanıcılar
- Güncelleme alan kullanıcıda (is_first_launch = false) dil **tr olarak sabitlenir**, cihaz dili ne olursa olsun.
- Türkçe veri pakette kalır; çevrimdışı çalışma aynen sürer.
- YDS gibi Türkiye'ye özgü içerik yalnızca tr'de görünür.

### 3.3 Kesinleşen kapsam (24 Ekim 2026)
Kural: bir bölümün o dilde içeriği yoksa **Türkçe içerik gösterilmez**, bölüm görünmez. Bölüm bayrakları Remote Config'de `modules_<lang>` ile yönetilir.

**Her dilde olacak bölümler** (v5.0'da en + ar; sonraki diller aynı şablonla):

| Bölüm | İngilizce (ve diğer çeviri dilleri) | Arapça–Arapça | Not |
|---|---|---|---|
| Sözlük: arama + kelime kartı | Anlam, harf-i cer anlamları, örnek cümle çevirisi | **Şerh + eş anlamlılar + zıt anlamlılar + kullanım notu**; örnek cümleler çevirisiz | Arapça kartın şeması için bkz. 5.4 |
| Kelime türü, çoğul, fiil çekim etiketleri | ✅ | ✅ | Terim sözlüğünden (5.3) |
| Emsile modu | ✅ "Verb conjugation (taṣrīf)" | ✅ "تصريف الأفعال" | 5.596 fiilin anlamları + 24 kalıp adı |
| AI: eksik kelimeyi bulma, kartta "AI'a sor" | ✅ | ✅ | **Türkçedeki kurallar aynen**: giriş şartı + kredi/kota. Cevap dili = anlam dili |
| Çeviri sekmesi | ✅ | ✅ | Hedef dil listesi zaten çok dilli (17 Arapça lehçe + 12 dil); yalnız arayüz ve istemler |
| Kelime listelerim / kaydedilenler | ✅ | ✅ | Yalnız arayüz |
| Profil, giriş, Premium, satın alma, hesap silme | ✅ | ✅ | Ürün adları mağazada dil başına |
| Tanıtım ekranı, kampanya/promo, değerlendirme isteği | ✅ | ✅ | Tanıtım görselleri dil başına |

**Yalnızca Türkçede kalacaklar:**
- **Öğren sekmesinin tamamı**: 35 sesli kitap, Kitabü'l Kıraat 1–3 + Taysir Sira, Siyer-i Nebi dersleri, satın alınan kitaplar ekranı. Diğer dillerde sekme hiç görünmez (bugünkü `isEnglish/isArabic` gizlemesi "dil tr değilse gizle" kuralına çevrilir).
- Kitap/ders satın alma ürünleri (`book_store_service`, Siyer) diğer dillerde listelenmez.
- **Kuran Sözlüğü modu (şimdilik)**: diğer dillerde mod seçicide görünmez. Karar ertelendi (24 Ekim 2026); açılırsa nasıl yapılacağı aşağıda ve 5.5'te.
- YDS'ye özgü içerik.
- Admin konsolu ve debug ekranları (hiç çevrilmez).

**Kapsam dışı** (kodda var ama kullanıcıya açılmıyor): AI öğretmen, topluluk sohbeti, oyun, Kuran metni ekranı, `gunun_kelimeleri.json`. İleride açılırlarsa çok dilli altyapıyla açılır.

**Kuran Sözlüğü ileride açılırsa gerekçeler (karar ertelendi):**
1. Öğren çıkınca diğer dillerde Premium'un içeriği Emsile + Kuran Sözlüğü + AI + Çeviri'ye iner; Kuran'ı da çıkarmak Premium'u iyice zayıflatır.
2. Hedef kitlenin (Endonezya, Pakistan, Arap ülkeleri, mühtediler) Arapça öğrenmesinin baş sebebi Kur'an.
3. Play'deki en-US ve ar taslakları Kuran sözlüğünü zaten öne çıkarıyor.
4. Maliyeti düşük: 25.878 kelime anlamı AI + inceleme ile üretilir; Arapçada meal gerekmez. İngilizce meal lisansı v5.0'a yetişmezse ayetler mealsiz gösterilir, takvim kaymaz.

**Bu kararların sonuçları:**
- Ödeme duvarındaki fayda listesi dile göre değişir: Türkçe dışında hikâyeler/dersler yazılmaz.
- Play'deki en-US ve ar taslaklarında "LEARN / قصص" bölümü ve "part of the stories / جزء من القصص" ifadesi var → yayından önce çıkarılmalı (`store_listing/en-US.txt`, `store_listing/ar.txt` ve Play taslağı).
- Kuran ertelendiği sürece taslaklardaki "QURAN DICTIONARY / قاموس القرآن" bölümleri ve kısa açıklamadaki "Quran words / قاموس القرآن" ifadesi de çıkarılmalı.
- Diğer dillerde Premium şunu içerir: sınırsız Emsile + AI + Çeviri, reklamsız kullanım.
- İçerik üretim hacminden kitaplar, Kitabü'l Kıraat ve dersler düşer (yalnız Türkçe).

### 3.4 Marka
- "Kavaid" (قواعد) uluslararası kalır; Arapçada "كوايد" (mevcut taslakta) kullanılıyor.
- Mağaza başlığı dil bazında: "Arabic English Dictionary", "كوايد: قاموس عربي عربي", "Kamus Arab Indonesia – Kavaid", "عربی اردو لغت – Kavaid"… (Play 30 karakter sınırı).

---

## 4. Teknik mimari

### 4.1 Arayüz yerelleştirme (gen-l10n)

**Durum (25 Ekim 2026): kuruldu.** 407 metin `lib/l10n/app_tr.arb`'de; tr + en, ar, id, ms, ur, fr, bn, ru, uz, az, de.
Kod metinlere bağlamsız `l10n.anahtar` ile erişir (`lib/l10n/l10n.dart`, servislerde de çalışır). Araçlar:
`tool/i18n/resolve_lang_ternaries.py` (eski isEnglish/isArabic dallarını tohum olarak topladı),
`extract_ui_strings.py` (metin → ARB + kod değişimi), `fix_const.py`, `rtl_convert.py`,
`translate_arb.py` (gemini-3.1-flash-lite, eksik anahtarları çevirir; en/ar elle gözden geçirildi).
Yeni metin eklerken: `app_tr.arb`'ye ekle → `python tool/i18n/translate_arb.py --langs en,ar,...` → `flutter gen-l10n`.
Arayüz dili profilde "Uygulama dili"nden seçilir; güncelleme alan kullanıcı Türkçe kalır, yeni kurulum cihaz dilini alır.
Kapsam dışı (Türkçe kalır): Öğren sekmesi ve Kuran sözlüğü (Türkçe olmayan arayüzde sekmesi, tanıtım sayfası ve Premium
maddesi gizli), yönetici/hata ayıklama ekranları. Açık iş: tanıtım ekran görüntüleri Türkçe.
- Kelime türü: verideki 500+ Türkçe yazım `lib/utils/word_type_label.dart` ile 27 ortak türe iner (%99,97 kapsama); kartta
  arayüz dilinde kısa etiket. Türkçede 16 karakterden kısa özgün yazım korunur.
- Dar yerler (çip, sekme, emsile başlığı, fiil kutusu): `tool/i18n/ui_max_len.json` azami uzunlukları; `translate_arb.py --refit`
  aşanları yeniden ister. Ayrıca bu etiketler sığmazsa "…" yerine küçülür (FittedBox).
- Emsile: 24 sığa adı sıra numarasından (1–24) yerelleşir. Fiil anlamları Türkçe; **karar (25 Ekim 2026): dil paketinde sözlük anlamından alınacak**
  (5.596 fiilin 4.393'ü sözlükte aynı kelimeyle var), kalan ~1.200 fiilin kısa anlam listesi ayrıca çevrilecek.
- Yapay zekâ (AI asistan, kelime asistanı): istemler Türkçe; sona arayüz diline göre "cevabı X dilinde ver" kuralı eklenir
  (`GeminiService._answerLanguageRule`). Lehçe çevirisinde kaynak dil arayüz dili; okunuş kullanıcının alfabesiyle.
  Uygulamada yapay zekâyla kelime ekleme yok ve olmayacak (kullanıcı kararı, 25 Ekim 2026); `_defaultPrompt` eski yapılandırma kalıntısı.
1. `pubspec.yaml`: `flutter_localizations` ekle, `flutter: generate: true`; `l10n.yaml`:
   ```yaml
   arb-dir: lib/l10n
   template-arb-file: app_tr.arb
   output-localization-file: app_localizations.dart
   nullable-getter: false
   ```
2. Kaynak dil **Türkçe** (`app_tr.arb`), çeviri dosyaları `app_en.arb`, `app_ar.arb`… Her anahtara `@açıklama` (bağlam) yazılır; AI çevirisi ve insan incelemesi bu bağlamla yapılır.
3. Metin çıkarma: yarı otomatik betik (`tool/extract_ui_strings.dart`): `Text('...')`, `SnackBar`, `AlertDialog`, `hintText`, `label`, `tooltip` vb. bulur, anahtar önerir, ARB'ye yazar; değiştirme dosya dosya, ekran ekran incelenerek yapılır. `debugPrint`, admin ve debug ekranları (admin_console, profile_debug_tools, log_screen) **çevrilmez**.
4. Çoğul ve değişkenler ICU formatında: `{count, plural, one{…} other{…}}`; tarih/sayı `intl` ile yerel biçim (Arapça-Hint rakamları kullanıcı tercihine bağlı).
5. Context'siz katmanlar (auth_service, purchase_manager, credits_service hata mesajları) metin değil **hata kodu** döndürür; UI katmanı çevirir. Gerekirse `lookupAppLocalizations(LanguageService().uiLocale)`.
6. CI/ön-commit kontrolü: eksik ARB anahtarı, kullanılmayan anahtar, ICU sözdizimi hatası → derleme kırılır.
7. **Pseudo-locale** (`app_xx.arb`: metinleri %40 uzatıp aksanlı yapar) ile taşma testleri.

### 4.2 LanguageService'in yeniden yazımı
```dart
class LanguageService extends ChangeNotifier {
  Locale uiLocale;            // arayüz
  String meaningLang;         // 'tr', 'en', 'ar', 'id', ...
  bool get isRtl;             // ar, ur, fa, ps
  TextDirection get textDirection;
  Future<void> setUiLocale(Locale l);
  Future<void> setMeaningLang(String code); // paket yoksa indirme akışını tetikler
}
```
- `MaterialApp(locale:, supportedLocales:, localizationsDelegates:, localeResolutionCallback:)`.
- `isTurkish/isEnglish/isArabic` kullanan ~200 yer gözden geçirilir; çoğu `meaningLang` veya `l10n` ile değiştirilir.
- Android 13+ uygulama başına dil: `res/xml/locales_config.xml` + manifest `android:localeConfig`; iOS: `CFBundleLocalizations` + her dil için `InfoPlist.strings` (mikrofon, konuşma tanıma, fotoğraf izin metinleri).

### 4.3 RTL ve tipografi
- Android manifest: `android:supportsRtl="true"`.
- Yön denetimi: `EdgeInsets.only(left:)` → `EdgeInsetsDirectional.only(start:)`, `Alignment.centerLeft` → `AlignmentDirectional.centerStart`, `Positioned(left:)` → `PositionedDirectional(start:)`, `TextAlign.left` → `TextAlign.start`, geri/ileri okları yön duyarlı ikonlar (`Icons.adaptive.arrow_back` veya `Directionality`'ye göre çevirme). Yaklaşık 170 nokta.
- Arapça kelime kartları zaten RTL; **LTR arayüz içinde RTL** (bugün) ve **RTL arayüz içinde LTR** (Arapça arayüzde Latin transliterasyon, sayılar) ayrı ayrı test edilir.
- Arapça Klavye bileşeni: ar/ur/fa kullanıcılarında cihaz klavyesi zaten Arapça harfli → varsayılan kapalı.
- Fontlar:
  | Dil | Arayüz fontu | Not |
  |---|---|---|
  | tr, en, id, ms, fr, de, ru, uz, az | Inter (mevcut; Latin + Kiril) | |
  | ar (arayüz) | Noto Sans Arabic veya IBM Plex Sans Arabic | ScheherazadeNew kelime/ayet için kalır |
  | ur | Noto Nastaliq Urdu | Satır yüksekliği ~2 kat; liste/kart düzenleri ayrıca test |
  | fa | Vazirmatn | |
  | bn | Noto Sans Bengali / Hind Siliguri | |
  Büyük fontlar **dil paketiyle birlikte indirilir** ve `FontLoader` ile çalışma anında yüklenir; APK'ya gömülmez.

### 4.4 Veri modeli ve kalıcı kelime kimliği
1. **Kalıcı kimlik (`wid`)**: 54.971 kaydın her birine bir kez tamsayı kimlik ver ve dondur (`content/master/words.jsonl`). Yeni kelimeler sona eklenir, silinen kimlik tekrar kullanılmaz. Tüm üretim sonuçları sıra numarasına değil bu kimliğe göre eşlenir.
2. **Tür kodları**: `tur` alanındaki ~60 Türkçe yazım ~40 sabit koda indirilir (`ism`, `fiil_mazi`, `fiil_muzari`, `fiil_emir`, `fiil_nehy`, `fiil_mazi_mechul`, `fiil_muzari_mechul`, `masdar`, `sifat`, `zarf`, `harf`, `harf_cer_ism`, `ism_fail`, `ism_meful`, `ism_tafdil`, `ism_tamlamasi`, `ozel_isim`, `deyim`…). Etiketler dil başına terim sözlüğünden gelir; `type_translations.dart` bu sistemle değiştirilir.
3. **Harf-i cer**: `anlam` içindeki `||HARFI_CER:فِي=...` metin kodlaması yapılandırılmış alana taşınır: `preps: [{h: "فِي", m: "..."}]`.
4. **Örnek cümle alan adları** tekleştirilir: `{ar: "...", t: {tr: "...", en: "..."}}` (şu an 4 farklı anahtar yazımı var).
5. **SQLite şeması (v2)**:
   ```sql
   words(id INTEGER PRIMARY KEY, kelime TEXT, harekeli TEXT, kok TEXT, type TEXT,
         cogul TEXT, fiil TEXT /*json*/, examples_ar TEXT /*json*/)
   meanings(word_id INTEGER, lang TEXT, text TEXT, preps TEXT, PRIMARY KEY(word_id, lang))
   example_tr(word_id INTEGER, idx INTEGER, lang TEXT, text TEXT, PRIMARY KEY(word_id, idx, lang))
   lang_packs(lang TEXT PRIMARY KEY, module TEXT, version INTEGER, sha256 TEXT, installed_at INTEGER)
   ```
   `openDatabase(version: 2, onUpgrade: ...)`; mevcut kullanıcıda `words` tablosu çekirdek + tr paketinden yeniden kurulur (zaten `recreateWordsTable` var).
6. **Bellek**: arama önbelleği (`ensureSearchCacheReady`) yalnızca **etkin anlam dilinin** metnini tutar; dil değişince arka planda yeniden kurulur. Önceki girişimin bellek sorununu bu çözer.
7. **Kayıtlı kelimeler / bulut senkronu / özel kelimeler**: anlam metninin kopyası değil `wid` saklanır; ekranda etkin dilde gösterilir. Özel kelimelere `lang` alanı eklenir (kullanıcının yazdığı anlam kendi dilindedir). Mevcut kayıtlar `kelime`/`harekeli` ile `wid`'e eşlenerek taşınır.

### 4.5 Dil paketleri (dağıtım)
```
assets/data/core_v1.json.gz        (pakette)  Arapça çekirdek: kelime, harekeli, kök, tür, çoğul, fiil, Arapça örnekler
assets/data/lang_tr_v1.json.gz     (pakette)  mevcut kullanıcılar ve çevrimdışı
assets/data/lang_en_v1.json.gz     (pakette)  evrensel yedek dil
Firebase Storage: lang/<xx>/dict_v<n>.json.gz, emsile_v<n>, quran_v<n>, daily_v<n>, font_<xx>.ttf
Remote Config: lang_manifest = { "ur": {"dict": {"v":1,"size":3400000,"sha256":"..."}, ...} }
```
- Paket boyutu (25 Ekim 2026 ölçümü, gzip -9): Arapça çekirdek **3,5 MB**, Türkçe anlam paketi **2,9 MB**, İngilizce **2,6 MB** (bugünkü tek parça `sozluk.json.gz` 7,2 MB). Türkçe kullanıcı için çekirdek + tr + en = 9,0 MB (bugüne göre +1,8 MB); diğer diller yalnız seçene iner, dil başına ~2,5–3 MB.
- Test kopyası (yalnız cihazda deneme, mağazaya gitmez): `flutter build apk --release --target-platform android-arm64 --dart-define=MEANING_LANG=en -PuseDebugSigning=true -PtestAppIdSuffix=.entest "-PtestAppLabel=Kavaid EN"`; derlemeden önce `android/app/src/release/google-services.json` içine `.entest` paketli istemci kopyası konur, derlemeden sonra silinir.
- İndirme servisi: kaldığı yerden devam, sha256 doğrulama, düşük alan/ağ hatası, arka planda kurulum, ilerleme çubuğu; indirme bitene kadar İngilizce yedekle çalışır.
- Paket güncellemesi: düzeltilen anlamlar uygulama güncellemesi gerektirmeden yeni paket sürümüyle gelir (manifest sürüm artışı).
- Alternatif (şimdilik önerilmiyor): Play Asset Delivery + iOS On-Demand Resources — Flutter'da daha zahmetli, iki ayrı akış.
- **Uygulanan (27 Ekim 2026):** indirme servisi yerine bütün diller pakette, xz ile (`sozluk.json.xz` 3,9 MB + `assets/data/lang/<dil>.json.xz`); arama, tüm sözlüğü bellekte tutmak yerine diskteki kompakt dizinden çalışır (`SearchStore`, veri sürümü başına bir kez kurulur). Hikâye sesleri pakette değil, Firebase Storage'da kitap başına zip (`audio/<kitap>.zip`, kural: herkes okur, kimse yazamaz); kitap ilk açılınca iner.
- Galaxy A16 ölçümü (release, arm64, Türkçe): soğuk açılışta aramanın hazır olması **4,1–4,5 sn → 1,0–1,3 sn**; bellek (PSS) **447 MB → 297 MB**; arama `ع` 70 → 47–56 ms, `عفا` 29 → 14 ms (sonuç sayıları aynı). Temiz ilk kurulumda süre çoğunlukla veritabanına yazmada: çözme ≈ 2,5 sn, 56 bin satırı SQLite'a yazma ≈ 9–11 sn, arama fihristi ≈ 5–6 sn; sözlük 12,7–14,5 sn, arama 17,8–21,3 sn'de hazır (eski sistem 13 / 17,1 sn). Sözlük bir kez çözülüyor, fihrist veritabanına yazılan listeden kuruluyor (kazanç ≈ 1 sn). Fihristi yazmayla aynı anda kurmak yazmayı 4–7 sn uzattığı için (izoleler çöp toplayıcıyı paylaşıyor) ikisi sırayla yapılıyor. Mağaza indirmesi tahmini ≈ 88 → 39 MB.

### 4.6 Arama
`search_ranking.dart` bugün Türkçeye özgü: `foldTurkishChar`, Türkçe mastar/ünlü uyumu kuralları, Türkçe okunuşa göre Latin→Arapça tahmin. Yeni yapı:
```dart
abstract class MeaningNormalizer {        // saf Dart, arama izolesinde çalışır
  String fold(String input);               // büyük/küçük, aksan, yazı varyantları
  Iterable<String> variants(String token); // basit gövdeleme, durak kelimeler
}
```
| Dil | Kurallar |
|---|---|
| tr | Mevcut kurallar aynen taşınır |
| en | küçük harf, `to `/`a `/`an `/`the ` atma, basit -s/-es/-ed/-ing gövdeleme |
| id/ms | küçük harf, yaygın ekler (me-/ber-/di-/-kan/-an/-nya) için hafif gövdeleme |
| fr | aksan katlama, `le/la/les/l'/un/une/se ` atma |
| de | ä/ö/ü/ß katlama, büyük harf duyarsız |
| ru | ё→е, küçük harf, önek eşleşmesi (çekim zengin) |
| ur/fa | **Arap harfi çakışması**: sorgu Arap yazısındaysa hem Arapça başlıkta hem ur/fa anlamda ara; ی/ي, ک/ك, ہ/ه, ۃ/ة, ے eşitle |
| bn | Bengal yazısı normalize (nukta, zero-width), önek eşleşmesi |
| ar (şerh) | Sorgu zaten Arapça; mevcut harekesiz/kök araması + şerh içinde arama |

- Latin harfli Arapça okunuş tahmini dil başına kural seti alır: İngilizce (sh, kh, th, dh, gh, aa, q), Endonezce (sy, kh, dz, ts, gh), Fransızca (ch, dj, ou), Türkçe (mevcut).
- Konuşarak arama (`speech_to_text`): STT dil kodu `meaningLang`'a göre (`en-US`, `id-ID`, `ur-PK`, `fr-FR`…); Arapça arama için `ar-SA` sabit.

### 4.7 Yapay zekâ özellikleri
- `gemini_service.dart`: istem Türkçe ve çıktı şeması `turkceCeviri` alanlı. Yeni şema dilden bağımsız: `{"meaning": "...", "preps": [...], "examples": [{"ar": "...", "t": "..."}]}`; istem İngilizce yazılır, `TARGET_LANGUAGE = Urdu` gibi parametre alır; dil başına sabit terim sözlüğü istemle verilir.
- AI ile bulunan eksik kelimeler RTDB'de `kelimeler/` altında Türkçe saklanıyor → yeni yol `kelimeler_v2/<normalizeKelime>/core` + `/m/<lang>`; başka dilde istenirse yalnız o dil üretilir ve eklenir. Firestore/RTDB kuralları güncellenir.
- AI sohbet, AI öğretmen: sistem istemine "Kullanıcının dili: {lang}; cevabı bu dilde ver, Arapça örnekleri harekeli yaz". AI öğretmen müfredatı Türk öğrencisine göre → dil başına sadeleştirilmiş müfredat.
- Çeviri ekranı (`dialect_language.dart`): kaynak diller şu an tr/en → id, ur, fr, … eklenir; TTS/STT kodları tabloya.
- Kredi/kota sistemi değişmez; dil başına kullanım analitiği eklenir.
- Not: Küresel açılış kötüye kullanım riskini artırır; AI anahtarının istemcide olması bu dönemde Cloud Functions'a taşınmayı değerlendirmeye değer (ayrı iş).

### 4.8 Firebase, analitik, yapılandırma
- Kullanıcı profiline (Firestore) `uiLocale`, `meaningLang`.
- Analytics kullanıcı özellikleri: `ui_lang`, `meaning_lang`; olaylara `lang` parametresi (`kelime_arama`, `ai_kelime_arama`…). `turkce_analytics_service.dart` → `analytics_service.dart`.
- Crashlytics özel anahtarları: `ui_lang`, `meaning_lang`, `rtl`.
- Remote Config koşulları: dil + ülke (fiyat bandı, reklam sıklığı, modül bayrakları, paket manifesti).

---

## 5. İçerik üretim hattı

### 5.1 İlkeler
- **Her dil sıfırdan üretilir.** Eski İngilizce veri kullanılmaz.
- **Kaynak Arapçadır, Türkçe yalnız ipucudur.** Modele kelimenin Arapça bilgileri verilir: harekeli yazım, kök, tür, çoğul, fiil çekimleri ve Arapça örnekler. Türkçe anlamlar yalnızca "editörlerin seçtiği anlamlar bunlar" diye, anlam ayrımı için eklenir. Türkçeden çeviri yapılmaz.
- **Kelime başına tek istek.** Anlamlar, harf-i cer anlamları ve o kelimenin örnek cümle çevirileri aynı istekte üretilir. Böylece örnek çevirisi verilen anlamla tutarlı olur (eskiden ayrı batch'lerdi).
- **Yapılandırılmış çıktı.** Gemini `response_schema` ile JSON şekli zorlanır; ayrıştırma hatası pratikte sıfıra iner.
- **Kalıcı anahtar.** `custom_id = "<dil>:<wid>"`; sonuçlar sıraya değil kimliğe göre eşlenir.
- **İnsan düzeltmesi korunur.** Elle düzeltilen kayıt `overrides.jsonl` dosyasına yazılır; sonraki üretimler onu asla ezmez.
- **Anahtar güvenliği.** API anahtarı `GEMINI_API_KEY` ortam değişkeninden okunur, koda yazılmaz.

### 5.2 Üretim hattı

#### 5.2.1 Araçlar (`tool/i18n/`)
| Adım | Betik | Ne yapar | Çıktı |
|---|---|---|---|
| 1 | `build_master.py` | `sozluk.json.gz`'deki kelimelere `wid` atar, türleri koda indirir, `\|\|HARFI_CER:` metnini `preps` alanına, örnek anahtarlarını tek biçime çevirir | `content/master/words.jsonl`, `wid_map.json` |
| 2 | `make_batch.py --lang en --set pilot\|all\|ids.txt` | İstem + şema ile batch girdisi üretir | `content/batch/en_<set>.jsonl` |
| 3 | `run_batch.py` | Dosyayı Gemini Files API'ye yükler, batch işini başlatır, durumunu izler, sonucu indirir | `content/raw/en/<iş>.jsonl` |
| 4 | `validate.py --lang en` | Otomatik kontroller (5.2.4); geçenler kabul, kalanlar ret listesine | `content/lang/en/dict.jsonl`, `rejects.jsonl` |
| 5 | `judge.py --lang en` | Hakem model puanlar; düşük puanlıları yeniden üretime yollar | `judge.jsonl`, `requeue.txt` |
| 6 | `review_export.py` / `review_import.py` | İnceleme tablosunu (CSV / Google Sheets) dışa ve içe aktarır | `overrides.jsonl` |
| 7 | `build_pack.py --lang en` | Kabul edilenler + düzeltmeler → dil paketi | `lang_en_v1.json.gz`, sha256, manifest |

`content/` altındaki büyük veri dosyaları git dışında kalır (.gitignore); istemler ve terim sözlükleri git'te tutulur.

#### 5.2.2 İstem tasarımı
**Çeviri dilleri (en, id, ur, fr…)**: İngilizce yazılmış tek istem, `{target_language}` parametresiyle.
- Görev: "Arapça–{dil} öğrenci sözlüğü için madde yaz."
- Anlamlar: Modern Standart Arapçada en yaygından başlayarak sıralanır; 1–4 kelimelik kısa karşılıklar; numara yok; çoğunlukla 3–8, en fazla 12 anlam; uydurma anlam yok.
- Biçim: başlık çekimli biçimse karşılık da öyle olur (عِقَابَاتٌ → "penalties", أَمْرٍ → "a matter"). Fiiller hedef dilin mastar biçimiyle verilir ("to write" / "menulis" / "لکھنا"). Edat ve harfler için işlev açıklaması yazılır.
- Harf-i cer: Türkçe veride geçen her harf için o harfle kazanılan anlam verilir; en fazla 2 ek harf, `added: true` işaretiyle.
- Örnekler: her Arapça cümle doğal ve aslına sadık çevrilir; özel isimler korunur; dinî terimler terim sözlüğüne (5.3) göre yazılır.
- Türkçe ipucu notu: "Bu anlamlar Türk editörlerin seçimidir; yalnızca Arapça kelime için geçerli olanları dikkate al, Türkçe deyimleri aktarma."
- Çıktı şeması:
  ```json
  {"wid": 9400,
   "senses": ["crowd", "congestion", "throng"],
   "preps": [{"h": "عَلَى", "m": ["to crowd around"], "added": false}],
   "examples": ["The market was crowded today.", "..."]}
  ```

**Arapça–Arapça**: ayrı istem (kart içeriği 5.4'te).
- `sh`: 1–2 cümlelik sade fasih tanım. Kelimenin kendisiyle veya aynı kökten tek kelimeyle döngüsel tanım yapılmaz.
- `syn`: 2–6 eş anlamlı (harekeli). `ant`: 0–4 zıt anlamlı. `note`: en fazla 25 kelime (çoğul, diğer anlamlar, sık kalıplar).
- `preps`: harfle değişen anlamın Arapça açıklaması (رَغِبَ فِي: أَحَبَّ / رَغِبَ عَنْ: كَرِهَ).
- Modern sözlüklerden alıntı yapılmaz; ifade özgün olur.

#### 5.2.3 Pilot (tam üretimden önce)
- **İlk tur: 50 kelime** (`tool/i18n/pilot_sample.py`, 24 Ekim 2026'da seçildi): 9 çok anlamlı temel kelime (ذَهَبَ، قَامَ، عَيْنٌ، كِتَابٌ، دِينٌ…) + türlere göre tabakalı 41 kelime (harf-i cerli fiiller, zamirli/çekimli biçimler, meçhul, emir, tamlama, zarf…). Gerekirse ikinci tur 300 kelime.
- **Modeller** (`tool/i18n/pilot_run.py`): `gemini-3.1-flash-lite` düşünme `minimal` ile (eski hattın modeli ve ayarı; yeni istemle ne kadar iyileştiğini görmek için), `gemini-3.5-flash-lite`, `gemini-3.8-flash` ve `gemini-4-argon` düşünme `low` ile. Eski hat (`Desktop\batch`) bütün işleri `gemini-3.1-flash-lite-preview` ile, düşünme `MINIMAL` ve modele yalnız kelimeyi göndererek yapmıştı; asıl zayıflık bu bağlamsız istemdi.
- **İstemler**: `tool/i18n/pilot_prompts.py` — çeviri dilleri için tek İngilizce istem, Arapça–Arapça için ayrı istem, ikisi de yapılandırılmış JSON şemalı. Modele kök, tür, çoğul, fiil çekimleri, harf-i cerler, Arapça örnekler ve Türkçe anlam ipucu gider.
- Pilotun kendi maliyeti (300 istek, standart fiyat): **1 doların altında**.

**Pilot sonucu (24 Ekim 2026, yalnız `gemini-3.1-flash-lite`, 50 kelime; kullanıcı diğer modellerin denenmemesini istedi):**

| Dil / ayar | Ort. girdi | Ort. çıktı | Ort. düşünme | Hata / uyarı | Tam üretim (batch) |
|---|---|---|---|---|---|
| en, `minimal` | 856 | 83 | 0 | 0 / 0 | **≈ $9,3** |
| en, `low` | 856 | 83 | 159 | 0 / 0 | ≈ $15,8 |
| ar, `minimal` | 799 | 288 | 0 | 0 / 0 | ≈ $17,4 |
| ar, `low` | 799 | 265 | 142 | 0 / 0 | **≈ $22,3** |

- **İngilizce**: `minimal` ile `low` neredeyse aynı; anlamlar ve örnek çevirileri Türkçe referansla örtüşüyor. `minimal`'de iki yazım hatası ("innoculated", "subsidance") ve bir fiilde çekim yerine mastar verildi. → **İngilizce için `minimal` yeterli**; yazım denetimi ve "..."→"…" düzeltmesi otomatik kontrole eklenecek.
- **Arapça–Arapça**: `low` dil bilgisinde belirgin şekilde daha doğru (مَسِيرًا مصدر ميمي, قَالَ باب نصر). İki ayar da `note` alanında biçim uyduruyor (أَذْكَى için olmayan dişil/çoğul) ve دِين / دَيْن'i karıştırıyor. → **Arapça için `low`**, ayrıca istem sıkılaştırılmalı: çoğul/dişil yalnız girdide varsa yazılsın, aynı yazılıp farklı harekelenen kelimeler karıştırılmasın; sonra 50 kelime yeniden denenir.
**200 kelimelik pilot (24 Ekim 2026, `gemini-3.1-flash-lite`, istem sıkılaştırıldıktan sonra; 1.200 girdinin hepsi tek tek değerlendirildi — ayrıntı `content/pilot/n200/degerlendirme.md`):**

| Dil | Ayar | Tam üretim (batch) | Doğru | Model kaynaklı yanlış | Karar |
|---|---|---|---|---|---|
| İngilizce | minimal | ≈ $10 | %89 | %1,5 | Yeterli |
| Endonezce | minimal | ≈ $10 | %90,5 | %3 | Yeterli (düzeltmelerle) |
| Malayca | minimal | ≈ $10 | %88,5 | %2,5 | Yeterli |
| Urduca | minimal | ≈ $10 | %87,5 | %3 (yazı kontrolüyle %2) | Yeterli |
| Fransızca | minimal | ≈ $10 | %81 | %4 | Sınırda |
| Arapça–Arapça | low | ≈ $24 | %70 | %7 | Yetersiz |

- Ortak bulgular: kaynak Türkçe veride %2 hata; Türkçe ipucunun diğer dillere sızması (namaz, vacip, ocak→foyer, çağ→époque, dalgın…); الْآذَانُ/الأَذَان karışması; örneklere başlık kelimenin şahsının zorlanması; Arapçada uydurma eş anlamlılar ve dil bilgisi notları.
- Karar önerisi: İngilizce önce üretilir, diğer dillere Türkçe yerine **İngilizce anlamlar** ipucu olur; sözlük biçimi fiiller mastarla verilir; Arapçada eş/zıt anlamlılar sözlüğümüzle doğrulanır ve nottan dil bilgisi çıkarılır; aynı 200 kelimeyle ikinci tur yapılır. Geçerse 6 dil tam üretim ≈ **$75**.
- Pilotun toplam harcaması **≈ $0,96** (50'lik turlar $0,41 + 200'lük tur $0,55).

**JSON ve uygulama uyumu** (`tool/i18n/check_app_compat.py`, 1.200 çıktı):
- 1.200/1.200 geçerli JSON ve şema; yarım kalan yanıt yok; örnek cümle sayısı her kelimede Arapça örneklerle eşleşiyor; editör harf-i cerleri her dilde 91/91 karşılanmış (harekesiz eşleştirmeyle); `||` / `=` ayraç çakışması yok; çeviri dillerinin tamamı bugünkü `anlam` biçimine (`a, b||HARFI_CER:harf=x, y`) kayıpsız dönüşüyor.
- Paketleme sırasında otomatik düzeltilecekler: tek maddede birden çok anlam ("radiating, emitting" → ikiye böl), parantezler (uygulama `sadeAnlam`'da siliyor; "(f.)" gibi işaretler için karar gerekli), "..." → "…", `added` işareti eksik 1–3 fazla harf.
- Paket boyutu (gzip): çeviri dilleri ~3,4–3,9 MB, Arapça–Arapça ~8,6 MB.
- Arapça–Arapça çıktısı (şerh, eş/zıt anlam, not) için uygulamada yeni kart alanları gerekir; bugünkü biçime yalnız şerh sığar.

**Model önerisi ve maliyet** (ölçülen token sayılarıyla, 54.971 kelime, batch):

| Model | Çeviri dili başına | Arapça–Arapça |
|---|---|---|
| `gemini-3.1-flash-lite` | $10–16 | $17–24 |
| `gemini-3.5-flash-lite` | $14–24 | $25–36 |
| `gemini-3.8-flash` | $28–44 (1 Ocak 2027 sonrası 2 katı) | $46–63 (sonrası $93–125) |
| `gemini-4-argon` | $76–117 (1 Aralık 2026 sonrası 2 katı) | $124–167 (sonrası $247–334) |

- `gemini-3.5-flash-lite` (50 kelime, ilk istem, `low` ama düşünme token'ı 0 harcadı): İngilizcede 3.1 ile aynı seviye (yazım hatası yok, ama دِينٌ'e "debt" ekledi, birkaç doğal olmayan ifade); Arapça–Arapçada D 31 · K 12 · Y 7 (%14) — 3.1'den iyi değil (دِين/دَيْن karışması, "مكسرات" gibi uydurma eş anlamlılar, şerhte İbrani harf). Maliyet: İngilizce ≈ $12,5 (3.1'den %25 pahalı), Arapça ≈ $20–23 (3.1 `low` ile aynı). → Ek fayda yok.
- Öneri: çeviri dilleri (en, id, ms, ur, fr) için `gemini-3.1-flash-lite` (`minimal`) + istem düzeltmeleri; Arapça–Arapça için önce Flash-Lite'ı kısıtlı alanlarla yeniden denemek, olmazsa yalnız Arapça için `gemini-3.8-flash` (fiyat artışından önce). `gemini-4-argon` maliyet/fayda açısından gerekli görünmüyor.
- 6 dil toplamı: hepsi Flash-Lite ≈ **$75**; Arapça 3.8-flash ile ≈ **$97–113** (1 Ocak 2027 öncesi). Yeniden üretim (%5–10) ve Emsile için ~%10 pay eklenmeli.

#### 5.2.8 En düşük maliyetle en iyi kalite (araştırma, 24 Ekim 2026)
Ölçüm: tek kelimelik istekte ~900 girdi token'ının **~780'i her istekte tekrarlanan sabit talimat**, kelimenin kendi verisi ~120 token. Maliyetin çoğu bu tekrardan geliyor.

| Yöntem | Etki | Not |
|---|---|---|
| **Tek istekte 10 kelime** (her biri `wid`'li, JSON dizi) | Çeviri dili $10,1 → **$5,3**; Arapça (minimal) $23,7 → **$11,8** | Kalite riski: kelimelerin birbirine karışması/atlanması → doğrulayıcı `wid` ve sayı kontrolü yapar, eksikler tek tek yeniden gönderilir. Pilotta denenmeli. Batch kuyruğu sınırını da çözer (Tier 1'de `3.1-flash-lite` için 10 M token). |
| Batch API | %50 indirim | Zaten hesapta |
| Tekrarları bir kez üretmek | ~%2,5 | 701 tekrar başlık (307'si tam kopya), 4.720 tekrar örnek cümle |
| Kademeli model: herkes Flash-Lite, yalnız otomatik kontrolün işaretlediği kelimeler 3.8-flash | Kaliteyi güçlü modele yaklaştırır; çeviri dilinde +$1,4 (%5), Arapçada +$14 (%25) | Tek kelimelik istekle yeniden üretim |
| Önce İngilizce, diğer dillere İngilizce ipucu | Ücretsiz; Türkçe sızıntısını ve eş yazılımlı kelime hatalarını önler | |
| Arapçada eş/zıt anlamlıları **kendi sözlüğümüz + Arapça WordNet 4.0** (CC BY 4.0, 124.653 giriş, ticari kullanım atıfla serbest) ile doğrulamak; WordNet adaylarını isteme vermek | Ücretsiz; en büyük Arapça hata kaynağını kapatır | `note`'tan dil bilgisi iddiaları tamamen çıkar |
| Önbellek (context caching) | Bu iş için önemsiz | Sabit kısım ~780 token; 3.8-flash için alt sınır 4.096 token; çoklu istekte zaten paylaştırılıyor |
| Ücretsiz katman (Flash-Lite) | Çeviri dillerinde $0'a iner | Kotalar garanti değil, AI Studio'dan görülür; ücretsiz katmanda gönderilen veriler Google tarafından ürün geliştirmede kullanılabilir (AB/BK hariç) |
| Krediler | Uygunsa tamamı $0 | Google Cloud 300 $ deneme (yeni müşteri, 90 gün, Vertex AI üzerinden; AI Studio'da geçmediği bildiriliyor); Google for Startups "Start" 2.000 $ (yatırım arayan girişimler için) |
| İnsan incelemesi | Para yerine Premium kodu | Gönüllü topluluk; en çok aranan 3.000 kelime |

**Önerilen yol ve maliyet** (54.971 kelime, tekrarlar ayıklanmış, batch):

| Kalem | Model | Maliyet |
|---|---|---|
| İngilizce, Endonezce, Malayca, Urduca, Fransızca (her biri) | `3.1-flash-lite` minimal, 10 kelime/istek + sorunlu %5 için `3.8-flash` | ≈ $6,7 × 5 = **$33** |
| Arapça–Arapça | Seçenek A: tamamı `3.8-flash`, 10 kelime/istek | ≈ **$40** (1 Ocak 2027 sonrası $79) |
| | Seçenek B: `3.1-flash-lite` + sorunlu %25 için `3.8-flash` | ≈ **$26** |
| **Toplam (6 dil)** | | **≈ $59–73** (bugünkü planla $75, üstelik Arapça zayıf kalıyordu) |
| Çeviri dilleri ücretsiz katmanda yapılırsa | | ≈ **$26–40** (yalnız Arapça) |

**2. tur sonucu (24 Ekim 2026, `tool/i18n/pilot_round2.py`, ayrıntı `content/pilot/n200_r2/degerlendirme_r2.md`):** 10 kelime/istek + İngilizce ipucu + düzeltilmiş istemlerle 6 dilin tam üretim maliyeti **$75 → $36,6**. 1. turun model hatalarının çoğu düzeldi (Arapça 14'ün 12'si, Fransızca 8'in 6'sı); Arapçada yanlış oranı %9 → ~%4. Yeni riskler: toplu istekte kelime karışması (%0,2), Urducada bazı grupların Latin harfle dönmesi, İngilizce ipucundaki hatanın diğer dillere yayılması. Kalan hataların çoğu artık kaynak Türkçe veriden.

**Gemini model araştırması (API listesi + belgeler, 24 Ekim 2026):**

| Model | Batch fiyatı (girdi/çıktı, 1M) | Durum | Bizim için |
|---|---|---|---|
| `gemini-2.5-flash-lite` | $0,05 / $0,20 | Kapanış tarihi yok | En ucuz (çeviri dili ≈ $1,7); denenmedi, eski nesil |
| `gemini-3.1-flash-lite` | $0,125 / $0,75 | **7 Mayıs 2027'de kapanıyor** (yerine 3.5-flash-lite) | Denendi; çeviri dilleri için yeterli, en iyi fiyat/performans |
| `gemini-3.5-flash-lite` | $0,15 / $1,25 | Google'ın yeni projeler için önerdiği | 2. tur düzeninde denendi: 6 dil $62,5 (3.1: $36,6); fr/id/ms'de kelimelerin %10–25'inde İngilizce ipucunu çevirmeden kopyaladı, Arapçada uydurma "ayet" ve eş anlamlılar (%16 yanlış). **Şimdilik kullanılmamalı**; 3.1 kapanınca yeniden denenmeli |
| `gemini-3.6-flash` | $0,375 / $1,875 | Önceki nesil Flash | 3.8 ile aynı fiyat → gereksiz |
| `gemini-3.8-flash` | $0,375 / $1,875 (1 Ocak 2027'de 2 katı) | Google'ın önerdiği en güçlü Flash | Arapça ve İngilizce pivot için aday (İngilizce ≈ $14, Arapça ≈ $25) |
| `gemini-3.1-pro-preview`, `gemini-4-argon` | $1 / $5–6 (argon 1 Aralık 2026'da 2 katı) | — | Bu iş için gereksiz pahalı |
| `gemini-3.5-flash`, `gemini-3.7-flash`, `gemini-3.1-flash-lite-preview` | — | Kullanımdan kalkmış / kalkıyor | Kullanılmamalı |

Uygulamanın kendi AI özellikleri: kelime arama `gemini-3.1-flash-lite` (7 Mayıs 2027'den önce değişmeli), lehçe çevirisi `gemini-3-flash-preview` (legacy).

**İngilizce tam üretim TAMAMLANDI (25 Ekim 2026, ayrıntı `content/lang/en/rapor_v1.md`):** 54.962 kelimelik İngilizce sözlük (`content/lang/en/dict_final.jsonl`); ilk turda %99,86 kabul, 715 kelime tek tek yeniden üretildi, 7 çöp kaynak kayıt çıkarıldı, 2 kelime elle eklenecek. Gerçek maliyet **≈ $5,94**, süre ~1,5 saat. Yan ürün: **1.734 kelimelik Türkçe veri düzeltme listesi** (`content/lang/turkish_data_fixes.jsonl`) ve 640 kelimelik inceleme listesi (161'i iki aday sürümlü). Bulgu: düşük benzerlik listesinin çoğu toplu istek karışması değil, Türkçe verideki hatalar.

**İngilizce tam üretim hazırlığı (24 Ekim 2026):**
- `tool/i18n/build_master.py`: 54.971 kayda kalıcı wid (`content/master/wid_map.json`, `words.jsonl`); yeniden çalıştırınca wid'ler değişmiyor.
- `tool/i18n/make_batch.py --lang en`: 5.498 istek (10 kelime/istek, `data_issue` işaretli) → `content/batch/en_v1_part1..3.jsonl` (~6 / 6 / 3,3 M girdi token; kuyruk sınırı için ayrı ayrı gönderilecek) + manifest.
- `tool/i18n/submit_batch.py submit|status|download --lang en --part N` (google-genai SDK; `Desktop\batch\.venv`).
- `tool/i18n/validate.py`: wid eşleme, eksik/çevrilmemiş/Türkçe/örnek sayısı → `requeue`, biçim düzeltme, `data_issues` listesi (sahte hatalarla sınandı).
- `tool/i18n/check_mixups.py`: `gemini-embedding-2` ile anlam ↔ ipucu benzerliği; pilotta eşik 0,55 bilinen karışmayı ve iki veri hatasını yakaladı (%1,5).
- `make_batch.py --wids <requeue|mixups>.jsonl`: yeniden üretim isteği.
- Ölçülen girdi (countTokens, 40 istek): 2.779 token/istek → 15,3 M. **Son maliyet ≈ $6,4** (ana batch $5,54 + yeniden üretim ~$0,30 + karışma kontrolü ~$0,55).

**Maliyet senaryoları (6 dil, 10 kelime/istek, ölçülen tokenlarla, +%10 yeniden üretim payı):**
- Hepsi `3.1-flash-lite`: ≈ **$40**
- İngilizce (pivot) ve Arapça `3.8-flash`, diğer 4 dil `3.1-flash-lite`: ≈ **$67** (1 Ocak 2027 öncesi) Bunun $0,23'ü, durdurulmadan önce İngilizcede biten `gemini-3.8-flash` ve `gemini-4-argon` çıktılarına ait; bu çıktılar `content/pilot/` altında duruyor ama rapora alınmadı.
- Rapor: `content/pilot/rapor.html` (A/B eşleşmesi `kor_eslesme.json`).
- Sonuçlar yan yana bir tabloda gösterilir; **sen ve bir inceleyici** hangi modelin ürettiğini bilmeden puanlarsınız (doğru / eksik / yanlış). Kazanan model ve istem sabitlenir.
- Pilotta gerçek token kullanımı ölçülür. Tam üretimin maliyeti kesin rakamla çıkarılır ve senin onayından sonra başlatılır.

#### 5.2.4 Otomatik kontroller (`validate.py`)
| Kontrol | Ret / işaret ölçütü |
|---|---|
| Şema | Geçersiz JSON, eşleşmeyen `wid`, boş `senses` |
| Yazı sistemi | en/id/fr çıktısında Arap harfi; ur/fa/ar çıktısında Latin harf; bn çıktısında Bengal harfi dışı metin |
| Türkçe sızıntısı | ğ, ş, ı, İ harfleri; "ve, bir, etmek, olmak" gibi kelimeler; -mak/-mek sonları |
| Anlam sayısı | 0 veya 12'den fazla; Türkçeye göre 3 kattan fazla sapma → işaret |
| Tekrar | Aynı anlam iki kez |
| Harf-i cer | Türkçede olan harf çıktıda yok → işaret |
| Örnekler | Sayı Arapça örnek sayısına eşit değil; boş; uzunluk oranı 0,3–3 dışında |
| Terim sözlüğü | Yasaklı karşılık (politika gereği çevrilmeyecek terimler) |
| Arapçaya özel | `syn`/`ant` kelimeleri sözlüğümüzde var mı (varsa kartta bağlantı olur, yoksa incelemeye işaret); şerhte Latin harf yok |

Reddedilenler hata nedeniyle birlikte en fazla 2 kez yeniden üretilir; yine geçemezse insan kuyruğuna düşer.

#### 5.2.5 Hakem model ve insan incelemesi
- **Hakem**: üreten modelden farklı, güçlü bir model. Doğruluk, eksiksizlik ve doğallık için 1–5 puan verir, yanlış anlamları işaretler. Kapsam: en çok aranan 5.000 kelimenin tamamı + kalanların %5'i + otomatik kontrolde işaretlenenler. Puanı 4'ün altında kalanlar geri bildirimle yeniden üretilir.
- **İnsan**: en çok aranan 3.000 kelime + rastgele 300 kelime. Rastgele örneklem, incelenmeyen kısmın hata oranını tahmin etmek için.
- **Yayın ölçütü**: rastgele örneklemde yanlış veya yanıltıcı anlam oranı **%3'ün altında**.
- İnceleme tablosu sütunları: wid · Arapça · tür · Türkçe (referans) · hedef dil anlamları (düzenlenebilir) · örnekler (düzenlenebilir) · durum (onay / düzeltildi / ret).
- "En çok aranan" listesi Firebase Analytics `kelime_arama` olayından çıkarılır; bu veri yoksa ders kitabı ve Kur'an sıklığından.
- İnceleyici: ana dili hedef dil olan ve Arapça bilen biri (ör. ilahiyat/Arapça öğrencisi). Kaba tahmin: dil başına birkaç yüz dolar (serbest çalışan) veya Premium karşılığı gönüllü.

#### 5.2.6 Diğer içerikler
- **Emsile (5.596 fiil)**: mazi biçimi ana sözlükte eşleşen fiillerin anlamı oradan alınır (tutarlılık için); eşleşmeyenler aynı hatla üretilir. 24 kalıp adı terim sözlüğünden elle girilir.
- **Arayüz metinleri (ARB)**: ayrı ve küçük bir iş. Her anahtar bağlam açıklamasıyla AI'a çevrilir, tamamı insan tarafından incelenir.
- **Paketleme ve geri bildirim**: `build_pack.py` → `lang_<xx>_v<n>.json.gz` + sha256 + manifest. Kartta "Anlamı bildir" → Firestore `meaning_reports` → `overrides.jsonl` → yeni paket sürümü.

#### 5.2.7 Hacim ve süre (dil başına)
| İş | İstek sayısı | Not |
|---|---|---|
| Ana sözlük (anlam + harf-i cer + örnekler birlikte) | 54.971 | Kelime başına tek istek |
| Emsile | ≤ 5.596 | Yalnız ana sözlükte eşleşmeyenler |
| Yeniden üretim | ~%5–10 | Ret + düşük puan |

- Token hacmi (pilot istemleriyle ölçüldü, `--dry-run`): kelime başına ~1.000 girdi (bunun ~800'ü sabit talimat) + görünür çıktı en ~65, ar ~115 token + düşünme token'ları (pilotta ölçülecek).
- Tam üretim maliyeti tahmini, 54.971 kelime, Batch API fiyatı (aralık: düşünme 0 → +300 token):

  | Model | İngilizce | Arapça–Arapça | Not |
  |---|---|---|---|
  | `gemini-3.1-flash-lite` (düşünme `minimal`) | ~$10 | ~$11 | Eski hattın modeli; eski işlerde düşünme token'ı 0 çıkmıştı |
  | `gemini-3.5-flash-lite` | ~$13–33 | ~$15–36 | |
  | `gemini-3.8-flash` | ~$27–58 | ~$30–61 | 1 Ocak 2027'den sonra fiyat 2 katı |
  | `gemini-4-argon` | ~$73–156 | ~$80–163 | 1 Aralık 2026'dan sonra fiyat 2 katı |

  Karşılaştırma: eski İngilizce anlam batch'i (flash-lite, bağlamsız istem) ~28 M girdi + ~2 M çıktı token, yaklaşık $5 tutmuştu.
- Fiyat artışları yüzünden seçilen modelle tam üretimi **artış tarihinden önce** göndermek maliyeti yarıya indirir.
- Sonuç süresi: pilot normal API ile çalışır, model ve dil başına birkaç dakika sürer. Tam üretim Batch API ile gider; Google'ın hedefi 24 saat. Eski işler 54.966 kelimeyi 22 dakika ile 1,5 saat arasında bitirmişti (bazılarının sonucu ertesi gün indirilmişti, gerçek süre belirsiz).
- Girdinin büyük kısmı sabit talimat olduğu için önbelleğe alma (context caching) girdi maliyetini ayrıca düşürebilir; pilotta denenir.
- Süre (İngilizce): master veri 2 gün · pilot ve model seçimi 3–4 gün · tam batch 1–2 gün · kontrol, hakem ve yeniden üretim 2–3 gün · insan incelemesi 1–2 hafta (uygulama geliştirmeyle paralel) → **yaklaşık 3 hafta**. Arapça–Arapça aynı takvimle paralel yürür.

### 5.3 Terim sözlüğü (dil başına ~150 terim)
`content/glossary/<lang>.json` — tür adları, fiil çekim adları, emsile kalıpları, dinî terimler ve saygı ifadeleri.
- Gelenek farkı önemli: Emsile, Osmanlı/Türk medrese geleneğinin adıdır. Karşılıklar:
  - ar: تصريف الأفعال / الأوزان · id/ms: **Tashrif** (pesantrende "Al-Amtsilah at-Tashrifiyyah" bilinir) · ur: صرف / گردان · en: "Verb conjugation (taṣrīf)".
- Fiil/isim terimleri çoğu dilde Arapça terimin yerel yazımıdır: id "fi'il madhi, fi'il mudhari', mashdar, isim fa'il"; ur "فعل ماضی، فعل مضارع، مصدر، اسم فاعل"; en "Past (māḍī), Present (muḍāriʿ), Verbal noun (maṣdar), Active participle (ism fāʿil)".
- Saygı ifadeleri: tr "(s.a.v.)", en "ﷺ / (peace be upon him)", id "SAW", ur "صلی اللہ علیہ وسلم".

### 5.4 Arapça–Arapça (özel durum)
- Çeviri değil **tanım** üretilir. Kesinleşen kart içeriği (24 Ekim 2026):
  - `الشرح`: 1–2 cümlelik sade fasih tanım,
  - `المرادفات`: eş anlamlılar,
  - `الأضداد`: zıt anlamlılar (yoksa boş, kartta gizli),
  - `ملاحظة`: kısa kullanım notu (çoğul biçimi, başka anlamları, sık kalıplar).
- Paket şeması: `{sh: "...", syn: [...], ant: [...], note: "..."}`. Örnek cümleler zaten Arapça, çeviri gerekmez.
- Dört alan olduğu için inceleme yükü yalnız şerhe göre yaklaşık iki kat; inceleme önce en çok aranan kelimelerden başlar.
- Modern sözlüklerden (ör. المعجم الوسيط) **metin kopyalanmaz** (telif); özgün tanım üretilir, klasik kaynaklar yalnızca doğrulama için.
- İnceleme mutlaka ana dili Arapça bir inceleyiciyle (yanlış/uydurma tanım riski en yüksek burada).

#### 5.4.0 Araştırma: Araplar hangi sözlüğü kullanıyor? (25 Ekim 2026)
- Play'de Arapça–Arapça sözlükler: Almaany (المعاني) 1M+, معجم العرب 1M+, المعجم الشامل 1M+, çevrimdışı قاموس عربي عربي 500K+,
  Kur'an kelime anlamları 500K+ → toplam ~4M+, Endonezce/Bengalce düzeyinde talep.
- Bu uygulamalar maddeyi birkaç sözlükten gösterir (Almaany: الوسيط، الغني، اللغة العربية المعاصرة، الرائد، لسان العرب).
  Madde yapısı: **birden çok anlam** (çağdaş sözlüklerde numaralı; ذَهَبَ için 6–10), anlam başına kısa örnek, **biçim bilgisi**
  (mastar, bab, çoğul, fail/mef'ul), **harf-i cerli anlamlar** (ذهب إلى/به/عن/على), sık kalıplar (كتم غيظه، كاتم الصوت),
  bazen ayet/şiir şahidi. Eş/zıt anlamlılar ayrı sözlükte (معجم المرادفات والأضداد).
- Sonuç: **tek cümlelik şerh yetersiz**; çok anlamlı kelimede rakiplerin gerisinde kalır. Madde yapısı genişletilmeli (5.4.1).
- Telif: الوسيط (Kahire Arap Dili Akademisi), اللغة العربية المعاصرة (2008), الغني, الرائد çağdaş ve telifli → kopyalanmaz.
  لسان العرب, القاموس المحيط, مختار الصحاح, الصحاح yüzyıllar önce yazıldığı için telif dışı → doğrulama kaynağı olabilir.
- Kaynak: maajim.com madde karşılaştırması (كتم، ذهب), Play Store ölçümü.

#### 5.4.1 Üretim planı (25 Ekim 2026, kullanıcı "önce Arapça" dedi)
**Güncel madde yapısı (araştırmadan sonra):** `senses` 1–4 numaralı anlam (sıklığa göre; arkaik anlamlar yok), her biri
≤20 kelimelik tanım + varsa kendi örnek cümlemizden biri; `preps` harf-i cerli anlamlar; `syn`/`ant` (süzgeçli);
`colloc` 0–3 sık kalıp. **Biçim bilgisi (mastar, çoğul, çekimler) yapay zekâya ürettirilmez**, kendi verimizden gelir
(pilotta modelin uydurduğu yer burasıydı). Ayet/şiir şahidi üretilmez (3.5 uydurma ayet yazmıştı).
Daha zengin çıktı → kelime başı ~300 giriş / ~350 çıkış token: flash-lite ≈ $17 + hakem ≈ $5; 3.8-flash ≈ $42 + hakem.
Aşağıdaki maddeler ilk (tek şerhli) plana göredir; adımlar aynı kalır.

**3. tur pilotu (25 Ekim 2026, `tool/i18n/pilot_ar3.py`, ayrıntı `content/pilot/ar3/degerlendirme.md`):** 50 kelime tek tek okundu.
flash-lite D %68 · K %30 · Y %2 (tam üretim ≈ $12,6); **3.8-flash D %92 · K %6 · Y %2** (≈ $23,5, 1 Ocak 2027'de iki katına
çıkar). 3.8 daha zengin (kelime başı 2,5 eş, 1,4 zıt, 1,2 kalıp) ve biçim/şahıs uyumu tutarlı. Sözlük süzgeci doğru çekimli
eş anlamlıları da attığı için yalnız "başlığın kendisi" süzgeci + hakem turu kullanılacak. Öneri: Arapça için 3.8-flash.

**4. tur (v4 istem, 37 çok anlamlı kelime, `--prompt v4`):** kart diğer diller gibi en üstte kısa satır gösterir
(eş anlamlılar), altında İngilizce ipucundaki her ayrı anlam için numaralı şerh (en fazla 5). Anlam sayısı: 1 anlam 4,
2 anlam 24, 3 anlam 8, 4 anlam 1 kelime (3. turda kelimelerin %76'sı tek anlamdı). عَيْنٌ: göz, pınar, casus, öz;
قَضَى: hüküm verdi, (vakit) geçirdi, yerine getirdi. Kalan kusurlar gevşek eş anlamlı (كَتَمَ → طَمَسَ، صَانَ) ve
şüpheli harf-i cer (عَلِمَ عَلَى). Kelime başı 251 çıkış token → tam üretim ≈ $25–32 (çok anlamlılar pahalı).
**Kart kararı (25 Ekim 2026, telefonda denendi):** kapalı kartta ١ rozetiyle ilk anlamın şerhi; açılınca yerinde kalır,
altına örneği gelir, ٢'den sonraki anlamlar art arda (rozet + tanım + çizgili örnek); sonra kelimeyle birlikte harf-i cerler
(«قَامَ بِـ …»); en altta çoğul ve çekim kutuları. Tanımlar telefonun Arapça fontuyla. **Eş/zıt anlamlı ve kalıplar
kullanıcı isteğiyle kaldırıldı**; Arapça maddede emsile ve "daha fazla örnek" butonları gizli. Tam üretim istemi buna göre
yalnız `senses` + `preps` (+ `data_issue`) üretecek → çıktı kısalır, maliyet düşer.
Uygulamada deneme: `ArabicDefinitions` + `ArabicQuickLine`/`ArabicDefinitionView`, test asset'i
`assets/data/sozluk_ar_pilot.json.gz` (`tool/i18n/build_ar_pilot_asset.py`, 230 madde), test derlemesinde `MEANING_LANG=ar`.
**26 Ekim 2026:** tam sözlük `assets/data/sozluk_ar.json.gz` (`tool/i18n/build_ar_asset.py`; 56.394/56.406 kayıt, 4,4 MB gz,
22,4 MB ham). Kayıtların kimliği olmadığından madde başlıkla bulunur; aynı başlığı paylaşan farklı türdeki kayıtlar
"başlık|tür" anahtarıyla ayrıca tutulur, örnek numarası metne çevrilir. Yükleme açılışı bekletmez (`ArabicDefinitions.loaded`,
kartlar yüklenince yenilenir). Telefonda (debug) denendi: yeni kelime مَوْهِبَةٌ ve eski kelimeler (قَامَ، كِتَابٌ) tam kartla
geliyor. Release test derlemesi şimdilik yapılamıyor: `.entest` Firebase istemcisi yalnız `src/debug/google-services.json`'da.
Kalıcı çözümde 22 MB JSON belleğe açılmamalı, dil paketi SQLite'a yazılmalı (4.5).
**Hareke kararı (26 Ekim 2026, kullanıcı):** veride tanımlar tam harekeli kalır (73.745 tanımın %100'ü); kartta tanım,
örnek ve harf-i cerli anlam Arapça sözlüklerdeki gibi **varsayılan harekesiz** gösterilir, başlık kelime, kalıp başlığı,
çoğul ve çekim kutuları harekeli kalır. Kartın altındaki «التشكيل» düğmesi harekeyi açar; tercih bütün kartlar için
geçerli ve kalıcı (`ar_show_tashkeel`). Telefonda denendi. **Güncelleme (aynı gün, kullanıcı):** ayar karttan profile taşındı
(`TashkeelTile`, "Uygulama dili"nin altında, yalnız Arapça anlam dilinde); kart açılınca ilk satır kaydığı için anlam numaraları
(١ ٢ ٣) kaldırıldı, anlamlar örnek balonlarıyla ayrılır.

**Endonezce, Malayca, Urduca tam üretim (26 Ekim 2026, `tool/i18n/lang_pipeline.py`):** gemini-3.1-flash-lite, `minimal`,
10 kelime/istek, İngilizce son sözlük ipucu; sözlük 56.406 kayıt (yeni eklenen 1.435 dahil).
| Dil | İlk turda kabul | Yeniden üretilen (başlıca neden) | Son sözlük | Maliyet |
|---|---|---|---|---|
| id | 56.231 | 175 (156 anlam İngilizce kalmış) → 171 | 56.402 | $5,42 |
| ms | 55.627 | 779 (770 anlam İngilizce kalmış) → 776 | 56.403 | $5,58 |
| ur | 49.870 | 6.536 (6.529 Latin harfli Roman Urdu) → 6.452 | 56.322 | $6,77 |
Toplam ≈ $17,8. Urducada 84 kelime iki turda da Latin harfli döndü (madde yok). Rastgele 20'şer kelime okundu: id D 19 · K 1,
ms D 18 · K 2 (halimunan "görünmez" ← sis; Endonezce jendela), ur D 18 · K 2; yanlış yok. Uygulamada henüz yalnız tr/en/ar
anlam dili seçilebiliyor; bu dillerin asset'i ve dil paketi yapılmadı.
Pilot geçmişi (aynı 200 kelime): 1. tur D %70 · K %21 · Y %9; 2. tur (dil bilgisi nottan çıkarıldı, 10 kelime/istek)
rastgele 25'te D 14 · K 10 · Y 1 (%4). Şerh çoğunlukla doğru; sorun eş/zıt anlamlılarda (uydurma, gevşek, yanlış tür)
ve Türkçe ipucunun sızmasında ("دالغ" ← dalgın).
1. **Girdi:** Arapça başlık, kök, tür, Arapça örnekler + **İngilizce anlamlar** (doğrulanmış, Türkçe değil) ipucu.
2. **Üretim:** gemini-3.1-flash-lite, `low`, 10 kelime/istek, batch. Kelime başı ~254 giriş / ~190 çıkış token → **≈ $9,6**.
3. **Eş/zıt anlamlı süzgeci (yeni):** her eş/zıt anlamlı (1) harekesiz, `ال`'siz biçimiyle sözlüğümüzde (54 bin başlık)
   bulunmalı, (2) eş anlamlıysa sözlükteki İngilizce anlamı başlığın İngilizce anlamına gömme benzerliğiyle yakın olmalı.
   Geçemeyen silinir (az ama doğru). Gerekirse kapsama için Arabic WordNet 4.0 (CC BY 4.0; indirme için onay gerekir). ≈ $0,3.
4. **Hakem turu:** aynı model, kelime başı "şerh başlığa ve İngilizce anlama uyuyor mu, not uydurma mı" → ok/sorun. ≈ $4.
5. **Yeniden üretim:** sorunlu ve süzgeçte boş kalanlar tek kelimelik istekle (~%5). ≈ $0,5.
6. **Örnek denetim:** rastgele 200 kelimeyi tek tek okuyup D/K/Y oranını ölçmek; en çok aranan ~2.000 kelime ana dili
   Arapça biri tarafından incelenir.
- Toplam ≈ **$15–16**, ~2–3 saat. Hedef: Y ≤ %2, K ≤ %15 (pilotla ölçülecek; tutmazsa tam üretime geçilmez).

**Tam üretim sonucu (26 Ekim 2026, `tool/i18n/ar_pipeline.py`, özet `content/lang/ar/pipeline_report.txt`):** v5 istem,
gemini-3.8-flash, 10 kelime/istek, 6 parça (her biri ~4 dk). 54.962 kelimenin 54.946'sı otomatik denetimden geçti; hakem
(flash-lite) 1.695'ini (%3,1) işaretledi; 1.711 kelime tek kelimelik istekle yeniden üretildi, 1.708'i kabul edildi.
Son sözlük `content/lang/ar/dict_final.jsonl`: **54.959 kelime**, iki turda da kabul edilmeyen 3. **Gerçek maliyet ≈ $22,02**
(ana $18,37 · hakem $2,38 · yeniden üretim $1,27; usageMetadata × batch fiyatı).
Rastgele 200 madde tek tek okundu: **D %88,5 · K %11,5 · Y %0** (hedefin içinde). K'lerin 7'si Türkçe verideki harekeli başlık
yazım hatası (طَلَافَةٌ → طلاقة, يَخْتَضِنُ → يحتضن, إِثَارٌ → إيثار, يُصِينُ → يصيب; 6'sı `data_issue` olarak işaretli);
kalan 16'sının yarısı uydurma/şüpheli harf-i cerli kullanım (يَقْبَلُ عَلَى ← أَقْبَلَ, بِئْسَ بِهِ), diğerleri zayıf örnek ve
iki harekeli kelimeyi karıştırma (وَثُقَ / وَثِقَ بِهِ). Model 3.372 başlıkta Türkçe veride sorun gördü
(`data_issues_v1*.jsonl`): Türkçe veri düzeltmesi için aday liste.

**Türkçe veri denetimi (26 Ekim 2026, `tool/i18n/check_tr_data.py`, gemini-3.8-flash `low`, $0,94):** işaretli 3.376 kayıt
→ ok 453 · düzeltme 2.878 · emin değil 45. Sorunlar: örnek 1.170, yazım 1.020, hareke 808, anlam 806, iki kelime karışmış 290,
tür 192, kelime değil 124. 1.616 başlık düzeltmesinin 1.431'i kanıtlı (649'u kaydın kendi örneğinde geçiyor; 1.416'sı
sözlükte zaten ayrı başlık → çoğu mükerrer kayıt, düzeltmede birleştirilmeli). Kalibrasyon: el ile bakılan 30 kayıtta
gerçek 21 sorunun 20'si + gözden kaçan 4 örnek hatası bulundu; `low` zor kayıtlarda `medium`'dan cesur (anlam önerileri
incelenmeli). Çıktı `content/lang/tr/fix_v1.jsonl` ve `duzeltme_listesi_v1.csv` (onay sütunlu); veride değişiklik yok.

**Eksik kelimeler (26 Ekim 2026):** uygulama "bulunamadı" aramalarını kaydetmiyor. (1) Firebase Realtime Database `kelimeler`
(eski AI aramasının ortak sözlüğü, 60.223 kayıt, 46.589'u AI, Haz 2025–May 2026) tarayıcıdan indirildi
(`content/firebase/kelimeler_2026-10-26.json`); `tool/i18n/firebase_missing.py` → sözlükte olmayan **1.196** kelime
(çoğu Mart–Mayıs 2026, son aktarımdan sonra). `check_tr_data.py --recs … --tag fbnew` ($0,28): 968 olduğu gibi eklenebilir,
166 düzeltilerek, 61 mevcut kelimenin hatalı tekrarı, 1 şüpheli (`content/lang/tr/fbnew_liste_v1.csv`). (2) Altyazı sıklık
listesi (hermitdave/FrequencyWords `ar_50k.txt`, MIT) `tool/i18n/freq_gap.py` + `freq_classify.py` (3.8-flash, $0,47):
3.504 aday → 2.256 özel isim, 982 kelime…; **sözlükte hiçbir biçimi olmayan 314 lemma** (ilk 20 binde 92), 100'ünün yalnız
çekimli biçimi var. Çoğu modern alıntı (دُولَار، جِنِرَال، أُكْسِجِين) ve bazı MSA kelimeleri (مَوْهِبَة، زِنَاد، مَشْرَحَة);
bir kısmı uygunsuz/argo (eklemeden önce elenmeli). Sonuç `content/lang/tr/freq_missing_subs.jsonl`. (3) Arapça Vikipedi
sıklık listesi (IlyaSemenov/wikipedia-word-frequency `arwiki-2022-08-29.txt`, MIT), ilk 50 bin, $0,99: 6.738 aday → 4.484 isim,
1.843 kelime…; **hiçbir biçimi olmayan 905 lemma** (ilk 10 binde 82, ilk 20 binde 259), 149'unun yalnız çekimli biçimi var.
Ağırlıkla milliyet/nisbe sıfatları (يُونَانِيّ، بُولَنْدِيّ), bilim terimleri (أُكْسِجِين، يُورَانْيُوم), mezhep ve siyaset terimleri;
az sayıda temel MSA kelimesi (مُسْتَكْشِف، اِسْتِثْنَائِيّ، مُقَاضَاة). İki liste birlikte 1.051 farklı eksik lemma (168 ortak).
Sonuç `content/lang/tr/freq_missing_wiki.jsonl`. Güvenlik: aynı
veritabanının kuralları herkese açık (konsol uyarısı) ve kod Gemini anahtarını `config/gemini_api`'den okuyor.
- Önce aynı 200 kelimeyle bu düzenin pilotu (≈ $0,10), sonuç kullanıcıya gösterilir, onayla tam üretim.
- Uygulama tarafı: Arapça anlam dilinde kart şerh / المرادفات / الأضداد / ملاحظة / harf-i cer anlamlarını gösterir; örnekler
  zaten Arapça (çeviri satırı gizlenir).

### 5.5 Kuran mealleri (Kuran Sözlüğü ertelendi; açılırsa geçerli)
- Ayet mealleri yapay zekâ ile **üretilmez**. Her dil için yerleşik, tanınmış bir meal ve **ticari kullanıma uygun lisans** kontrolü (Tanzil, QuranEnc, Quran.com/Quran Foundation kaynaklarının her çevirisinin lisansı ayrı ayrı incelenmeli); künye ve kaynak gösterimi uygulama içinde.
- Lisans sağlanamayan dilde Kuran sözlüğü yalnızca kelime anlamlarıyla açılır, meal satırı gizlenir.

---

## 6. Gelir, mağaza ve ASO

### 6.1 Abonelik ve satın alma
- RevenueCat ürünleri aynı kalır; App Store Connect ve Play Console'da **ürün adı/açıklaması her dil için** girilir.
- **Bölgesel fiyat**: Endonezya, Pakistan, Bangladeş, Mısır, Hindistan, Nijerya için satın alma gücüne göre düşük fiyat (Play ülke bazlı fiyat, App Store storefront fiyatı); RevenueCat Offerings'i ülkeye göre hedefleme.
- Ödeme duvarı (subscription_screen) metinleri, otomatik yenileme açıklaması ve EULA bağlantısı **her dilde** (App Review 3.1.2 için zorunlu ögeler).
- Kitap satın alma (`book_store_service`): kitap adları/açıklamaları dil başına; içerik o dilde hazır değilse mağazada gösterilmez.

### 6.2 Reklam
- AdMob eCPM Güney/Güneydoğu Asya'da düşük → bu dillerde gelirin büyük kısmı hacimden gelir; reklam sıklığı Remote Config ile ülke bazında.
- Rusya'da Google reklamları ve Play ödemeleri kısıtlı; İran'da Play/App Store dağıtımı yok — bu pazarlar için gelir beklentisi sıfıra yakın planlanır.

### 6.3 Mağaza girişleri
- **Play**: en-US ve ar taslakları v5.0 ile birlikte yayınlanır; sonra id, ms, ur, fr-FR, bn-BD, ru-RU… Başlık 30, kısa açıklama 80 karakter. Gerekirse ülke bazlı özel mağaza girişleri (mevcut "kavaid" özel girişi gibi).
- **App Store**: İngilizce, Arapça, Endonezce, Malayca, Fransızca, Rusça… yerelleştirmeleri eklenir (Urduca ve Bengalce App Store Connect'te listelenebiliyor; yayın öncesi kontrol edilmeli). Ad 30, alt başlık 30, anahtar kelime 100 karakter.
- **Uygulama adları (26 Ekim 2026, kullanıcı onayladı):** Latin alfabeli bütün dillerde marka **Kavaid** kalır
  ("Qavaid/Qawaid" değil: Play "qavaid"ı "qawaid" gibi arıyor ve 14+ dilbilgisi / Kur'an elifbası uygulaması çıkıyor
  (Ahsanul Qawaid, Qawaid un Nahw…); App Store'da "kavaid" 6 ülkede yalnız bizi gösteriyor). "qawaid, qavaid" gizli
  anahtar kelimelere eklenir.

  | Dil | İkon altı | Mağaza başlığı |
  |---|---|---|
  | tr | Kavaid | Kavaid Arapça Türkçe Sözlük (yayında) |
  | en | Kavaid | Kavaid: Arabic Dictionary |
  | ar | قاموس قواعد | قاموس قواعد – معجم عربي عربي |
  | id | Kavaid | Kavaid: Kamus Arab Indonesia |
  | ms | Kavaid | Kavaid: Kamus Arab Melayu |
  | ur | قواعد لغت | قواعد: عربی اردو لغت |
  | Pakistan (en, ülkeye özel giriş) | — | Kavaid: Arabic Urdu Dictionary |

  İkon altı ad: Android `res/values-ar|ur/strings.xml` (`app_name`), iOS `ar.lproj` / `ur.lproj/InfoPlist.strings`
  (`CFBundleDisplayName`). `ar.lproj` dosyası önceden diskte olup Xcode projesine bağlı değildi; 26 Ekim'de ikisi birlikte
  `Runner.xcodeproj`'a (InfoPlist.strings değişken grubu) eklendi — ilk Codemagic derlemesinde doğrulanmalı.
- **Ekran görüntüleri**: bugün Android'den alınmış Türkçe `assets/intro/*.webp` kullanılıyor. Yeni: `integration_test` + her dil için otomatik ekran görüntüsü → `tool/make_store_graphics.py` (zaten tr/en/ar destekli) çerçeveleme.
- Yorum yanıtları ve destek: en az İngilizce + Arapça; AI destekli yanıt taslağı.

---

## 7. Hukuk ve politika
- Gizlilik politikası ve EULA (onbir-apps.web.app/privacy.html) en azından İngilizce ve Arapça; her dilde uygulama içi bağlantı.
- Mağaza metinleri yalnızca **gerçekten hazır olan** içeriği vaat eder (yanıltıcı açıklama politikası; şu anki taslakların bekletilme sebebi).
- App Review notları İngilizce güncellenir; test hesabı (test@kavaid.com) doğrulanır.
- Dinî içerik: meal lisansı ve künyesi, terim sözlüğü, saygı ifadeleri; kullanıcı bildirimleriyle hızlı düzeltme.
- Topluluk sohbeti: dil odaları + her dilde kullanım kuralları + raporlama (UGC politikası).

---

## 8. Test ve kalite
- **Birim testleri**: her `MeaningNormalizer`, paket ayrıştırıcı, `wid` eşleme, ARB tamlığı.
- **Golden/ekran testleri**: ana ekran, kelime kartı, emsile, ödeme duvarı × (tr, en, ar, ur, pseudo) × (açık/koyu) × (küçük telefon/tablet).
- **RTL kontrol listesi**: geri tuşu yönü, kaydırma yönleri, sayfa geçiş animasyonu, ilerleme çubukları, sekme sırası, Arapça arayüzde Latin metin.
- **Arama kalitesi**: dil başına 200 "altın sorgu" (ör. en "book" → كِتَابٌ ilk 3'te); "sonuç yok" oranı izlenir.
- **Kapalı test**: Play kapalı test kanalında dil başına 5–10 ana dili konuşan kullanıcı; TestFlight harici test.
- **Kademeli yayın**: Play %5 → %20 → %100; Crashlytics ve "sonuç yok" oranına göre ilerleme.
- Türkçe regresyon testi her sürümde zorunlu.

---

## 9. Başarı ölçütleri (dil başına)
- Yükleme, D1/D7/D30 elde tutma, günlük arama/kullanıcı.
- Arama "sonuç yok" oranı ve AI'a düşme oranı (paket kalitesinin göstergesi).
- "Anlamı bildir" sayısı / 1.000 kelime görüntüleme.
- Abonelik dönüşümü, ARPDAU (reklam + abonelik), mağaza puanı (dil bazında).
- Çökme yaşamayan oturum oranı (RTL dillerinde ayrıca).

---

## 10. Yol haritası

| Faz | Süre | İçerik | Çıktı |
|---|---|---|---|
| **0 – Karar ve hazırlık** | 1 hafta | Kendi verimizle dil doğrulaması, bütçe, inceleyici arayışı, terim sözlüğü taslakları (en, ar), `wid` atama ve tür kodları | Kesin dil listesi, `content/master` |
| **1 – Altyapı** | 3–4 hafta | gen-l10n + metin çıkarma, LanguageService, dil seçimi ekranı, RTL denetimi, fontlar, SQLite v2 + göç, dil paketi servisi, `MeaningNormalizer`, AI istemlerinin parametrelenmesi, modül bayrakları, analitik | Türkçe davranışı birebir aynı, dil altyapısı hazır sürüm (iç test) |
| **2 – İçerik (1. dalga)** *(Faz 1 ile paralel)* | ~3 hafta | Yeni hatla sıfırdan (5.2): pilot → en ve ar tam üretim (en: anlam, harf-i cer, örnekler; ar: şerh, eş/zıt anlam, not) → otomatik kontrol, hakem, insan incelemesi; Emsile; ARB en/ar çevirisi ve incelemesi | `lang_en_v1`, `lang_ar_v1`, `app_en.arb`, `app_ar.arb` |
| **3 – Test ve yayın v5.0** | 2 hafta | Golden testler, kapalı test, ekran görüntüleri, mağaza girişleri (Play taslaklarını yayınla, iOS en/ar ekle), kademeli yayın | **v5.0: tr + en + ar** (≈ Ocak 2027 ortası) |
| **4 – 2. dalga** | dil başına 2–3 hafta (paralel yürütülebilir) | id + ms, ur (Nastaʿlīq ve RTL ek testleri), fr | v5.1 (id, ms, ur) — Ramazan 2027 (≈ 8 Şubat) öncesi hedef; v5.2 (fr) |
| **5 – 3. dalga** | 2027 2. çeyrek | bn, ru, uz, az, de | v5.3+ |
| **Sürekli** | — | Geri bildirimle paket düzeltmeleri, Kuran mealleri, yeni diller | Paket sürümleri |

Ramazan, Kuran ve Arapça uygulamaları için en yoğun dönemdir; 2. dalganın (özellikle Endonezce ve Urduca) içerik üretimine Faz 3 sırasında başlamak takvimi kurtarır.

---

## 11. Riskler ve önlemler

| Risk | Etki | Önlem |
|---|---|---|
| AI çeviri hataları (özellikle dinî terimler, Arapça şerh) | Güven kaybı, kötü yorum | Terim sözlüğü, otomatik kapılar, en çok aranan kelimelerde insan incelemesi, "Anlamı bildir" |
| Paket boyutu / bellek (önceki girişimin geri alınma sebebi) | Yavaş açılış, ANR | Yalnızca tr + en gömülü, diğerleri indirilebilir; arama önbelleğinde tek dil |
| RTL hataları | Arapça/Urduca kullanıcılarında bozuk arayüz | Directional widget'lar, golden testler, kapalı test |
| Türkçe kullanıcılarda gerileme | Ana gelir kaynağına zarar | Türkçe sabitleme, regresyon testleri, kademeli yayın, özellik bayrakları |
| Bakım yükünün dil sayısıyla çarpılması | Her yeni özellik yavaşlar | ARB tamlık kontrolü CI'da, AI ile çeviri + toplu inceleme, dil sayısını dalgalarla sınırlama |
| Meal lisansı | Hukuki risk | Yalnız lisansı doğrulanmış meal, yoksa meal satırı gizli |
| Ödeme/dağıtım kısıtları (Rusya, İran) | Gelir beklentisi boşa çıkar | Bu pazarları gelir planına katmamak, reklam/fiyat Remote Config ile |
| Yanıltıcı mağaza açıklaması | Mağaza politikası ihlali | Mağaza metinleri yalnız yayındaki içeriği anlatır |
| AI kötüye kullanımı (küresel trafik) | Maliyet artışı | Kota, giriş şartı (mevcut), anahtarı sunucuya taşıma değerlendirmesi |
| Destek yükü | Yanıtsız yorumlar | İngilizce + Arapça destek, AI destekli yanıt taslakları, SSS ekranı |

---

## 12. Kararlar

**Verilen kararlar (24 Ekim 2026):**
- Öğren sekmesi (kitaplar, Kitabü'l Kıraat, Siyer) → **yalnız Türkçe**.
- AI özellikleri → **her dilde Türkçedeki kurallarla** (giriş şartı + kredi/kota).
- Arapça–Arapça kart → **şerh + eş anlamlı + zıt anlamlı + kullanım notu**.
- Kuran Sözlüğü → **şimdilik yalnız Türkçe**; diğer diller için karar ertelendi.
- Eski İngilizce veri → **kullanılmayacak**, geri dönüşüm kutusuna taşındı; tüm diller yeni hatla sıfırdan üretilecek.

**Bekleyenler:**
1. **Pilot**: 300 kelimelik örneklemle model karşılaştırmasına başlansın mı (5.2.3)?
2. **1. dalga dilleri**: tr + en + ar önerisi uygun mu, yoksa Endonezce de v5.0'a mı girsin?
3. **İnsan incelemesi bütçesi**: serbest çalışan mı, gönüllü topluluk (Premium karşılığı) mı?
4. **Bölgesel fiyat**: düşük gelirli ülkelerde abonelik fiyatını düşürelim mi?
5. **API anahtarı**: GitHub'a gitmiş Gemini anahtarının yenilenmesi (yalnız sen yapabilirsin, Google AI Studio / Cloud Console).

---

## 13. Hemen başlanabilecek ilk işler (Faz 0–1)
1. `wid` atama betiği + tür kodu eşlemesi (`tool/build_master_content.py`) — veriye dokunmadan ana kopya üretir.
2. `tool/i18n/` hattının ilk betikleri (`make_batch.py`, `run_batch.py`, `validate.py`) ve 300 kelimelik pilot (en + ar).
3. gen-l10n kurulumu + `app_tr.arb` iskeleti; önce en görünür ekranlar: ana ekran, kelime kartı, arama, ödeme duvarı, profil.
4. `LanguageService` yeniden yazımı (Türkçe sabit kalacak şekilde) + `supportsRtl` / `CFBundleLocalizations`.
5. RTL denetimini `EdgeInsetsDirectional`/`AlignmentDirectional` dönüşümüyle başlatmak (Türkçede görsel fark yaratmaz).
6. Betiklerdeki açık API anahtarlarını kaldırıp `GEMINI_API_KEY` ortam değişkenine geçmek (anahtarın yenilenmesi senin tarafında).
