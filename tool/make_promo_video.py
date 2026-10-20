"""Sosyal medya için kısa tanıtım videosu üretir (X, Instagram, TikTok).

Kullanım (proje kökünde):  python tool/make_promo_video.py <çıktı klasörü>

Çıktı:
  <klasör>/kavaid_tanitim_4x5.mp4    1080x1350, 15 sn, sessiz (X ve Instagram akışı)
  <klasör>/kavaid_tanitim_9x16.mp4   1080x1920, 15 sn, sessiz (Reels, TikTok, hikâye)
  <klasör>/kavaid_post_4x5.png       aynı tasarımın tek kare hâli (görselli post için)

Ekranlar uygulamanın gerçek ekran görüntüleridir (assets/intro/*.webp); telefon
çerçevesi ve zemin make_store_graphics.py ile aynıdır. Kodlama için PATH'te ffmpeg
(libx264) gerekir.
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw, ImageFilter  # noqa: E402

import make_store_graphics as g  # noqa: E402

OUT = sys.argv[1] if len(sys.argv) > 1 else 'promo_out'
FPS = 30
DURATION = 15.0

SCENES = [  # (ekran, başlık, alt metin, sahne başlangıcı, sahne sonu)
    ('dictionary', 'Yaz, anında bul', 'Harekesi, kökü ve çoğulu tek kartta', 2.3, 5.9),
    ('verb', 'Fiil çekimleri', 'Örnek cümleler ve Arapça seslendirme', 5.4, 9.0),
    ('emsile', '24 sığa ile Emsile', 'Her fiilin çekimleri tek dokunuşta', 8.5, 12.1),
]
HOOK = ['Arapça bir kelimeye', 'mi takıldın?']
END = ('Kavaid', 'Arapça Türkçe Sözlük', ['Emsile', "Kur'an sözlüğü", 'Çeviri'],
       "App Store ve Google Play'de ücretsiz")


def ease_out(t):
    t = min(1.0, max(0.0, t))
    return 1 - (1 - t) ** 3


def ease_in_out(t):
    t = min(1.0, max(0.0, t))
    return 4 * t ** 3 if t < 0.5 else 1 - (-2 * t + 2) ** 3 / 2


def progress(t, a, b):
    return 0.0 if b <= a else min(1.0, max(0.0, (t - a) / (b - a)))


def text_layer(lines, size, weight, color=(255, 255, 255, 255), gap=1.18, width=None):
    """Ortalanmış çok satırlı yazıyı şeffaf bir katmana çizer."""
    f = g.font(size, weight)
    probe = ImageDraw.Draw(Image.new('RGBA', (1, 1)))
    w = width or int(max(probe.textlength(s, font=f) for s in lines)) + 20
    h = int(size * gap * len(lines) + size * 0.4)
    layer = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i, s in enumerate(lines):
        d.text(((w - d.textlength(s, font=f)) / 2, i * size * gap), s, font=f, fill=color)
    return layer


def shadowed(sprite, blur=30, offset=(0, 20), opacity=110):
    """Gölgeyi bir kez hesaplayıp sprite ile birlikte dolgulu tek katman yapar."""
    pad = blur * 3
    w, h = sprite.size
    out = Image.new('RGBA', (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    alpha = sprite.getchannel('A').point(lambda v: v * opacity // 255)
    shadow = Image.new('RGBA', sprite.size, (0, 0, 0, 255))
    shadow.putalpha(alpha)
    out.paste(shadow, (pad + offset[0], pad + offset[1]), shadow)
    out = out.filter(ImageFilter.GaussianBlur(blur))
    out.alpha_composite(sprite, (pad, pad))
    return out, pad


def put(base, layer, x, y, opacity=1.0):
    """Katmanı (x, y) noktasına saydamlıkla koyar; tuval dışına taşan kısmı kırpar."""
    if opacity <= 0.01:
        return
    x, y = int(round(x)), int(round(y))
    sx, sy = max(0, -x), max(0, -y)
    dx, dy = max(0, x), max(0, y)
    w = min(layer.width - sx, base.width - dx)
    h = min(layer.height - sy, base.height - dy)
    if w <= 0 or h <= 0:
        return
    part = layer.crop((sx, sy, sx + w, sy + h))
    if opacity < 0.99:
        part.putalpha(part.getchannel('A').point(lambda v: int(v * opacity)))
    base.alpha_composite(part, (dx, dy))


def icon_layer(size, radius):
    icon = Image.open('assets/images/app_icon.png').convert('RGBA').resize((size, size), Image.LANCZOS)
    out = Image.new('RGBA', icon.size, (0, 0, 0, 0))
    out.paste(icon, (0, 0), g.rounded_mask(icon.size, radius))
    ImageDraw.Draw(out).rounded_rectangle((0, 0, size - 1, size - 1), radius,
                                          outline=(255, 255, 255, 235), width=max(4, size // 30))
    return shadowed(out, blur=14, offset=(0, 8), opacity=90)


def chips_layer(chips, size):
    f = g.font(size, 600)
    probe = ImageDraw.Draw(Image.new('RGBA', (1, 1)))
    padx, h, gap = int(size * 0.8), int(size * 1.9), int(size * 0.5)
    widths = [int(probe.textlength(c, font=f)) + 2 * padx for c in chips]
    layer = Image.new('RGBA', (sum(widths) + gap * (len(chips) - 1) + 4, h + 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x = 2
    for c, w in zip(chips, widths):
        d.rounded_rectangle((x, 2, x + w, 2 + h), h // 2, fill=(255, 255, 255, 46),
                            outline=(255, 255, 255, 150), width=2)
        d.text((x + padx, 2 + h / 2), c, font=f, fill=(255, 255, 255, 255), anchor='lm')
        x += w + gap
    return layer


def build(width, height, name, still_at=None):
    tall = height / width > 1.5
    bg = g.stars(g.gradient(width, height, (8, 84, 200), (20, 140, 255)), alpha=26, cell=170)
    bg = bg.convert('RGBA')

    # Açılış
    icon, icon_pad = icon_layer(150, 34)
    hook = text_layer(HOOK, 96, 800)
    hook_y = height * (0.40 if tall else 0.36)

    # Sahneler
    phone_w = 700 if tall else 600
    cap_y = 130 if tall else 95
    phone_y = 520 if tall else 395
    scenes = []
    for shot, title, sub, a, b in SCENES:
        img = Image.open(f'{g.INTRO}/{shot}.webp').convert('RGB')
        sprite, pad = shadowed(g.iphone(img, phone_w))
        cap = text_layer([title], 84, 800)
        subl = text_layer([sub], 42, 500, color=(255, 255, 255, 235))
        scenes.append((sprite, pad, cap, subl, a, b))

    # Kapanış
    t_name, t_sub, t_chips, t_cta = END
    end_icon, end_pad = icon_layer(190, 44)
    end_name = text_layer([t_name], 124, 800)
    end_sub = text_layer([t_sub], 54, 600)
    end_chips = chips_layer(t_chips, 30)
    end_cta = text_layer([t_cta], 40, 500, color=(255, 255, 255, 235))
    end_top = (height - 680) / 2  # kapanış bloğu (~680 px) dikeyde ortalı

    def frame(t):
        f = bg.copy()
        cx = width / 2
        # 1) Açılış: ikon ve soru
        enter = ease_out(progress(t, 0.0, 0.6))
        leave = ease_in_out(progress(t, 2.0, 2.45))
        op = enter * (1 - leave)
        put(f, icon, cx - icon.width / 2, hook_y - 230 - icon_pad + 30 * (1 - enter) - 60 * leave, op)
        put(f, hook, cx - hook.width / 2, hook_y + 40 * (1 - enter) - 60 * leave,
            ease_out(progress(t, 0.2, 0.8)) * (1 - leave))
        # 2) Ekranlar: alttan / sağdan gelir, sola çıkar
        for i, (sprite, pad, cap, subl, a, b) in enumerate(scenes):
            if t < a - 0.01 or t > b + 0.01:
                continue
            last = i == len(scenes) - 1
            ein = ease_out(progress(t, a, a + 0.6))
            eout = ease_in_out(progress(t, b - 0.5, b))
            base_x = cx - sprite.width / 2
            base_y = phone_y - pad
            drift = -18 * progress(t, a + 0.6, b - 0.5)
            if i == 0:
                x, y = base_x, base_y + (height - phone_y) * (1 - ein)
            else:
                x, y = base_x + width * (1 - ein), base_y
            if last:
                y += 140 * eout
                pop = 1 - eout
            else:
                x -= width * eout
                pop = 1.0
            put(f, sprite, x, y + drift, pop)
            cop = ease_out(progress(t, a + 0.15, a + 0.6)) * (1 - ease_in_out(progress(t, b - 0.55, b - 0.2)))
            put(f, cap, cx - cap.width / 2, cap_y + 16 * (1 - cop), cop)
            put(f, subl, cx - subl.width / 2, cap_y + 104 + 16 * (1 - cop), cop)
        # 3) Kapanış kartı
        e = ease_out(progress(t, 11.9, 12.6))
        if e > 0:
            y0 = end_top + 40 * (1 - e)
            put(f, end_icon, cx - end_icon.width / 2, y0 - end_pad, e)
            y1 = y0 + 190 + 40
            put(f, end_name, cx - end_name.width / 2, y1, e)
            put(f, end_sub, cx - end_sub.width / 2, y1 + 150, ease_out(progress(t, 12.1, 12.8)))
            put(f, end_chips, cx - end_chips.width / 2, y1 + 250, ease_out(progress(t, 12.3, 13.0)))
            put(f, end_cta, cx - end_cta.width / 2, y1 + 360, ease_out(progress(t, 12.5, 13.2)))
        return f.convert('RGB')

    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    cmd = ['ffmpeg', '-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24',
           '-s', f'{width}x{height}', '-r', str(FPS), '-i', '-',
           '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p',
           '-movflags', '+faststart', path]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    for i in range(int(DURATION * FPS)):
        proc.stdin.write(frame(i / FPS).tobytes())
    proc.stdin.close()
    if proc.wait() != 0:
        raise SystemExit('ffmpeg hata verdi')
    if still_at is not None:
        frame(still_at).save(os.path.join(OUT, name.replace('tanitim', 'post').replace('.mp4', '.png')))
    print('tamam:', path)


if __name__ == '__main__':
    build(1080, 1350, 'kavaid_tanitim_4x5.mp4', still_at=4.2)
    build(1080, 1920, 'kavaid_tanitim_9x16.mp4')
