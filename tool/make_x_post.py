"""X (Twitter) için 3 görselli tanıtım gönderisi üretir.

Kullanım (proje kökünde):
  python tool/make_x_post.py <ekran görüntüsü klasörü> <çıktı klasörü>

Ekran görüntüsü klasöründe telefondan alınmış (1080x2340) şu dosyalar beklenir:
  verb.png (fiil çekimli sözlük kartı), emsile.png, quran.png, ai.png, translate.png

X'te 3 görselli gönderi: solda büyük dikey görsel (7:8), sağda üst üste iki yatay görsel
(16:9). Bu yüzden ana görsel 1400x1600, diğer ikisi 1600x900 üretilir. Telefonun kendi
durum çubuğu (saat, bildirimler) temizlenip sade bir durum çubuğu çizilir.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw  # noqa: E402

import make_store_graphics as g  # noqa: E402

SHOTS = sys.argv[1] if len(sys.argv) > 1 else 'shots'
OUT = sys.argv[2] if len(sys.argv) > 2 else 'x_post'
STATUS_H = 108          # telefonun durum çubuğu yüksekliği (1080 genişlikte)
EDGE = 4                # ekran kaydı sırasında kenarda çıkan ince çerçeve


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
    # Sağda sinyal, Wi-Fi, pil
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
    # Kamera deliği
    d.ellipse((w / 2 - 17, cy - 17, w / 2 + 17, cy + 17), fill=(8, 8, 10))
    return img


def background(w, h):
    return g.stars(g.gradient(w, h, (8, 84, 200), (20, 140, 255)), alpha=26, cell=170).convert('RGBA')


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


def brand(canvas, x, y, size=64, center=False):
    icon = Image.open('assets/images/app_icon.png').convert('RGBA').resize((size, size), Image.LANCZOS)
    ic = Image.new('RGBA', icon.size, (0, 0, 0, 0))
    ic.paste(icon, (0, 0), g.rounded_mask(icon.size, size // 4))
    f = g.font(int(size * 0.62), 800)
    d = ImageDraw.Draw(canvas)
    tw = d.textlength('Kavaid', font=f)
    if center:
        x = x - (size + 16 + tw) / 2
    canvas.alpha_composite(ic, (int(x), int(y)))
    d.text((x + size + 16, y + size / 2), 'Kavaid', font=f, fill=(255, 255, 255), anchor='lm')


def pill(canvas, text, anchor_xy, side, target, max_w=300):
    """Beyaz etiket ve hedef noktaya ince bir çizgi. side: 'left' ya da 'right'."""
    f = g.font(28, 700)
    lines = wrap(text, f, max_w - 44)
    d = ImageDraw.Draw(canvas)
    tw = max(d.textlength(s, font=f) for s in lines)
    pw, ph = int(tw + 44), int(len(lines) * 36 + 26)
    ax, ay = anchor_xy
    x0 = ax - pw if side == 'left' else ax
    y0 = ay - ph / 2
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    edge_x = x0 + pw if side == 'left' else x0
    ld.line((edge_x, ay, target[0], target[1]), fill=(255, 255, 255, 230), width=4)
    ld.ellipse((target[0] - 11, target[1] - 11, target[0] + 11, target[1] + 11),
               fill=(255, 255, 255, 255), outline=(10, 96, 220, 255), width=5)
    ld.rounded_rectangle((x0, y0, x0 + pw, y0 + ph), 20, fill=(255, 255, 255, 245))
    for i, s in enumerate(lines):
        ld.text((x0 + 22, y0 + 13 + i * 36), s, font=f, fill=(12, 52, 130, 255))
    canvas.alpha_composite(layer)


def main_image():
    W, H = 1400, 1600
    c = background(W, H)
    brand(c, W / 2, 46, 64, center=True)
    d = ImageDraw.Draw(c)
    hf = g.font(70, 800)
    head = 'Kelimeyi yaz, her şey tek kartta'
    d.text(((W - d.textlength(head, font=hf)) / 2, 140), head, font=hf, fill=(255, 255, 255))
    sf = g.font(34, 500)
    sub = 'Arapça–Türkçe sözlük: 55.000 harekeli kelime'
    d.text(((W - d.textlength(sub, font=sf)) / 2, 232), sub, font=sf, fill=(255, 255, 255, 235))

    shot = clean('verb.png')
    pw, px, py = 640, (W - 640) // 2, 300
    sprite = g.phone(shot, pw)
    c = g.with_shadow(c.convert('RGB'), sprite, (px, py)).convert('RGBA')
    bez = max(14, pw // 36)
    scale = (pw - 2 * bez) / shot.width

    def at(x, y):  # ekran görüntüsündeki (orijinal 1080 px) nokta -> tuval noktası
        return px + bez + (x - EDGE) * scale, py + bez + (y - EDGE) * scale

    # Çizgiler kartın kenarında biter; arayüzdeki simgelerin üstünü kapatmaz.
    L, R = 360, W - 360
    card_l, card_r = 26, 1053
    for text, side, y in (
            ('Kök ve kelime türü', 'left', 532),
            ('Mazi, müzari, mastar ve emir', 'left', 930),
            ('Örnek cümleler ve Arapça ses', 'left', 1400),
            ('Yapay zekâ, seslendirme ve kaydetme', 'right', 528),
            ('Tüm fiil çekimleri (24 sığa)', 'right', 1106),
            ('AI ile daha fazla örnek', 'right', 1776)):
        tx, ty = at(card_l if side == 'left' else card_r, y)
        pill(c, text, (L if side == 'left' else R, ty), side, (tx, ty))
    return c.convert('RGB')


def duo_image(left, right):
    W, H = 1600, 900
    c = background(W, H)
    for i, (shot_name, title, sub) in enumerate((left, right)):
        hx = i * 800
        shot = clean(shot_name)
        sprite = g.phone(shot, 380)
        c = g.with_shadow(c.convert('RGB'), sprite, (hx + 50, 44), blur=26, offset=(0, 16),
                          opacity=110).convert('RGBA')
        d = ImageDraw.Draw(c)
        tf, sf = g.font(52, 800), g.font(30, 500)
        tl = wrap(title, tf, 300)
        sl = wrap(sub, sf, 300)
        block = len(tl) * 62 + 18 + len(sl) * 42
        y = (H - block) / 2 - 20
        for s in tl:
            d.text((hx + 470, y), s, font=tf, fill=(255, 255, 255))
            y += 62
        y += 18
        for s in sl:
            d.text((hx + 470, y), s, font=sf, fill=(255, 255, 255, 235))
            y += 42
    brand(c, W - 260, H - 92, 52)
    return c.convert('RGB')


def main():
    os.makedirs(OUT, exist_ok=True)
    main_image().save(os.path.join(OUT, 'x_1_sozluk_karti.png'), optimize=True)
    duo_image(('emsile.png', '24 sığa ile Emsile',
               'Her fiilin ism-i fâil, mastar, nehy, emir… tüm çekimleri tek ekranda.'),
              ('quran.png', "Kur'an sözlüğü",
               "Kelimenin Kur'an'daki anlamları ve örnek ayetler, Türkçe mealiyle.")
              ).save(os.path.join(OUT, 'x_2_emsile_kuran.png'), optimize=True)
    duo_image(('ai.png', 'Yapay zekâ asistanı',
               'Kelimeyi sor: kullanımı, örnek cümleler, benzerlerinden farkı.'),
              ('translate.png', 'Lehçelerle çeviri',
               'Standart Arapça ve 17 lehçe; okunuşu ve sesiyle birlikte.')
              ).save(os.path.join(OUT, 'x_3_ai_ceviri.png'), optimize=True)
    print('tamam:', OUT)


if __name__ == '__main__':
    main()
