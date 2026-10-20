"""X (Twitter) için 4 görselli (karusel) tanıtım gönderisi üretir.

Kullanım (proje kökünde):
  python tool/make_x_post.py <ekran görüntüsü klasörü> <çıktı klasörü>

Ekran görüntüsü klasöründe telefondan alınmış (1080x2340) şu dosyalar beklenir:
  verb.png (fiil çekimli sözlük kartı), emsile.png, quran.png, ai.png, translate.png

X 2026'dan beri çok görselli gönderileri kaydırılan karusel olarak, kırpmadan gösterir
(en fazla 4 görsel). Telefonda ekranı en çok 9:16 kapladığı için 4 dikey 9:16 (1080x1920)
slayt üretilir ve telefon görselin çoğunu kaplar ki arayüz okunabilsin; ilki markanın
mavisi, diğerleri her bölümün kendi renginde. Ekranlar make_store_graphics.iphone
çerçevesine konur: telefonun kendi durum çubuğu ve alt gezinme çubuğu kesilir, yerine
iPhone durum çubuğu ve ana ekran çizgisi gelir.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw  # noqa: E402

import make_store_graphics as g  # noqa: E402

SHOTS = sys.argv[1] if len(sys.argv) > 1 else 'shots'
OUT = sys.argv[2] if len(sys.argv) > 2 else 'x_post'
W, H = 1080, 1920
EDGE = 4                # ekran kaydı sırasında kenarda çıkan ince çerçeve
STATUS_END = 108        # Android durum çubuğunun bittiği y (1080x2340 görüntüde)
NAV_TOP = 2148          # uygulamanın alt gezinme çubuğunun başladığı y

COLORS = {
    'blue': ((8, 84, 200), (20, 140, 255)),
    'navy': ((30, 46, 104), (66, 96, 170)),
    'green': ((16, 84, 58), (40, 138, 92)),
    'purple': ((62, 42, 160), (122, 82, 222)),
}


def screen(name, top=STATUS_END, bottom=NAV_TOP):
    """Durum çubuğu ve alt gezinme çubuğu olmadan uygulama ekranı."""
    img = Image.open(os.path.join(SHOTS, name)).convert('RGB')
    return img.crop((EDGE, top, img.width - EDGE, min(bottom, img.height - EDGE)))


def background(color):
    top, bottom = COLORS[color]
    return g.stars(g.gradient(W, H, top, bottom), alpha=26, cell=170).convert('RGBA')


def wrap(text, f, max_w):
    probe = ImageDraw.Draw(Image.new('RGBA', (1, 1)))
    lines, cur = [], ''
    for word in text.split(' '):
        t = (cur + ' ' + word).strip()
        if probe.textlength(t, font=f) > max_w and cur:
            lines.append(cur)
            cur = word
        else:
            cur = t
    lines.append(cur)
    return lines


def brand(canvas, y=40, size=56):
    icon = Image.open('assets/images/app_icon.png').convert('RGBA').resize((size, size), Image.LANCZOS)
    ic = Image.new('RGBA', icon.size, (0, 0, 0, 0))
    ic.paste(icon, (0, 0), g.rounded_mask(icon.size, size // 4))
    f = g.font(int(size * 0.62), 800)
    d = ImageDraw.Draw(canvas)
    tw = d.textlength('Kavaid', font=f)
    x = (W - (size + 14 + tw)) / 2
    canvas.alpha_composite(ic, (int(x), int(y)))
    d.text((x + size + 14, y + size / 2), 'Kavaid', font=f, fill=(255, 255, 255), anchor='lm')


def header(canvas, title_lines, sub, y=120):
    """Ortalı başlık ve alt metin; alt metnin bittiği y'yi döndürür."""
    d = ImageDraw.Draw(canvas)
    tf, sf = g.font(84, 800), g.font(40, 500)
    for s in title_lines:
        d.text(((W - d.textlength(s, font=tf)) / 2, y), s, font=tf, fill=(255, 255, 255))
        y += 98
    y += 6
    for s in wrap(sub, sf, W - 140):
        d.text(((W - d.textlength(s, font=sf)) / 2, y), s, font=sf, fill=(255, 255, 255, 235))
        y += 46
    return y


def put_phone(canvas, shot, width, x, y):
    sprite = g.iphone(shot, width)
    return g.with_shadow(canvas.convert('RGB'), sprite, (int(x), int(y)), blur=30, offset=(0, 20),
                         opacity=115).convert('RGBA')


def slide(color, shot, title_lines, sub, pw=920):
    c = background(color)
    brand(c)
    y = header(c, title_lines, sub)
    c = put_phone(c, shot, pw, (W - pw - 2 * max(4, round(pw * 0.007))) / 2, y + 44)
    return c.convert('RGB')


def slide_duo():
    """4. slayt (mor): yapay zekâ asistanı ve çeviri, iki telefon."""
    c = background('purple')
    brand(c)
    y = header(c, ['Yapay zekâ', 've çeviri'], 'Kelimeyi sor, cümleyi Arapça lehçelere çevir')
    # Asistan panelinin alttaki soru kutusu görünsün diye arkadaki karartılmış üst kısım kırpılır
    # İki telefon büyük ve hafif üst üste: arayüz okunur kalsın, alt boşluk dolsun
    c = put_phone(c, screen('ai.png', top=STATUS_END + 120, bottom=2336), 600, -24, y + 40)
    c = put_phone(c, screen('translate.png'), 600, 498, y + 190)
    return c.convert('RGB')


def main():
    os.makedirs(OUT, exist_ok=True)
    slides = [
        # Kartın alttaki "AI Asistan'a sor" düğmesi de görünsün diye telefon biraz küçük
        slide('blue', screen('verb.png'), ['Kelimeyi yaz,', 'her şey tek kartta'],
              'Arapça–Türkçe sözlük', pw=860),
        slide('navy', screen('emsile.png'), ['24 sığa ile', 'Emsile'],
              'Her fiilin bütün çekimleri tek ekranda'),
        slide('green', screen('quran.png'), ["Kur'an sözlüğü"],
              "Kelimenin ayetlerdeki anlamları, örnek ayetler ve meali"),
        slide_duo(),
    ]
    names = ['x_1_sozluk_karti.png', 'x_2_emsile.png', 'x_3_kuran.png', 'x_4_ai_ceviri.png']
    for img, name in zip(slides, names):
        img.save(os.path.join(OUT, name), optimize=True)
    print('tamam:', OUT)


if __name__ == '__main__':
    main()
