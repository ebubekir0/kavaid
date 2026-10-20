"""X (Twitter) için 4 görselli (karusel) tanıtım gönderisi üretir.

Kullanım (proje kökünde):
  python tool/make_x_post.py <ekran görüntüsü klasörü> <çıktı klasörü>

Ekran görüntüsü klasöründe telefondan alınmış (1080x2340) şu dosyalar beklenir:
  verb.png (fiil çekimli sözlük kartı), emsile.png, quran.png, ai.png, translate.png

X 2026'dan beri çok görselli gönderileri kaydırılan karusel olarak, kırpmadan gösterir
(en fazla 4 görsel). Bu yüzden 4 dikey 4:5 (1080x1350) slayt üretilir; ilki markanın
mavisi, diğerleri her bölümün kendi renginde. Telefonun kendi durum çubuğu (saat,
bildirimler) temizlenip sade bir durum çubuğu çizilir.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw  # noqa: E402

import make_store_graphics as g  # noqa: E402

SHOTS = sys.argv[1] if len(sys.argv) > 1 else 'shots'
OUT = sys.argv[2] if len(sys.argv) > 2 else 'x_post'
W, H = 1080, 1350
STATUS_H = 108          # telefonun durum çubuğu yüksekliği (1080 genişlikte)
EDGE = 4                # ekran kaydı sırasında kenarda çıkan ince çerçeve

COLORS = {
    'blue': ((8, 84, 200), (20, 140, 255)),
    'navy': ((30, 46, 104), (66, 96, 170)),
    'green': ((16, 84, 58), (40, 138, 92)),
    'purple': ((62, 42, 160), (122, 82, 222)),
}


def clean(name):
    """Kenarları kırpar, durum çubuğunu sade bir çubukla değiştirir, kamera deliği ekler."""
    img = Image.open(os.path.join(SHOTS, name)).convert('RGB')
    img = img.crop((EDGE, EDGE, img.width - EDGE, img.height - EDGE))
    w = img.width
    bg = g._avg_color(img, (0, STATUS_H + 2, 24, STATUS_H + 10))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, w, STATUS_H), fill=bg)
    ink = (25, 25, 28) if g._is_light(bg) else (255, 255, 255)
    cy = STATUS_H // 2 + 2
    d.text((46, cy), '9:41', font=g.font(40, 600), fill=ink, anchor='lm')
    x = w - 250
    for i, h in enumerate((10, 16, 22, 28)):
        bx = x + i * 13
        d.rounded_rectangle((bx, cy + 14 - h, bx + 8, cy + 14), 2, fill=ink)
    wx, wy = w - 165, cy + 14
    for r in (28, 19, 10):
        d.arc((wx - r, wy - r, wx + r, wy + r), 225, 315, fill=ink, width=5)
    d.ellipse((wx - 4, wy - 4, wx + 4, wy + 4), fill=ink)
    bx0, bx1 = w - 115, w - 50
    d.rounded_rectangle((bx0, cy - 15, bx1, cy + 15), 8, outline=ink, width=3)
    d.rounded_rectangle((bx0 + 5, cy - 10, bx1 - 5, cy + 10), 5, fill=ink)
    d.rounded_rectangle((bx1 + 3, cy - 6, bx1 + 8, cy + 6), 2, fill=ink)
    d.ellipse((w / 2 - 17, cy - 17, w / 2 + 17, cy + 17), fill=(8, 8, 10))
    return img


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
    tf, sf = g.font(74, 800), g.font(36, 500)
    for s in title_lines:
        d.text(((W - d.textlength(s, font=tf)) / 2, y), s, font=tf, fill=(255, 255, 255))
        y += 86
    y += 6
    for s in wrap(sub, sf, W - 140):
        d.text(((W - d.textlength(s, font=sf)) / 2, y), s, font=sf, fill=(255, 255, 255, 235))
        y += 46
    return y


def pill(canvas, text, right_x, y, target, color):
    """Solda beyaz etiket, sağa doğru hedef noktaya ince çizgi."""
    f = g.font(26, 700)
    lines = wrap(text, f, 400)
    d = ImageDraw.Draw(canvas)
    tw = max(d.textlength(s, font=f) for s in lines)
    pw, ph = int(tw + 40), int(len(lines) * 34 + 24)
    x0, y0 = right_x - pw, y - ph / 2
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.line((right_x, y, target[0], target[1]), fill=(255, 255, 255, 230), width=4)
    ld.ellipse((target[0] - 10, target[1] - 10, target[0] + 10, target[1] + 10),
               fill=(255, 255, 255, 255), outline=color + (255,), width=5)
    ld.rounded_rectangle((x0, y0, x0 + pw, y0 + ph), 20, fill=(255, 255, 255, 245))
    for i, s in enumerate(lines):
        ld.text((x0 + 20, y0 + 12 + i * 34), s, font=f, fill=(12, 52, 130, 255))
    canvas.alpha_composite(layer)


def put_phone(canvas, shot, width, x, y):
    sprite = g.phone(shot, width)
    return g.with_shadow(canvas.convert('RGB'), sprite, (x, y), blur=30, offset=(0, 20),
                         opacity=115).convert('RGBA')


def slide_card():
    """1. slayt (mavi): fiil çekimli sözlük kartı ve özellik etiketleri."""
    c = background('blue')
    brand(c)
    header(c, ['Kelimeyi yaz,', 'her şey tek kartta'], 'Arapça–Türkçe sözlük')
    shot = clean('verb.png')
    pw, px, py = 560, 480, 390
    c = put_phone(c, shot, pw, px, py)
    bez = max(14, pw // 36)
    scale = (pw - 2 * bez) / shot.width

    def at(x, y):  # ekran görüntüsündeki (orijinal 1080 px) nokta -> tuval noktası
        return px + bez + (x - EDGE) * scale, py + bez + (y - EDGE) * scale

    for text, y in (('Kök ve kelime türü', 532),
                    ('Anlamlar ve harf-i cer', 690),
                    ('Mazi, müzari, mastar, emir', 930),
                    ('Tüm fiil çekimleri (24 sığa)', 1106),
                    ('Örnek cümleler ve Arapça ses', 1400),
                    ('Yapay zekâ asistanı', 1776)):
        tx, ty = at(26, y)
        pill(c, text, px - 26, ty, (tx, ty), COLORS['blue'][0])
    return c.convert('RGB')


def slide_single(color, shot_name, title_lines, sub, pw=640):
    c = background(color)
    brand(c)
    y = header(c, title_lines, sub)
    c = put_phone(c, clean(shot_name), pw, (W - pw) // 2, int(y) + 44)
    return c.convert('RGB')


def slide_duo():
    """4. slayt (mor): yapay zekâ asistanı ve çeviri, iki telefon."""
    c = background('purple')
    brand(c)
    y = header(c, ['Yapay zekâ', 've çeviri'], 'Kelimeyi sor, cümleyi Arapça lehçelere çevir')
    c = put_phone(c, clean('ai.png'), 450, 70, int(y) + 44)
    c = put_phone(c, clean('translate.png'), 450, 560, int(y) + 104)
    return c.convert('RGB')


def main():
    os.makedirs(OUT, exist_ok=True)
    slides = [
        slide_card(),
        slide_single('navy', 'emsile.png', ['24 sığa ile', 'Emsile'],
                     'Her fiilin bütün çekimleri tek ekranda'),
        slide_single('green', 'quran.png', ["Kur'an sözlüğü"],
                     "Kelimenin ayetlerdeki anlamları, örnek ayetler ve meali"),
        slide_duo(),
    ]
    names = ['x_1_sozluk_karti.png', 'x_2_emsile.png', 'x_3_kuran.png', 'x_4_ai_ceviri.png']
    for img, name in zip(slides, names):
        img.save(os.path.join(OUT, name), optimize=True)
    print('tamam:', OUT)


if __name__ == '__main__':
    main()
