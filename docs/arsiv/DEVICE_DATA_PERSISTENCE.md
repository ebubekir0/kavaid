# KAVAID - Cihaz Verilerinin Kalıcı Olması

## Sorun
Uygulama verileri silindiğinde veya uygulama yeniden yüklendiğinde:
- Premium durumu kayboluyordu
- Kalan ücretsiz haklar sıfırlanıyordu  
- Günlük haklar sıfırlanıyordu

## Çözüm
Firebase Realtime Database kullanarak cihaz bazlı veri saklama sistemi eklendi.

### Yapılan Değişiklikler

#### 1. Yeni Servis: `DeviceDataService`
- Cihaz ID'si oluşturur (Android ID veya iOS identifierForVendor)
- Firebase'de `cihazlar` node'u altında cihaz verilerini saklar
- Kredi bilgileri, premium durumu ve diğer verileri Firebase'e kaydeder

#### 2. `CreditsService` Güncellemeleri
- Başlatma sırasında önce Firebase'den veri alınır
- Firebase'de veri varsa, o veriler kullanılır
- Her veri değişikliğinde Firebase'e senkronize edilir
- Offline durumda da çalışır (yerel cache)

#### 3. Firebase Yapısı
```
cihazlar/
  [device_id]/
    krediler: 100
    premiumDurumu: false
    premiumBitisTarihi: 1234567890
    ilkKredilerKullanildi: false
    sonSifirlamaTarihi: "2025-01-28T00:00:00.000"
    oturumAcilanKelimeler: ["kelime1", "kelime2"]
    sonGuncelleme: {timestamp}
    ilkAcilis: false
```

### Firebase Kuralları
`firebase_database_rules.json` dosyasını Firebase Console'da güncellemelisiniz:

1. Firebase Console'a gidin
2. Realtime Database > Rules sekmesine gidin
3. Aşağıdaki kuralları yapıştırın:

```json
{
  "rules": {
    "kelimeler": {
      ".read": true,
      ".write": false
    },
    "cihazlar": {
      "$device_id": {
        ".read": true,
        ".write": true,
        ".validate": "newData.hasChildren(['krediler', 'premiumDurumu', 'ilkKredilerKullanildi', 'sonGuncelleme'])"
      }
    }
  }
}
```

### Test Etme
1. Uygulamayı açın ve birkaç kelime açın
2. Uygulama verilerini temizleyin (Ayarlar > Uygulamalar > KAVAID > Depolama > Verileri Temizle)
3. Uygulamayı tekrar açın
4. Premium durumu, krediler ve diğer verilerin korunduğunu göreceksiniz

### Notlar
- İlk yükleme biraz zaman alabilir (Firebase'den veri çekilirken)
- Offline durumda da çalışır
- Cihaz ID'si değişirse (fabrika ayarları gibi) veriler kaybolur
- Her cihaz kendi verilerini saklar 