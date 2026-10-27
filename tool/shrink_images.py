"""Büyük JPEG/PNG görselleri WebP'ye çevirir ve ekranda gereken boyuta indirir (uygulama boyutunu küçültmek için).

Kullanım (kavaid klasöründen):
    python tool/shrink_images.py --dry-run     # yalnız ölçer, dosyaya dokunmaz
    python tool/shrink_images.py               # assets/images/*.webp yazar, eski dosyayı siler,
                                               # lib/ altındaki yolları .webp'ye çevirir

Kapaklar en büyük hâliyle tam genişlikte (~400 dp × 3 yoğunluk) çizildiği için en fazla 1080 px genişlik yeter.
--min-kb'den küçük dosyalara ve uygulama ikonuna dokunulmaz.
"""
import argparse
import glob
import io
import os
import sys

from PIL import Image

MAX_WIDTH = 1080
QUALITY = 78
SKIP = {'app_icon.png'}


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--min-kb', type=int, default=150)
    args = ap.parse_args()

    before = after = 0
    renamed = {}
    for path in sorted(glob.glob('assets/images/*')):
        name = os.path.basename(path)
        ext = os.path.splitext(name)[1].lower()
        size = os.path.getsize(path)
        if name in SKIP or ext not in ('.jpg', '.jpeg', '.png') or size < args.min_kb * 1024:
            continue
        img = Image.open(path)
        if img.width > MAX_WIDTH:
            img = img.resize((MAX_WIDTH, round(img.height * MAX_WIDTH / img.width)), Image.LANCZOS)
        if img.mode not in ('RGB', 'RGBA'):
            img = img.convert('RGBA' if 'transparency' in img.info else 'RGB')
        buf = io.BytesIO()
        img.save(buf, 'WEBP', quality=QUALITY, method=6)
        before += size
        after += buf.tell()
        new_name = os.path.splitext(name)[0] + '.webp'
        print(f'{name}: {size / 1e6:.2f} MB → {buf.tell() / 1e6:.2f} MB')
        if not args.dry_run:
            with open(os.path.join('assets/images', new_name), 'wb') as f:
                f.write(buf.getvalue())
            os.remove(path)
            renamed[name] = new_name
    print(f'toplam {before / 1e6:.1f} MB → {after / 1e6:.1f} MB')

    if renamed:
        changed = 0
        for root, _, files in os.walk('lib'):
            for f in files:
                if not f.endswith('.dart'):
                    continue
                p = os.path.join(root, f)
                with open(p, encoding='utf-8') as fh:
                    src = fh.read()
                new = src
                for old, nw in renamed.items():
                    new = new.replace(f'assets/images/{old}', f'assets/images/{nw}')
                if new != src:
                    with open(p, 'w', encoding='utf-8', newline='') as fh:
                        fh.write(new)
                    changed += 1
        print(f'{len(renamed)} görsel çevrildi, {changed} Dart dosyasında yol güncellendi')


if __name__ == '__main__':
    main()
