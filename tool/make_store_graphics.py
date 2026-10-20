"""Google Play mağaza görsellerini üretir (özellik grafiği + telefon ekran görüntüleri).

Kullanım (proje kökünde):  python tool/make_store_graphics.py <çıktı klasörü>

Ekranlar uygulamanın gerçek ekran görüntüleridir (assets/intro/*.webp); bu betik
yalnızca başlık, zemin ve telefon çerçevesi ekler. Çıktı:
  <klasör>/tr/01.png ... 08.png      1080x1920 telefon ekran görüntüleri
  <klasör>/en/01.png ... 08.png
  <klasör>/tr/feature.png            1024x500 özellik grafiği
  <klasör>/en/feature.png
  <klasör>/icon_512.png              512x512 uygulama simgesi
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else 'store_out'
INTRO = 'assets/intro'
INTER = 'assets/fonts/Inter-VariableFont_opsz,wght.ttf'

W, H = 1080, 1920

# Her ekran: (görsel, zemin üst renk, zemin alt renk, {dil: (başlık satırları, alt metin)})
SLIDES = [
    ('dictionary', (10, 96, 220), (0, 132, 255), {
        'tr': (['Arapça ↔ Türkçe', 'anında bul'], 'Yaklaşık 55.000 kelime, harekeli ve kök bilgisiyle'),
        'en': (['Arabic ↔ Turkish', 'in an instant'], 'Nearly 55,000 words with vowels and roots'),
    }),
    ('verb', (8, 84, 200), (30, 144, 255), {
        'tr': (['Fiil çekimleri ve', 'örnek cümleler'], 'Mazi, müzari, mastar ve emir tek kartta'),
        'en': (['Verb forms and', 'example sentences'], 'Past, present, verbal noun and imperative on one card'),
    }),
    ('emsile', (40, 62, 104), (74, 104, 160), {
        'tr': (['24 kalıpta', 'Emsile çekimi'], '5.500\'den fazla fiil, sığa sığa incele'),
        'en': (['Emsile in', '24 patterns'], 'Over 5,500 verbs, form by form'),
    }),
    ('quran', (40, 71, 32), (84, 120, 62), {
        'tr': (['Kur\'an sözlüğü'], 'Kelimenin ayetlerdeki anlamları ve örnek ayetler'),
        'en': (['Quran dictionary'], 'Word meanings in the verses, with example verses'),
    }),
    ('ai', (0, 110, 235), (88, 86, 214), {
        'tr': (['Yapay zekâ', 'asistanı'], 'Kelime hakkında sor, kısa ve net cevap al'),
        'en': (['Smart', 'assistant'], 'Ask about a word with AI and get a short, clear answer'),
    }),
    ('translate', (0, 120, 220), (0, 160, 200), {
        'tr': (['Çeviri ve 18', 'Arapça lehçe'], 'Türkçe ve 11 dil ile, okunuş destekli'),
        'en': (['Translate with 18', 'Arabic dialects'], 'Plus Turkish and 11 other languages, with pronunciation'),
    }),
    ('lists', (10, 96, 220), (0, 132, 255), {
        'tr': (['Kendi kelime', 'listelerin'], 'Kaydet, kartlarla çalış, listeni düzenle'),
        'en': (['Your own word', 'lists'], 'Save words, review with cards, organize your lists'),
    }),
    ('learn', (112, 78, 36), (168, 122, 66), {
        'tr': (['Arapça hikâyeler'], 'Oku, dinle, kelimeye dokunup anlamını gör'),
        'en': (['Arabic stories'], 'Read, listen, tap a word to see its meaning'),
    }),
]

FEATURE = {
    'tr': ('Kavaid', 'Arapça Türkçe Sözlük', ['Fiil çekimleri', 'Kur\'an sözlüğü', 'Çeviri']),
    'en': ('Kavaid', 'Arabic–Turkish Dictionary', ['Verb forms', 'Quran dictionary', 'Translate']),
}


def font(size, weight=700):
    f = ImageFont.truetype(INTER, size)
    f.set_variation_by_axes([min(32, max(14, size * 0.4)), weight])
    return f


def gradient(w, h, top, bottom):
    img = Image.new('RGB', (w, h))
    px = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        px.line([(0, y), (w, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img


def stars(img, alpha=26, cell=190, line=3):
    """Zemine çok silik sekiz köşeli yıldız örgüsü."""
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for row in range(-1, int(img.height / cell) + 2):
        for col in range(-1, int(img.width / cell) + 2):
            cx, cy = col * cell, row * cell
            r = cell * 0.40
            pts = []
            for i in range(16):
                rr = r if i % 2 == 0 else r * 0.72
                a = math.pi / 8 + i * math.pi / 8
                pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
            d.line(pts + [pts[0]], fill=(255, 255, 255, alpha), width=line, joint='curve')
            k, s = cell / 2, cell * 0.12
            mx, my = cx + k, cy + k
            d.line([(mx, my - s), (mx + s, my), (mx, my + s), (mx - s, my), (mx, my - s)],
                   fill=(255, 255, 255, alpha), width=line)
    base = img.convert('RGBA')
    base.alpha_composite(layer)
    return base.convert('RGB')


def rounded_mask(size, radius):
    m = Image.new('L', size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius, fill=255)
    return m


def phone(screen, width):
    """Ekran görüntüsünü yuvarlak köşeli koyu çerçeveye yerleştirir (gölgeli)."""
    bezel = max(14, width // 36)
    sw = width - 2 * bezel
    sh = int(screen.height * sw / screen.width)
    scr = screen.resize((sw, sh), Image.LANCZOS)
    outer_r = int(width * 0.115)
    inner_r = max(8, outer_r - bezel)
    total = (width, sh + 2 * bezel)
    body = Image.new('RGBA', total, (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle((0, 0, total[0] - 1, total[1] - 1), outer_r, fill=(17, 21, 28, 255))
    body.paste(scr.convert('RGBA'), (bezel, bezel), rounded_mask((sw, sh), inner_r))
    # Çok ince açık kenar
    ImageDraw.Draw(body).rounded_rectangle((0, 0, total[0] - 1, total[1] - 1), outer_r,
                                           outline=(255, 255, 255, 40), width=2)
    return body


def with_shadow(canvas, sprite, xy, blur=38, offset=(0, 26), opacity=120):
    sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    alpha = sprite.split()[3].point(lambda v: v * opacity // 255)
    shadow_sprite = Image.new('RGBA', sprite.size, (0, 0, 0, 255))
    shadow_sprite.putalpha(alpha)
    sh.paste(shadow_sprite, (xy[0] + offset[0], xy[1] + offset[1]), shadow_sprite)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    base = canvas.convert('RGBA')
    base.alpha_composite(sh)
    base.alpha_composite(sprite, xy)
    return base.convert('RGB')


def draw_centered(d, text, y, f, fill, width=W):
    w = d.textlength(text, font=f)
    d.text(((width - w) / 2, y), text, font=f, fill=fill)


def slide(lang, idx, spec):
    name, top, bottom, texts = spec
    heads, sub = texts[lang]
    img = stars(gradient(W, H, top, bottom))
    d = ImageDraw.Draw(img)
    y = 120
    hf = font(92, 800)
    for line in heads:
        draw_centered(d, line, y, hf, (255, 255, 255))
        y += 108
    sf = font(40, 500)
    # Alt metin uzunsa iki satıra böl
    words, lines, cur = sub.split(' '), [], ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if d.textlength(t, font=sf) > W - 160 and cur:
            lines.append(cur)
            cur = w
        else:
            cur = t
    lines.append(cur)
    y += 10
    for line in lines:
        draw_centered(d, line, y, sf, (255, 255, 255, 235))
        y += 54
    shot = Image.open(f'{INTRO}/{name}.webp').convert('RGB')
    pw = 790
    sprite = phone(shot, pw)
    py = max(y + 50, 440)
    img = with_shadow(img, sprite, ((W - pw) // 2, py))
    os.makedirs(f'{OUT}/{lang}', exist_ok=True)
    img.save(f'{OUT}/{lang}/{idx:02d}.png', 'PNG', optimize=True)
    return img.size


def feature(lang):
    fw, fh = 1024, 500
    title, sub, chips = FEATURE[lang]
    img = stars(gradient(fw, fh, (8, 92, 214), (20, 140, 255)), alpha=30, cell=150, line=2)
    d = ImageDraw.Draw(img)
    icon = Image.open('assets/images/app_icon.png').convert('RGBA').resize((132, 132), Image.LANCZOS)
    icon_bg = Image.new('RGBA', icon.size, (0, 0, 0, 0))
    icon_bg.paste(icon, (0, 0), rounded_mask(icon.size, 30))
    ImageDraw.Draw(icon_bg).rounded_rectangle((0, 0, icon.size[0] - 1, icon.size[1] - 1), 30,
                                              outline=(255, 255, 255, 235), width=5)
    img = with_shadow(img, icon_bg, (70, 92), blur=14, offset=(0, 8), opacity=90)
    d = ImageDraw.Draw(img)
    d.text((70, 250), title, font=font(84, 800), fill=(255, 255, 255))
    d.text((74, 352), sub, font=font(32, 600), fill=(255, 255, 255, 240))
    x = 74
    cf = font(21, 600)
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    for c in chips:
        tw = ld.textlength(c, font=cf)
        ld.rounded_rectangle((x, 424, x + tw + 30, 462), 19, fill=(255, 255, 255, 50),
                             outline=(255, 255, 255, 150), width=2)
        ld.text((x + 15, 431), c, font=cf, fill=(255, 255, 255, 255))
        x += tw + 30 + 10
    base = img.convert('RGBA')
    base.alpha_composite(layer)
    img = base.convert('RGB')
    # Sağ tarafta iki telefon, alttan taşarak
    left = phone(Image.open(f'{INTRO}/dictionary.webp').convert('RGB'), 232)
    right = phone(Image.open(f'{INTRO}/verb.webp').convert('RGB'), 232)
    right = right.rotate(-5, resample=Image.BICUBIC, expand=True)
    left = left.rotate(4, resample=Image.BICUBIC, expand=True)
    img = with_shadow(img, right, (770, 110), blur=22, offset=(0, 14), opacity=110)
    img = with_shadow(img, left, (560, 64), blur=22, offset=(0, 14), opacity=110)
    os.makedirs(f'{OUT}/{lang}', exist_ok=True)
    img.save(f'{OUT}/{lang}/feature.png', 'PNG', optimize=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    for lang in ('tr', 'en'):
        for i, spec in enumerate(SLIDES, start=1):
            slide(lang, i, spec)
        feature(lang)
    icon = Image.open('assets/images/app_icon.png').convert('RGBA').resize((512, 512), Image.LANCZOS)
    icon.save(f'{OUT}/icon_512.png', 'PNG', optimize=True)
    print('tamam:', OUT)


if __name__ == '__main__':
    main()
