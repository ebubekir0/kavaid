# Veritabanı Kopyalama Talimatı

## Adım 1: Mevcut Veritabanını Bul

Uygulamayı bir kez çalıştırıp veritabanını yükledikten sonra, aşağıdaki komutlarla veritabanını bilgisayarınıza kopyalayın:

### Android için:

```bash
# Veritabanı konumunu bul
adb shell run-as com.onbir.kavaid ls -la /data/data/com.onbir.kavaid/databases/

# Veritabanını bilgisayara kopyala
adb shell run-as com.onbir.kavaid cat /data/data/com.onbir.kavaid/databases/kavaid.db > kavaid.db

# Veya alternatif yöntem:
adb exec-out run-as com.onbir.kavaid cat databases/kavaid.db > kavaid.db
```

### iOS için:

```bash
# iOS simülatörde veritabanı konumu:
# ~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/

# Xcode > Window > Devices and Simulators > İlgili cihaz > Installed Apps > Kavaid > Settings (⚙️) > Download Container
# İndirilen container içinde: AppData/Library/Application Support/kavaid.db
```

## Adım 2: Veritabanını Assets Klasörüne Kopyala

Kopyaladığınız `kavaid.db` dosyasını şu konuma taşıyın:
```
kavaid/assets/database/kavaid.db
```

## Adım 3: Pubspec.yaml'ı Güncelle

`pubspec.yaml` dosyasında assets bölümüne ekleyin:
```yaml
assets:
  - assets/database/
  - assets/images/
  - assets/books/
  - assets/fonts/
```

## Adım 4: Temizlik ve Yeniden Build

```bash
flutter clean
flutter pub get
flutter build apk  # veya flutter run
```

## Not:

Veritabanı dosyası büyükse (>10MB), Git'e eklemeyi unutmayın veya `.gitignore`'a ekleyin.
Uygulama ilk açılışta bu veritabanını otomatik olarak kullanacak.
