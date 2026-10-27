# Google Play mağaza girişi

Play Console metinlerinin kopyası.

- `tr-TR.txt` — canlı varsayılan giriş (Arapça–Türkçe sözlük).
- `en-US.txt` — Arapça–İngilizce sözlük olarak yazılmış metin.
- `ar.txt` — Arapça–Arapça sözlük olarak yazılmış metin.
- `ios-tr.txt` — App Store (Türkçe) ad, alt başlık, tanıtım metni, anahtar kelimeler, açıklama, "Yenilikler".
  App Store ekran görüntüleri `tool/make_store_graphics.py` çıktısındaki `ios/tr/` klasörüdür
  (1206x2622, iPhone çerçevesi: Dynamic Island, durum çubuğu, ana ekran çizgisi).

Uygulama adları (26 Ekim 2026, onaylandı; ayrıntı `docs/YERELLESTIRME_PLANI.md` 6.3): marka her Latin alfabeli
dilde **Kavaid**. Başlıklar: tr "Kavaid Arapça Türkçe Sözlük", en "Kavaid: Arabic Dictionary",
ar "قاموس قواعد – معجم عربي عربي", id "Kavaid: Kamus Arab Indonesia", ms "Kavaid: Kamus Arab Melayu",
ur "قواعد: عربی اردو لغت", Pakistan'a özel İngilizce giriş "Kavaid: Arabic Urdu Dictionary".

`en-US` ve `ar` girişleri, uygulama arayüzü ve kelime anlamları o dillere
yerelleştirilmeden **yayına gönderilmemelidir**; Play Console'da taslak olarak
bekler (Mağaza girişleri > Varsayılan girişi düzenle). Yerelleştirme çıkınca
ekran görüntüleri o dildeki arayüzle yeniden alınmalıdır.

Görseller `python tool/make_store_graphics.py <klasör>` ile üretilir (gerçek ekran
görüntüleri: `assets/intro/*.webp`; Arapça yazı için Windows'ta Segoe UI gerekir).
Sayılar: sözlük ~55.000 kelime, Emsile 5.596 fiil, Kur'an sözlüğü 21.218 kelime,
çeviride 18 Arapça türü ve 12 hedef dil.
