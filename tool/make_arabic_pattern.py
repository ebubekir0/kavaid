"""Ana ekranın hafif İslami geometrik desenini üretir (beyaz çizgiler,
saydam zemin). Uygulama görseli temaya göre renklendirir.

Kullanım (proje kökünde): python tool/make_arabic_pattern.py [çıktı.webp]
"""
import math
import sys

from PIL import Image, ImageDraw

OUT = sys.argv[1] if len(sys.argv) > 1 else 'assets/images/arabic_letters_pattern.webp'

DP = 1.75                      # 1 dp = 1.75 px
W, H = int(411 * DP), int(913 * DP)
SS = 3                         # kenar yumuşatma için büyütme
CELL = 96 * DP * SS
LINE = max(2, int(1.3 * DP * SS))

img = Image.new('L', (W * SS, H * SS), 0)
d = ImageDraw.Draw(img)


def star(cx, cy, r_out, r_in, rot=0.0):
    """Sekiz köşeli yıldız (iki üst üste kare gibi)."""
    pts = []
    for i in range(16):
        r = r_out if i % 2 == 0 else r_in
        a = rot + i * math.pi / 8
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    d.line(pts + [pts[0]], fill=255, width=LINE, joint='curve')


cols = int(W * SS / CELL) + 2
rows = int(H * SS / CELL) + 2
for row in range(-1, rows):
    for col in range(-1, cols):
        cx, cy = col * CELL, row * CELL
        r = CELL * 0.40
        star(cx, cy, r, r * 0.72, rot=math.pi / 8)
        # iç sekizgen halka
        d.ellipse((cx - r * 0.34, cy - r * 0.34, cx + r * 0.34, cy + r * 0.34),
                  outline=255, width=LINE)
        # yıldızları bağlayan eşkenar dörtgen (hücre köşelerinde)
        k = CELL / 2
        mx, my = cx + k, cy + k
        s = CELL * 0.12
        d.line([(mx, my - s), (mx + s, my), (mx, my + s), (mx - s, my), (mx, my - s)],
               fill=255, width=LINE)

mask = img.resize((W, H), Image.LANCZOS)
# Üstte belirgin, aşağıya doğru silinen yumuşak geçiş
fade = Image.linear_gradient('L').resize((W, H)).point(lambda v: int(255 - v * 0.7))
mask = Image.composite(mask, Image.new('L', (W, H), 0), fade).point(lambda v: v)
alpha = Image.eval(mask, lambda v: v)
out = Image.merge('RGBA', (Image.new('L', (W, H), 255),) * 3 + (alpha,))
out.save(OUT, 'WEBP', lossless=True, quality=100, method=6)
print(OUT, out.size)
