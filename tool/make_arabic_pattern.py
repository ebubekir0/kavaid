"""Ana ekranın hafif Arapça harf desenini üretir (beyaz harfler, saydam zemin).

Kullanım (proje kökünde): python tool/make_arabic_pattern.py

Uygulama görseli temaya göre renklendirir (açık: mavi, koyu: beyaz).
"""
import math
import random
import sys

from PIL import Image, ImageDraw, ImageFont

FONT = 'assets/fonts/ScheherazadeNew-Bold.ttf'
OUT = sys.argv[1] if len(sys.argv) > 1 else 'assets/images/arabic_letters_pattern.webp'

# 411x913 dp'lik bir telefon ekranını kaplayacak; 1 dp = 1.75 px.
DP = 1.75
W, H = int(411 * DP), int(913 * DP)
CELL = 92 * DP
LETTERS = list('ابتثجحخدذرزسشصضطظعغفقكلمنهوي')

rnd = random.Random(7)
canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
cols = math.ceil(W / CELL)
rows = math.ceil(H / CELL)
index = 0
for row in range(rows):
    for col in range(cols):
        if rnd.random() < 0.28:
            continue
        letter = LETTERS[(index * 11 + row * 5) % len(LETTERS)]
        index += 1
        size = int((32 + rnd.random() * 42) * DP)
        font = ImageFont.truetype(FONT, size)
        left, top, right, bottom = font.getbbox(letter)
        gw, gh = right - left + 8, bottom - top + 8
        glyph = Image.new('RGBA', (gw, gh), (0, 0, 0, 0))
        ImageDraw.Draw(glyph).text((4 - left, 4 - top), letter, font=font, fill=(255, 255, 255, 255))
        angle = (rnd.random() - 0.5) * 0.7
        glyph = glyph.rotate(math.degrees(angle), resample=Image.BICUBIC, expand=True)
        x = col * CELL + rnd.random() * max(0, CELL - glyph.width)
        y = row * CELL + rnd.random() * max(0, CELL - glyph.height)
        canvas.alpha_composite(glyph, (int(x), int(y)))

canvas.save(OUT, 'WEBP', lossless=True, quality=100, method=6)
print(OUT, canvas.size, index, 'harf')
