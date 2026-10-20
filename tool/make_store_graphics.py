"""Google Play mağaza görsellerini üretir (özellik grafiği + telefon ekran görüntüleri).

Kullanım (proje kökünde):  python tool/make_store_graphics.py <çıktı klasörü>

Ekranlar uygulamanın gerçek ekran görüntüleridir (assets/intro/*.webp); bu betik
yalnızca başlık, zemin ve telefon çerçevesi ekler. Çıktı:
  <klasör>/<dil>/01.png ... 08.png   1080x1920 telefon ekran görüntüleri
  <klasör>/<dil>/feature.png         1024x500 özellik grafiği
  <klasör>/icon_512.png              512x512 uygulama simgesi
Diller: tr (Arapça–Türkçe), en (Arapça–İngilizce), ar (Arapça–Arapça).

Arapça yazı için Pillow'da raqm yoktur; harfler bu dosyadaki küçük şekillendirici
ile (Unicode sunum biçimleri + sağdan sola sıralama) çizilir. Windows'taki Segoe UI
(yoksa Arial/Tahoma) yazı tipini kullanır.
"""
import math
import os
import re
import sys
import unicodedata

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else 'store_out'
INTRO = 'assets/intro'
INTER = 'assets/fonts/Inter-VariableFont_opsz,wght.ttf'
WIN_FONTS = 'C:/Windows/Fonts/'

W, H = 1080, 1920

# Her ekran: (görsel, zemin üst renk, zemin alt renk, {dil: (başlık satırları, alt metin)})
SLIDES = [
    ('dictionary', (10, 96, 220), (0, 132, 255), {
        'tr': (['Arapça ↔ Türkçe', 'anında bul'], 'Yaklaşık 55.000 kelime, harekeli ve kök bilgisiyle'),
        'en': (['Arabic ↔ English', 'in an instant'], 'Nearly 55,000 words with vowels and roots'),
        'ar': (['قاموس عربي عربي', 'ابحث في لحظة'], 'نحو 55,000 كلمة مشكولة مع الجذر والمعنى'),
    }),
    ('verb', (8, 84, 200), (30, 144, 255), {
        'tr': (['Fiil çekimleri ve', 'örnek cümleler'], 'Mazi, müzari, mastar ve emir tek kartta'),
        'en': (['Verb forms and', 'example sentences'], 'Past, present, verbal noun and imperative on one card'),
        'ar': (['تصريف الأفعال', 'وجمل تمثيلية'], 'الماضي والمضارع والمصدر والأمر في بطاقة واحدة'),
    }),
    ('emsile', (40, 62, 104), (74, 104, 160), {
        'tr': (['24 kalıpta', 'Emsile çekimi'], '5.500\'den fazla fiil, sığa sığa incele'),
        'en': (['Emsile in', '24 patterns'], 'Over 5,500 verbs, form by form'),
        'ar': (['الأمثلة المختلفة', 'في 24 صيغة'], 'أكثر من 5,500 فعل، صيغة بعد صيغة'),
    }),
    ('quran', (40, 71, 32), (84, 120, 62), {
        'tr': (['Kur\'an sözlüğü'], 'Kelimenin ayetlerdeki anlamları ve örnek ayetler'),
        'en': (['Quran dictionary'], 'Word meanings in the verses, with example verses'),
        'ar': (['قاموس القرآن'], 'معاني الكلمة في الآيات مع آيات تمثيلية'),
    }),
    ('ai', (0, 110, 235), (88, 86, 214), {
        'tr': (['Yapay zekâ', 'asistanı'], 'Kelime hakkında sor, kısa ve net cevap al'),
        'en': (['Smart', 'assistant'], 'Ask about a word with AI and get a short, clear answer'),
        'ar': (['المساعد', 'الذكي'], 'اسأل عن أي كلمة واحصل على إجابة قصيرة وواضحة'),
    }),
    ('translate', (0, 120, 220), (0, 160, 200), {
        'tr': (['Çeviri ve 18', 'Arapça lehçe'], 'Türkçe ve 11 dil ile, okunuş destekli'),
        'en': (['Translate with 18', 'Arabic dialects'], 'Plus English and 11 other languages, with pronunciation'),
        'ar': (['ترجمة من 18', 'لهجة عربية'], 'وإلى الإنجليزية والتركية و10 لغات أخرى، مع النطق'),
    }),
    ('lists', (10, 96, 220), (0, 132, 255), {
        'tr': (['Kendi kelime', 'listelerin'], 'Kaydet, kartlarla çalış, listeni düzenle'),
        'en': (['Your own word', 'lists'], 'Save words, review with cards, organize your lists'),
        'ar': (['قوائمك', 'الخاصة'], 'احفظ الكلمات وراجعها بالبطاقات وأدر قوائمك'),
    }),
    ('learn', (112, 78, 36), (168, 122, 66), {
        'tr': (['Arapça hikâyeler'], 'Oku, dinle, kelimeye dokunup anlamını gör'),
        'en': (['Arabic stories'], 'Read, listen, tap a word to see its meaning'),
        'ar': (['قصص عربية'], 'اقرأ واستمع، وانقر على الكلمة لترى معناها'),
    }),
]

FEATURE = {
    'tr': ('Kavaid', 'Arapça Türkçe Sözlük', ['Fiil çekimleri', 'Kur\'an sözlüğü', 'Çeviri']),
    'en': ('Kavaid', 'Arabic–English Dictionary', ['Verb forms', 'Quran dictionary', 'Translate']),
    'ar': ('كوايد', 'قاموس عربي عربي', ['تصريف الأفعال', 'قاموس القرآن', 'الترجمة']),
}

# --- Arapça şekillendirme -------------------------------------------------

_FORMS = {}
_LIGA = {}
for _cp in range(0xFE70, 0xFEFD):
    _dec = unicodedata.decomposition(chr(_cp))
    if not _dec.startswith('<'):
        continue
    _tag, *_rest = _dec.split()
    _base = ''.join(chr(int(x, 16)) for x in _rest)
    if len(_base) == 1:
        _FORMS.setdefault(_base, {})[_tag.strip('<>')] = chr(_cp)
    elif len(_base) == 2 and _base[0] == '\u0644':
        _LIGA.setdefault(_base, {})[_tag.strip('<>')] = chr(_cp)

_RIGHT_ONLY = set('\u0627\u0623\u0625\u0622\u0671\u062f\u0630\u0631\u0632\u0648\u0624\u0629\u0649')
_NON_JOIN = set('\u0621')
_ALEFS = set('\u0627\u0623\u0625\u0622')
_LTR_RUN = re.compile(r'[0-9A-Za-z][0-9A-Za-z,.%+\-/]*')


def _shape(seg):
    out = []
    i, n = 0, len(seg)
    while i < n:
        c = seg[i]
        if c not in _FORMS:
            out.append(c)
            i += 1
            continue
        prev = seg[i - 1] if i > 0 else ''
        prev_joined = (c not in _NON_JOIN and prev in _FORMS
                       and prev not in _RIGHT_ONLY and prev not in _NON_JOIN)
        if c == '\u0644' and i + 1 < n and seg[i + 1] in _ALEFS:
            forms = _LIGA['\u0644' + seg[i + 1]]
            out.append(forms['final'] if prev_joined else forms['isolated'])
            i += 2
            continue
        nxt = seg[i + 1] if i + 1 < n else ''
        next_joined = (c not in _RIGHT_ONLY and c not in _NON_JOIN
                       and nxt in _FORMS and nxt not in _NON_JOIN)
        key = ('medial' if prev_joined and next_joined else 'final' if prev_joined
               else 'initial' if next_joined else 'isolated')
        out.append(_FORMS[c].get(key) or _FORMS[c]['isolated'])
        i += 1
    return ''.join(out)


def visual(text):
    """Mantıksal Arapça metni, Pillow'un soldan sağa çizeceği görsel sıraya çevirir.
    Rakam ve Latin harf öbekleri soldan sağa kalır."""
    segs, pos = [], 0
    for m in _LTR_RUN.finditer(text):
        if m.start() > pos:
            segs.append((False, text[pos:m.start()]))
        segs.append((True, m.group()))
        pos = m.end()
    if pos < len(text):
        segs.append((False, text[pos:]))
    return ''.join(s if ltr else _shape(s)[::-1] for ltr, s in reversed(segs))


def vis(lang, text):
    return visual(text) if lang == 'ar' else text


def _first_font(names):
    for n in names:
        if os.path.exists(WIN_FONTS + n):
            return WIN_FONTS + n
    raise SystemExit('Arapça yazı tipi bulunamadı: ' + ', '.join(names))


def font(size, weight=700, lang='tr'):
    if lang == 'ar':
        if weight >= 700:
            names = ['segoeuib.ttf', 'arialbd.ttf', 'tahomabd.ttf']
        elif weight >= 600:
            names = ['seguisb.ttf', 'segoeuib.ttf', 'arialbd.ttf']
        else:
            names = ['segoeui.ttf', 'arial.ttf', 'tahoma.ttf']
        return ImageFont.truetype(_first_font(names), size)
    f = ImageFont.truetype(INTER, size)
    f.set_variation_by_axes([min(32, max(14, size * 0.4)), weight])
    return f


# --- Çizim yardımcıları ---------------------------------------------------

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


def _avg_color(img, box):
    px = img.crop(box).resize((1, 1), Image.BOX).getpixel((0, 0))
    return tuple(px[:3])


def _is_light(rgb):
    return (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) > 150


def iphone(screen, width):
    """iPhone 15 Pro benzeri çerçeve: Dynamic Island, durum çubuğu, ana ekran çizgisi ve
    yan tuşlar. Uygulama ekran görüntüsü durum çubuğu ile ana ekran çizgisi arasına girer.
    Boyutlar 393x852 pt'lik ekran üzerinden ölçeklenir."""
    btn = max(4, round(width * 0.007))          # yan tuşların dışarı taşan kısmı
    frame = round(width * 0.030)                 # titanyum + siyah çerçeve
    sw = width - 2 * frame
    k = sw / 393.0
    top_h, sh = round(59 * k), round(852 * k)
    content_h = min(round(sw * screen.height / screen.width), sh - top_h - round(20 * k))
    bottom_h = sh - top_h - content_h
    shot = screen.convert('RGB').resize((sw, round(sw * screen.height / screen.width)), Image.LANCZOS)
    shot = shot.crop((0, 0, sw, content_h))

    top_bg = _avg_color(shot, (0, 0, sw, 8))
    bot_bg = _avg_color(shot, (0, content_h - 8, sw, content_h))
    scr = Image.new('RGB', (sw, sh), top_bg)
    scr.paste(Image.new('RGB', (sw, bottom_h), bot_bg), (0, top_h + content_h))
    scr.paste(shot, (0, top_h))
    d = ImageDraw.Draw(scr)

    ink = (20, 20, 22) if _is_light(top_bg) else (255, 255, 255)
    cy = round(30 * k)                           # durum çubuğu satırının ortası
    # Saat
    tf = font(round(17 * k), 700)
    t = '9:41'
    d.text((round(70 * k) - d.textlength(t, font=tf) / 2, cy), t, font=tf, fill=ink, anchor='lm')
    # Sinyal çubukları
    x = round(297 * k)
    for i, h in enumerate((4, 6, 8.5, 11)):
        bx = x + round(i * 4.6 * k)
        d.rounded_rectangle((bx, cy + round(5.5 * k) - round(h * k), bx + round(3 * k), cy + round(5.5 * k)),
                            round(1 * k), fill=ink)
    # Wi-Fi
    wx, wy = round(331 * k), cy + round(6 * k)
    for r in (11, 7.2, 3.4):
        rr = round(r * k)
        d.arc((wx - rr, wy - rr, wx + rr, wy + rr), 228, 312, fill=ink, width=max(2, round(2.2 * k)))
    d.ellipse((wx - round(1.6 * k), wy - round(1.6 * k), wx + round(1.6 * k), wy + round(1.6 * k)), fill=ink)
    # Pil
    bx0, bx1 = round(348 * k), round(373 * k)
    by0, by1 = cy - round(6 * k), cy + round(6 * k)
    d.rounded_rectangle((bx0, by0, bx1, by1), round(3.6 * k), outline=ink, width=max(2, round(1.1 * k)))
    d.rounded_rectangle((bx0 + round(2 * k), by0 + round(2 * k), bx1 - round(2 * k), by1 - round(2 * k)),
                        round(2 * k), fill=ink)
    d.rounded_rectangle((bx1 + round(1.6 * k), cy - round(2.2 * k), bx1 + round(3.2 * k), cy + round(2.2 * k)),
                        round(0.8 * k), fill=ink)
    # Dynamic Island
    d.rounded_rectangle((sw / 2 - 63 * k, 11 * k, sw / 2 + 63 * k, 48 * k), 18.5 * k, fill=(0, 0, 0))
    # Ana ekran çizgisi
    hi = (20, 20, 22) if _is_light(bot_bg) else (255, 255, 255)
    d.rounded_rectangle((sw / 2 - 67 * k, sh - 13 * k, sw / 2 + 67 * k, sh - 8 * k), 2.5 * k, fill=hi)

    total_w, total_h = width + 2 * btn, sh + 2 * frame
    body = Image.new('RGBA', (total_w, total_h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    metal = (70, 71, 76, 255)
    # Yan tuşlar (gövdenin arkasında)
    for y0, h in ((118, 26), (172, 52), (240, 52)):          # sol: eylem, ses +, ses -
        bd.rounded_rectangle((0, frame + round(y0 * k), btn + frame, frame + round((y0 + h) * k)),
                             round(2 * k), fill=metal)
    bd.rounded_rectangle((total_w - btn - frame, frame + round(200 * k), total_w, frame + round(290 * k)),
                         round(2 * k), fill=metal)                  # sağ: güç
    outer_r = round(55 * k) + frame
    bd.rounded_rectangle((btn, 0, btn + width - 1, total_h - 1), outer_r, fill=metal)
    band = round(frame * 0.42)
    bd.rounded_rectangle((btn + band, band, btn + width - 1 - band, total_h - 1 - band),
                         outer_r - band, fill=(6, 6, 8, 255))
    mask = Image.new('L', (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), round(55 * k), fill=255)
    body.paste(scr.convert('RGBA'), (btn + frame, frame), mask)
    bd.rounded_rectangle((btn, 0, btn + width - 1, total_h - 1), outer_r, outline=(255, 255, 255, 46), width=2)
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


def wrap(d, lang, text, f, max_w):
    """Mantıksal kelimeleri satırlara böler; genişlik görsel dizgiyle ölçülür."""
    lines, cur = [], ''
    for w in text.split(' '):
        t = (cur + ' ' + w).strip()
        if d.textlength(vis(lang, t), font=f) > max_w and cur:
            lines.append(cur)
            cur = w
        else:
            cur = t
    lines.append(cur)
    return lines


def slide(lang, idx, spec, canvas=(W, H), pw=790, subdir=None, target=None, mock=None):
    """Telefon ekran görüntüsü. `canvas` mantıksal boyuttur; `target` verilirse sonuç bu
    boyuta ölçeklenir. `mock` verilirse (ör. iphone) telefon çerçevesi olarak o kullanılır
    ve telefon, tuvale sığacak şekilde `pw` genişliğine kadar küçültülür."""
    name, top, bottom, texts = spec
    cw, ch = canvas
    heads, sub = texts[lang]
    img = stars(gradient(cw, ch, top, bottom))
    d = ImageDraw.Draw(img)
    y = 120
    hf = font(92, 800, lang)
    for line in heads:
        draw_centered(d, vis(lang, line), y, hf, (255, 255, 255), cw)
        y += 108
    sf = font(40, 500, lang)
    y += 10
    for line in wrap(d, lang, sub, sf, cw - 160):
        draw_centered(d, vis(lang, line), y, sf, (255, 255, 255, 235), cw)
        y += 54
    shot = Image.open(f'{INTRO}/{name}.webp').convert('RGB')
    py = max(y + 50, 440)
    if mock:
        probe = mock(shot, 1000)
        pw = min(pw, int(1000 * (ch - py - 60) / probe.height))
        sprite = mock(shot, pw)
    else:
        sprite = phone(shot, pw)
    img = with_shadow(img, sprite, ((cw - sprite.width) // 2, py))
    if target:
        img = img.resize(target, Image.LANCZOS)
    folder = f'{OUT}/{subdir}/{lang}' if subdir else f'{OUT}/{lang}'
    os.makedirs(folder, exist_ok=True)
    img.save(f'{folder}/{idx:02d}.png', 'PNG', optimize=True)
    return img.size


def feature(lang):
    fw, fh = 1024, 500
    rtl = lang == 'ar'
    title, sub, chips = FEATURE[lang]
    img = stars(gradient(fw, fh, (8, 92, 214), (20, 140, 255)), alpha=30, cell=150, line=2)
    icon = Image.open('assets/images/app_icon.png').convert('RGBA').resize((132, 132), Image.LANCZOS)
    icon_bg = Image.new('RGBA', icon.size, (0, 0, 0, 0))
    icon_bg.paste(icon, (0, 0), rounded_mask(icon.size, 30))
    ImageDraw.Draw(icon_bg).rounded_rectangle((0, 0, icon.size[0] - 1, icon.size[1] - 1), 30,
                                              outline=(255, 255, 255, 235), width=5)
    icon_x = fw - 70 - 132 if rtl else 70
    img = with_shadow(img, icon_bg, (icon_x, 92), blur=14, offset=(0, 8), opacity=90)
    d = ImageDraw.Draw(img)

    def put(text, y, f, fill, pad):
        text = vis(lang, text)
        x = fw - pad - d.textlength(text, font=f) if rtl else pad
        d.text((x, y), text, font=f, fill=fill)

    put(title, 232 if rtl else 250, font(84, 800, lang), (255, 255, 255), 70)
    put(sub, 346 if rtl else 352, font(32, 600, lang), (255, 255, 255, 240), 74)

    cf = font(21, 600, lang)
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    x = fw - 74 if rtl else 74
    for c in chips:
        c = vis(lang, c)
        tw = ld.textlength(c, font=cf)
        x0 = x - (tw + 30) if rtl else x
        ld.rounded_rectangle((x0, 424, x0 + tw + 30, 462), 19, fill=(255, 255, 255, 50),
                             outline=(255, 255, 255, 150), width=2)
        ld.text((x0 + 15, 427 if rtl else 431), c, font=cf, fill=(255, 255, 255, 255))
        x = x0 - 10 if rtl else x0 + tw + 30 + 10
    base = img.convert('RGBA')
    base.alpha_composite(layer)
    img = base.convert('RGB')
    # Telefonlar, alttan taşarak (sağdan sola dilde sol tarafa aynalanır)
    front = phone(Image.open(f'{INTRO}/dictionary.webp').convert('RGB'), 232)
    back = phone(Image.open(f'{INTRO}/verb.webp').convert('RGB'), 232)
    if rtl:
        back = back.rotate(5, resample=Image.BICUBIC, expand=True)
        front = front.rotate(-4, resample=Image.BICUBIC, expand=True)
        img = with_shadow(img, back, (fw - 770 - back.width, 110), blur=22, offset=(0, 14), opacity=110)
        img = with_shadow(img, front, (fw - 560 - front.width, 64), blur=22, offset=(0, 14), opacity=110)
    else:
        back = back.rotate(-5, resample=Image.BICUBIC, expand=True)
        front = front.rotate(4, resample=Image.BICUBIC, expand=True)
        img = with_shadow(img, back, (770, 110), blur=22, offset=(0, 14), opacity=110)
        img = with_shadow(img, front, (560, 64), blur=22, offset=(0, 14), opacity=110)
    os.makedirs(f'{OUT}/{lang}', exist_ok=True)
    img.save(f'{OUT}/{lang}/feature.png', 'PNG', optimize=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    for lang in ('tr', 'en', 'ar'):
        for i, spec in enumerate(SLIDES, start=1):
            slide(lang, i, spec)
            # App Store iPhone 6.3" (1206x2622); diğer ekran boyutlarına App Store ölçekler
            slide(lang, i, spec, canvas=(1080, 2348), pw=1000, subdir='ios', target=(1206, 2622), mock=iphone)
        feature(lang)
    icon = Image.open('assets/images/app_icon.png').convert('RGBA').resize((512, 512), Image.LANCZOS)
    icon.save(f'{OUT}/icon_512.png', 'PNG', optimize=True)
    print('tamam:', OUT)


if __name__ == '__main__':
    main()
