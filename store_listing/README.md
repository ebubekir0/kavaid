# Google Play mağaza girişi

Play Console metinlerinin kopyası.

- `tr-TR.txt` — canlı varsayılan giriş (Arapça–Türkçe sözlük).
- `en-US.txt` — Arapça–İngilizce sözlük olarak yazılmış metin.
- `ar.txt` — Arapça–Arapça sözlük olarak yazılmış metin.

`en-US` ve `ar` girişleri, uygulama arayüzü ve kelime anlamları o dillere
yerelleştirilmeden **yayına gönderilmemelidir**; Play Console'da taslak olarak
bekler (Mağaza girişleri > Varsayılan girişi düzenle). Yerelleştirme çıkınca
ekran görüntüleri o dildeki arayüzle yeniden alınmalıdır.

Görseller `python tool/make_store_graphics.py <klasör>` ile üretilir (gerçek ekran
görüntüleri: `assets/intro/*.webp`; Arapça yazı için Windows'ta Segoe UI gerekir).
Sayılar: sözlük ~55.000 kelime, Emsile 5.596 fiil, Kur'an sözlüğü 21.218 kelime,
çeviride 18 Arapça türü ve 12 hedef dil.
