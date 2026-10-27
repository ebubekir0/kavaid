"""Uygulamanın sözlük verisini (assets/data/sozluk.json.xz) okur; araçların ortak girişi."""
import json
import lzma

SOURCE = 'assets/data/sozluk.json.xz'


def load_dictionary(path=SOURCE):
    """Kayıt listesi, uygulamadaki sırayla."""
    with lzma.open(path, 'rt', encoding='utf-8') as f:
        return json.load(f)
