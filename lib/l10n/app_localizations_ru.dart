// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get kavaidSozluk => 'Словарь Kavaid';

  @override
  String get tekrarDene => 'Повторить попытку';

  @override
  String get kavaidArapcaSozluk => 'Kavaid — Арабский словарь';

  @override
  String get sozluk => 'Словарь';

  @override
  String get ceviri => 'Перевод';

  @override
  String get ogren => 'Обучение';

  @override
  String get profil => 'Профиль';

  @override
  String get kelimeBulunamadi => 'Слово не найдено';

  @override
  String get baglantiAcilamadi => 'Не удалось открыть ссылку';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'Поздравляем! Вам начислен 1 месяц Premium-подписки 🌟';

  @override
  String get gecersizVeyaKullanilmisKod =>
      'Недействительный или уже использованный код.';

  @override
  String get buKoduDahaOnceKullandiniz => 'Вы уже использовали этот код.';

  @override
  String get buKodunSuresiDolmus => 'Срок действия кода истек.';

  @override
  String get buKodunKullanimLimitiDolmus =>
      'Лимит использования этого кода исчерпан.';

  @override
  String get lutfenOnceGirisYapin => 'Пожалуйста, сначала войдите в систему.';

  @override
  String get m1AyUcretsizPremiumKazan => 'Получите 1 месяц бесплатного Premium';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'Поделитесь своим мнением о приложении в Twitter (X), сделав ретвит закрепленного поста, и получите 1 месяц бесплатного Premium!';

  @override
  String get nasilKatilirim => 'Как принять участие?';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'Поделитесь своим мнением о приложении в Twitter (X), сделав ретвит указанного поста.';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'Отправьте ссылку на ваш ретвит в личные сообщения аккаунту @ebubekr53 в Twitter, чтобы получить ваш код.';

  @override
  String get koduAsagiyaGirin => 'Введите код ниже.';

  @override
  String get tweetiAlintila => 'Ретвитнуть';

  @override
  String get promosyonKodu => 'Промокод';

  @override
  String get kullan => 'Применить';

  @override
  String get dahaFazlaOzellik => 'Больше возможностей';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'Перейдите на Premium,\nчтобы создавать больше списков';

  @override
  String get kapat => 'Закрыть';

  @override
  String get premiumAl => 'Получить Premium';

  @override
  String get yeniListe => 'Новый список';

  @override
  String get listeAdi => 'Название списка';

  @override
  String get iptal => 'Отмена';

  @override
  String get olustur => 'Создать';

  @override
  String get listeyiYenidenAdlandir => 'Переименовать список';

  @override
  String get kaydet => 'Сохранить';

  @override
  String get kelimeListelerim => 'Мои списки слов';

  @override
  String get yeniListeOlustur => 'Создать список';

  @override
  String get henuzListeYok => 'Списков пока нет';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'Создайте список,\nчтобы упорядочить ваши слова';

  @override
  String wordcountKelime(int wordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      wordCount,
      locale: localeName,
      other: '$wordCount слов',
      few: '$wordCount слова',
      one: '$wordCount слово',
    );
    return '$_temp0';
  }

  @override
  String get yenidenAdlandir => 'Переименовать';

  @override
  String get sil => 'Удалить';

  @override
  String get listeyiSil => 'Удалить список';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return 'Удалить «$name»?\nВсе слова внутри также будут удалены.';
  }

  @override
  String get buListedeHenuzKelimeYok => 'В этом списке пока нет слов';

  @override
  String get liste => 'Список';

  @override
  String get kart => 'Карточка';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'Перейдите на Premium для доступа к большему количеству карточек';

  @override
  String get premiumAYukselt => 'Перейти на Premium';

  @override
  String get dinle => 'Прослушать';

  @override
  String get oyun => 'Игра';

  @override
  String get kullanimSiniriDoldu => 'Лимит использования исчерпан';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'Чтобы продолжить пользоваться словарем Корана без ограничений, пожалуйста, войдите в систему и перейдите на Premium.';

  @override
  String get tamam => 'Готово';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'Все книги открыты, реклама отключена.';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'Все книги открыты. Пожалуйста, войдите в систему, чтобы навсегда отключить рекламу.';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'Не удалось применить секретный код: $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'Словарь обновляется... Пожалуйста, подождите.';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 слов',
      few: '$p1 слова',
      one: '$p1 слово',
    );
    return 'Словарь успешно обновлен! Загружено $_temp0.';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu => 'Ошибка при обновлении словаря!';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'Ошибка перезагрузки базы данных: $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris =>
      'Пожалуйста, сначала зарегистрируйтесь или войдите.';

  @override
  String get kelimeAra => 'Поиск слова';

  @override
  String get emsile => 'Emsile';

  @override
  String get kuranSozlugu => 'Словарь Корана';

  @override
  String get kavaidIDegerlendir => 'Оценить Kavaid';

  @override
  String get gorusunBizimIcinCokDegerli => 'Ваше мнение очень важно для нас.';

  @override
  String get kuranSozluguYukleniyor => 'Загрузка словаря Корана...';

  @override
  String get kuranSozlugundeAraniyor => 'Поиск в словаре Корана...';

  @override
  String get araniyor => 'Поиск...';

  @override
  String get kuranSozlugundeBulunamadi => 'В словаре Корана не найдено';

  @override
  String get farkliBirKelimeVeyaKok => 'Попробуйте другое слово или корень';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'Чтобы пользоваться словарем Корана без ограничений, перейдите на Premium.';

  @override
  String get kurAnIKerimSozlugu => 'Словарь Священного Корана';

  @override
  String get kurAnDaGecenTum =>
      'Изучайте употребление всех слов, встречающихся в Коране, и их коранические смыслы вместе с аятами.';

  @override
  String get kurAnDakiBenzersizTum => 'Все уникальные слова Корана.';

  @override
  String get kuraniAnlamlar => 'Коранические смыслы';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'Узнайте значения, которые слова приобретают в аятах Корана.';

  @override
  String get kurAnAyetleri => 'Аяты Корана';

  @override
  String get onBinlerceKurAnAyeti =>
      'Смотрите, как слова используются в Коране, с помощью десятков тысяч аятов.';

  @override
  String get kavaidArapcaSozluk2 => 'Арабский словарь Kavaid';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'Первый арабский словарь нового поколения на базе ИИ';

  @override
  String get premiumAGec => 'Перейти на Premium';

  @override
  String get sinirsizErisim => 'Безлимитный доступ';

  @override
  String get profilResmiGuncellendi => '✅ Фото профиля обновлено!';

  @override
  String get birHataOlustu => 'Произошла ошибка';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'Firebase Storage не настроен. Пожалуйста, активируйте Storage в консоли Firebase.';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'Ошибка доступа. Проверьте правила Storage.';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'Ошибка авторизации. Пожалуйста, войдите в систему.';

  @override
  String get internetBaglantisiHatasi => 'Ошибка интернет-соединения.';

  @override
  String get detay => 'Подробнее';

  @override
  String get hataDetayi => 'Детали ошибки';

  @override
  String get kullanici => 'Пользователь';

  @override
  String get kurucu => 'ОСНОВАТЕЛЬ';

  @override
  String get moderator => 'МОДЕРАТОР';

  @override
  String get emailYok => 'Нет email';

  @override
  String get cikisYapilsinMi => 'Выйти из аккаунта?';

  @override
  String get oturumunuzKapatilacak => 'Ваш сеанс будет завершен.';

  @override
  String get cikis => 'Выйти';

  @override
  String get aboneligiYonet => 'Управление подпиской';

  @override
  String get satinAlmalarKontrolEdiliyor => 'Проверка покупок...';

  @override
  String get geriYukle => 'Восстановить';

  @override
  String get girisYapinVeyaKayitOlun => 'Войдите или зарегистрируйтесь';

  @override
  String get girisYap => 'Войти';

  @override
  String get kayitOl => 'Зарегистрироваться';

  @override
  String get premiumUyesiniz => 'У вас Premium-подписка';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'Безлимитный контент, без рекламы.';

  @override
  String get tumOzelliklereErisin => 'Доступ ко всем функциям.';

  @override
  String get reklamsizKullanim => 'Без рекламы';

  @override
  String get uygulamayiPaylas => 'Поделиться приложением';

  @override
  String get iletisim => 'Связаться с нами';

  @override
  String get kavaidUygulamasiHakkinda => 'О приложении Kavaid';

  @override
  String get hesabimiSil => 'Удалить аккаунт';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'Вы уверены, что хотите навсегда удалить свой аккаунт и все связанные с ним данные? Это действие нельзя отменить.';

  @override
  String get vazgec => 'Отмена';

  @override
  String get hesabinizBasariylaSilindi => 'Ваш аккаунт успешно удален.';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'Не удалось удалить аккаунт: $e. Из соображений безопасности может потребоваться повторный вход.';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi =>
      'Kavaid — приложение арабского словаря';

  @override
  String get paylasimSirasindaBirHataOlustu =>
      'Произошла ошибка при попытке поделиться';

  @override
  String get internetGerekli => 'Требуется интернет';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'Для этого действия необходимо подключение к интернету.';

  @override
  String get kullaniciAdiDegistir => 'Сменить имя пользователя';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'Текущее: $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'Новое имя пользователя';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'username123 (строчные буквы, без пробелов)';

  @override
  String get enAz3KarakterSadece =>
      '• Минимум 3 символа\n• Только строчные латинские буквы и цифры';

  @override
  String get kullaniciAdiEnAz3 =>
      'Имя пользователя должно содержать минимум 3 символа';

  @override
  String get sadeceKucukHarfRakamVe =>
      'Только строчные латинские буквы и цифры';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'Имя пользователя изменено на «$newUsername»!';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'Это имя пользователя недоступно или занято';

  @override
  String get degistir => 'Изменить';

  @override
  String get premiumUyelikAktif => '🎉 Подписка Premium активна!';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'Ошибка подключения: $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'Чтобы купить Premium, пожалуйста, войдите в аккаунт.';

  @override
  String hataE(Object e) {
    return 'Ошибка: $e';
  }

  @override
  String get kavaidPremium => 'Kavaid Premium';

  @override
  String get aiAsistanASinirsizErisim => 'Безлимитный доступ к AI-ассистенту';

  @override
  String get ceviriyeSinirsizErisim => 'Безлимитный доступ к переводчику';

  @override
  String get m5500Fiilin24Siga => 'Таблицы спряжения Emsile для 5500+ глаголов';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'Доступ ко всем материалам в разделе обучения';

  @override
  String get kuranSozluguneSinirsizErisim =>
      'Безлимитный доступ к словарю Корана';

  @override
  String get sinirsizKelimeKartiVeListe =>
      'Создание неограниченного числа карточек и списков';

  @override
  String get reklamsizDeneyim => 'Без рекламы';

  @override
  String get aylikAbonelik => 'Месячная подписка';

  @override
  String get m1AyBoyuncaSinirsizErisim => 'Безлимитный доступ на 1 месяц';

  @override
  String get yillikAbonelik => 'Годовая подписка';

  @override
  String get m1YilBoyuncaSinirsizErisim => 'Безлимитный доступ на 1 год';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return 'Безлимитный доступ на 1 год ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return 'СКИДКА $yearlyDiscount%';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Оформить подписку$buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Оформить подписку$buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'Оплата будет списана с вашего Apple ID. Подписка продлевается автоматически, если вы не отмените её как минимум за 24 часа до окончания текущего периода. Вы можете отменить подписку в настройках App Store.';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'Оплата будет списана через Google Play. Подписка продлевается автоматически, если вы не отмените её как минимум за 24 часа до окончания текущего периода. Вы можете отменить подписку в настройках Google Play.';

  @override
  String get satinAlmalariGeriYukle => 'Восстановить покупки';

  @override
  String get kullanimKosullariEula => 'Условия использования (EULA)';

  @override
  String get gizlilikPolitikasi => 'Политика конфиденциальности';

  @override
  String get metinGirin => 'Введите текст';

  @override
  String get harekeAc => 'Огласовки';

  @override
  String get kopyala => 'Копировать';

  @override
  String get kopyalandi => 'Скопировано';

  @override
  String get cevir => 'Перевести';

  @override
  String get suDileCevir => 'Перевести на язык';

  @override
  String get premiumAGecin => 'Перейти на Premium';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'Оформите Premium для безлимитного перевода.';

  @override
  String get lutfenOnceKayitOlupGiris =>
      'Пожалуйста, сначала войдите в аккаунт.';

  @override
  String get diller => 'Языки';

  @override
  String get lehceler => 'Диалекты';

  @override
  String get internetBaglantisiGerekiyor => 'Требуется интернет-соединение.';

  @override
  String get aiAsistanSuAnKullanilamiyor => 'AI-ассистент сейчас недоступен.';

  @override
  String get yanitGelmedi => 'Нет ответа.';

  @override
  String get suAndaCevapAlinamadi => 'Не удалось получить ответ.';

  @override
  String get hazir => 'Готово.';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'Для AI-помощника требуется интернет-соединение.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'Лимит бесплатных запросов к AI-помощнику на сегодня исчерпан.';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'Неверный API-ключ AI-учителя. Проверьте настройки Gemini API.';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'AI-помощник сейчас не отвечает. Попробуйте позже.';

  @override
  String get yukleniyor => 'Загрузка...';

  @override
  String get sozlukHazir => 'Словарь готов.';

  @override
  String get sozlukYuklenemedi => 'Не удалось загрузить словарь.';

  @override
  String get ekranHazirlaniyor => 'Подготовка экрана...';

  @override
  String get sozlukKontrolEdiliyor => 'Проверка словаря...';

  @override
  String get sozlukAyarlaniyor => 'Настройка словаря...';

  @override
  String get aramaHazirlaniyor => 'Подготовка поиска...';

  @override
  String get aramaHazir => 'Поиск готов.';

  @override
  String get internetBaglantisiYok => 'Нет подключения к интернету';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'Для использования приложения требуется интернет. Пожалуйста, проверьте подключение к Wi-Fi или мобильной сети.';

  @override
  String get sozlukHazirlaniyor => 'Словарь подготавливается...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    String _temp0 = intl.Intl.pluralLogic(
      existingCount,
      locale: localeName,
      other: '$existingCount слов',
      few: '$existingCount слова',
      one: '$existingCount слово',
    );
    return 'Словарь готов. Доступно $_temp0.';
  }

  @override
  String get kelimelerYukleniyor => 'Загрузка слов...';

  @override
  String get sozlukHazir2 => 'Словарь готов!';

  @override
  String get mevcutVeritabaniKullanilacak =>
      'Будет использована текущая база данных.';

  @override
  String get hicGuncellenmedi => 'Не обновлялось';

  @override
  String get girisYapmalisiniz => 'Необходимо войти.';

  @override
  String get paketBulunamadiLifetime => 'Пакет не найден (Lifetime).';

  @override
  String get hataOlustu => 'Произошла ошибка';

  @override
  String beklenmedikHataE(Object e) {
    return 'Непредвиденная ошибка: $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'Не удалось запустить RevenueCat: $e';
  }

  @override
  String get satinAlmakIcinOnceGiris => 'Чтобы купить, сначала войдите.';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'Ошибка покупки: $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'Не удалось загрузить пакет подписки. Пожалуйста, проверьте интернет и попробуйте снова.';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'Для проверки покупки требуется интернет.';

  @override
  String get aktifBirAbonelikBulunamadi => 'Активная подписка не найдена.';

  @override
  String restoreHatasiE(Object e) {
    return 'Ошибка восстановления: $e';
  }

  @override
  String get hataOlustu2 => 'Произошла ошибка.';

  @override
  String get ceviriIcinGirisYapmanGerekiyor => 'Для перевода необходимо войти.';

  @override
  String get premiumKullanici => 'Пользователь Premium.';

  @override
  String get ceviriHakkiKullanildi => 'Лимит переводов исчерпан.';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'Не удалось проверить лимит переводов. Проверьте подключение.';

  @override
  String get yeniSohbet => 'Новый чат';

  @override
  String get buSohbetinGecmisiSilinsinMi => 'Удалить историю этого чата?';

  @override
  String get aiAsistan => 'AI-ассистент';

  @override
  String get hakkinda => ' о';

  @override
  String get arapcaSozlukYardimcin => 'Ваш помощник по арабскому';

  @override
  String get bugunkuUcretsizSoruHakkin => 'Бесплатный вопрос на сегодня';

  @override
  String get arapcasiniDinle => 'Прослушать на арабском';

  @override
  String get tekrarDene2 => 'Повторить';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    String _temp0 = intl.Intl.pluralLogic(
      freeDailyLimit,
      locale: localeName,
      other: '$freeDailyLimit бесплатных вопросов',
      few: '$freeDailyLimit бесплатных вопроса',
      one: '$freeDailyLimit бесплатный вопрос',
    );
    return 'Ваши $_temp0 на сегодня закончились';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'Лимит обновится завтра. С Premium можно спрашивать без ограничений.';

  @override
  String get premiumAGec2 => 'Перейти на Premium';

  @override
  String get kisacaAnlat => 'Объясни кратко';

  @override
  String get m3OrnekCumleVer => 'Приведи 3 примера предложений';

  @override
  String get benzerKelimelerdenFarkiNe => 'В чем отличие от похожих слов?';

  @override
  String get okunusunuLatinHarfleriyleYaz => 'Напиши транскрипцию латиницей';

  @override
  String get gecmisZamanNasilKurulur => 'Как образуется прошедшее время?';

  @override
  String get harfICerNedir => 'Что такое харф-и джар (предлог)?';

  @override
  String get isimCumlesiNasilKurulur => 'Как составить именное предложение?';

  @override
  String get enSikKullanilan10Fiil => '10 самых частых глаголов';

  @override
  String get sonSorduklarim => 'Последние вопросы';

  @override
  String get ornekSorular => 'Примеры вопросов';

  @override
  String get buKelimeHakkindaKisaVe =>
      'Получите краткий и четкий ответ об этом слове.';

  @override
  String get arapcaSorunuYaz => 'Напишите свой вопрос об арабском';

  @override
  String get kisaVeNetCevapVerir =>
      'Отвечает кратко и по существу, не выдумывает лишнего.';

  @override
  String get ornekVer => 'Приведи пример';

  @override
  String get dahaBasitAnlat => 'Объясни проще';

  @override
  String get derinles => 'Разверни ответ';

  @override
  String get cekiminiGoster => 'Покажи спряжение';

  @override
  String get aiAsistanASor => 'Спросить AI-ассистента...';

  @override
  String get yeniAiAsistan => 'Новинка: AI-ассистент';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'Нажмите на этот значок в левом углу карточки слова, чтобы узнать значение, отличия от синонимов и примеры.';

  @override
  String get anladim => 'Понятно';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'Приведи больше примеров с этим словом по уровням: простые, средние, разговорные, грамматические и вопросительные.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'Ваш бесплатный лимит AI-ассистента на сегодня исчерпан. Оформите Premium, чтобы продолжить.';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'Не удалось получить ответ. Проверьте интернет-соединение и попробуйте снова.';

  @override
  String get aiKelimeAsistani => 'AI-ассистент';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining бесплатных запросов',
      few: '$remaining бесплатных запроса',
      one: '$remaining бесплатный запрос',
    );
    return 'AI-ассистент · $_temp0';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi =>
      'Не удалось подготовить AI-ассистента.';

  @override
  String get premiumAGec3 => 'Оформить Premium';

  @override
  String get kisacaAnlat2 => 'Краткое объяснение';

  @override
  String get gramerNotlari => 'Грамматические заметки';

  @override
  String get kullanimNotlari => 'Заметки по употреблению';

  @override
  String get buKelimeNeredeKullanilir => 'Где используется это слово?';

  @override
  String get m5YeniOrnekVer => 'Привести 5 примеров';

  @override
  String get kolayCumlelerleAnlat => 'Объяснить простыми предложениями';

  @override
  String get cekimleOrnekVer => 'Привести пример со спряжением';

  @override
  String get harfICerFarkiniAnlat =>
      'Объяснить разницу с предлогами (харф-и джар)';

  @override
  String get ornekleOgren => 'Учим на примерах';

  @override
  String get miniAlistirma => 'Мини-упражнение';

  @override
  String get hazirSorular => 'Готовые вопросы';

  @override
  String get sor => 'Спросить';

  @override
  String get buKelimeyleIlgiliSoruSor => 'Задать вопрос об этом слове';

  @override
  String get arapcaTurkceSozluk => 'Арабско-русский словарь';

  @override
  String get arapcaYaDaTurkceYaz =>
      'Пишите на арабском или русском, всё на одной карточке.';

  @override
  String get sesleYaDaArapcaKlavyeyle =>
      'Поиск голосом или через арабскую клавиатуру';

  @override
  String get kokCogulVeOrnekCumleler =>
      'Корень, множественное число и примеры предложений';

  @override
  String get fiilKarti => 'Карточка глагола';

  @override
  String get fiillerinCekimleriKartinIcinde =>
      'Спряжения глаголов прямо в карточке.';

  @override
  String get maziMuzariMastarVeEmir =>
      'Прошедшее, настоящее, масдар и повелительное';

  @override
  String get tumCekimlerIcinEmsileyeGec =>
      'Перейти в Emsile для всех спряжений';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'Нажмите на значок слева от карточки слова.';

  @override
  String get sorunuYazYaDaHazir => 'Напишите свой вопрос или выберите готовый.';

  @override
  String get kisaVeNetCevap => 'Короткий и четкий ответ';

  @override
  String get m5500DenFazlaFiilin => 'Таблицы спряжения более 5500 глаголов.';

  @override
  String get fiileDokunKartiAcilsin =>
      'Нажмите на глагол, чтобы открыть карточку';

  @override
  String get anlamlariVe24SigaCekimi => 'Значения и спряжение по 24 формам';

  @override
  String get kurAnSozlugu => 'Словарь Корана';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren =>
      'Изучайте слова из Корана вместе с аятами.';

  @override
  String get kelimeVeKurAniAnlamlari => 'Слово и его значение в Коране';

  @override
  String get gectigiAyetVeMeali => 'Аят, в котором встречается, и его перевод';

  @override
  String get lehceCeviri => 'Перевод по диалектам';

  @override
  String get turkceYazYaDaKonus =>
      'Пишите или говорите по-русски, переводите на 17 диалектов.';

  @override
  String get karsiligiVeOkunusu => 'Соответствие и произношение';

  @override
  String get lehceyiSecYaDaSesle => 'Выберите диалект или произнесите голосом';

  @override
  String get listelerVeKartlar => 'Списки и карточки';

  @override
  String get kaydettiginHerSeyTekYerde =>
      'Всё, что вы сохранили, в одном месте.';

  @override
  String get listeYaDaKartlarlaTekrar => 'Повторяйте по списку или карточкам';

  @override
  String get sozlukKurAnVeEmsile => 'Записи словаря, Корана и Emsile';

  @override
  String get a1DenC1EResimli =>
      'Иллюстрированные арабские рассказы от A1 до C1.';

  @override
  String get kelimeyeDokunAnlamiCiksin =>
      'Нажмите на слово, чтобы увидеть значение';

  @override
  String get metniSesliDinle => 'Прослушать текст';

  @override
  String get gec => 'Пропустить';

  @override
  String get yeni => 'НОВОЕ';

  @override
  String get ara => 'Поиск';

  @override
  String get bosluk => 'Пробел';

  @override
  String get hesabinizYoksaOnceKayitOlun =>
      'Если у вас нет аккаунта, сначала зарегистрируйтесь.';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'После завершения регистрации вам нужно будет войти.';

  @override
  String get ePosta => 'Эл. почта';

  @override
  String get gecersizEPostaAdresi => 'Неверный e-mail';

  @override
  String get sifre => 'Пароль';

  @override
  String get sifreGerekli => 'Введите пароль';

  @override
  String get sifremiUnuttum => 'Забыли пароль?';

  @override
  String get sifreTekrar => 'Повторите пароль';

  @override
  String get sifreTekrariGerekli => 'Требуется повтор пароля';

  @override
  String get sifrelerEslesmiyor => 'Пароли не совпадают';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'Введите адрес электронной почты для сброса пароля.';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return 'Если на адрес $email зарегистрирован аккаунт, на него будет отправлена ссылка для сброса пароля. Проверьте входящие и папку «Спам».';
  }

  @override
  String get gecerliBirEPostaAdresi =>
      'Введите корректный адрес электронной почты.';

  @override
  String get buEPostaIleKayit => 'Аккаунт с этой почтой не найден.';

  @override
  String get cokFazlaDenemeYapildiBir =>
      'Слишком много попыток. Попробуйте позже.';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'Ошибка сети. Проверьте подключение к интернету.';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'Не удалось отправить ссылку. Попробуйте снова.';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 Добро пожаловать! Аккаунт успешно создан.';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'Ошибка операции. Попробуйте снова.';

  @override
  String get ePostaVeyaSifreHatali =>
      'Неверный e-mail или пароль. Проверьте данные.';

  @override
  String get sifreHatali => 'Неверный пароль.';

  @override
  String get buEPostaZatenKayitli => 'Этот e-mail уже зарегистрирован.';

  @override
  String get sifreCokZayifDahaGuclu =>
      'Слишком простой пароль. Придумайте пароль посложнее.';

  @override
  String get buGirisYontemiProjeIcin =>
      'Этот метод входа не доступен для проекта.';

  @override
  String get oDisil => 'Она';

  @override
  String get ikisi => 'Оба/Обе';

  @override
  String get ikisiEril => 'Оба (муж. род)';

  @override
  String get ikisiDisil => 'Обе (жен. род)';

  @override
  String get onlarDisil => 'Они (жен. род)';

  @override
  String get senDisil => 'Ты (жен. род)';

  @override
  String get ikiniz => 'Вы двое';

  @override
  String get sizDisil => 'Вы (жен. род)';

  @override
  String get m3Sahis => 'غَائِب (3-е лицо)';

  @override
  String get m2Sahis => 'مُخَاطَب (2-е лицо)';

  @override
  String get m1Sahis => 'مُتَكَلِّم (1-е лицо)';

  @override
  String get muzari => 'Мудари';

  @override
  String get emsileCekimleri => 'Спряжение Emsile';

  @override
  String get maziGecmis => 'Мади (прош.)';

  @override
  String get muzariGenis => 'Мудари (наст.)';

  @override
  String get emir => 'Амр (пов.)';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return 'Спряжение «$tabTitle» не найдено';
  }

  @override
  String get kok => 'Корень';

  @override
  String get ismIFail => 'Исм фаиль';

  @override
  String get ismIMefUl => 'Исм мафуль';

  @override
  String get fiilCekimleriKavaidSozluk => 'Спряжение глаголов • Kavaid';

  @override
  String get m5500DenFazlaFiilin2 =>
      'Изучите спряжение более 5500 глаголов по 24 формам Emsile.';

  @override
  String get tumFiilleriAc => 'Открыть все глаголы';

  @override
  String get dahaFazlaFiilYukle => 'Загрузить ещё';

  @override
  String get arananKelimeBulunamadi => 'Слово не найдено';

  @override
  String get fiilIMaziMuttasilCekimler => 'Мази — слитные местоимения';

  @override
  String get fiilIMuzariMuttasilCekimler => 'Музари — слитные местоимения';

  @override
  String get emrIHazirMuttasilCekimler => 'Эмир — слитные местоимения';

  @override
  String get cekimler => 'Спряжения';

  @override
  String get premiumIcerik => 'Premium-контент';

  @override
  String get m5500DenFazlaFiilin3 =>
      'Откройте спряжение более 5500 глаголов по 24 формам Emsile';

  @override
  String get ucretsizFiiller => 'Бесплатные глаголы';

  @override
  String get listeyeEkle => 'В список';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'Чтобы использовать AI-помощника, пожалуйста, войдите в аккаунт.';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'Приведи 5 примеров с этим словом, подходящих для моего уровня: от простого к сложному.';

  @override
  String get tumFiilCekimleri => 'Все спряжения глагола';

  @override
  String kokRoot(Object root) {
    return 'корень $root';
  }

  @override
  String get cogul => 'Мн. ч.';

  @override
  String get ornekCumleler => 'Примеры предложений';

  @override
  String get cumleyiDinle => 'Прослушать';

  @override
  String get aiAsistanASor2 => 'Спросить ИИ-ассистента';

  @override
  String get dahaFazlaOrnek => 'Ещё примеры';

  @override
  String get kelimeKaydetmekIcinOnceGiris => 'Войдите, чтобы сохранить слово';

  @override
  String get oyna => 'Играть';

  @override
  String get verbFormPast => 'Мади';

  @override
  String get verbFormPresent => 'Мудари';

  @override
  String get verbFormInfinitive => 'Масдар';

  @override
  String get verbFormImperative => 'Амр';

  @override
  String get zamirOEril => 'Он (м.р.)';

  @override
  String get zamirOnlarEril => 'Они (м.р.)';

  @override
  String get zamirSenEril => 'Ты (м.р.)';

  @override
  String get zamirSizEril => 'Вы (м.р.)';

  @override
  String get zamirBen => 'Я';

  @override
  String get zamirBiz => 'Мы';

  @override
  String get dialectTr => 'Турецкий';

  @override
  String get dialectEn => 'Английский';

  @override
  String get dialectDe => 'Немецкий';

  @override
  String get dialectFr => 'Французский';

  @override
  String get dialectRu => 'Русский';

  @override
  String get dialectEs => 'Испанский';

  @override
  String get dialectIt => 'Итальянский';

  @override
  String get dialectPt => 'Португальский';

  @override
  String get dialectNl => 'Нидерландский';

  @override
  String get dialectFa => 'Персидский';

  @override
  String get dialectUr => 'Урду';

  @override
  String get dialectId => 'Индонезийский';

  @override
  String get dialectArStandard => 'Стандартный арабский';

  @override
  String get dialectArSyrian => 'Сирийский диалект';

  @override
  String get dialectArLebanese => 'Ливанский диалект';

  @override
  String get dialectArJordanian => 'Иорданский диалект';

  @override
  String get dialectArPalestinian => 'Палестинский диалект';

  @override
  String get dialectArEgyptian => 'Египетский диалект';

  @override
  String get dialectArIraqi => 'Иракский диалект';

  @override
  String get dialectArSudanese => 'Суданский диалект';

  @override
  String get dialectArSaudi => 'Саудовский диалект';

  @override
  String get dialectArEmirati => 'Эмиратский диалект';

  @override
  String get dialectArKuwaiti => 'Кувейтский диалект';

  @override
  String get dialectArQatari => 'Катарский диалект';

  @override
  String get dialectArOmani => 'Оманский диалект';

  @override
  String get dialectArYemeni => 'Йеменский диалект';

  @override
  String get dialectArMoroccan => 'Марокканский диалект';

  @override
  String get dialectArAlgerian => 'Алжирский диалект';

  @override
  String get dialectArTunisian => 'Тунисский диалект';

  @override
  String get dialectArLibyan => 'Ливийский диалект';

  @override
  String get appLanguage => 'Язык приложения';

  @override
  String get typeNoun => 'Имя сущ.';

  @override
  String get typeProperNoun => 'Имя собств.';

  @override
  String get typeVerb => 'Глагол';

  @override
  String get typeVerbPast => 'Глаг. мади';

  @override
  String get typeVerbPresent => 'Глаг. мудари';

  @override
  String get typeVerbImperative => 'Глаг. амр';

  @override
  String get typeVerbProhibitive => 'Глаг. нахи';

  @override
  String get typeVerbPastPassive => 'Мади пас.';

  @override
  String get typeVerbPresentPassive => 'Мудари пас.';

  @override
  String get typeVerbDefective => 'Накис';

  @override
  String get typeMasdar => 'Масдар';

  @override
  String get typeActiveParticiple => 'Исм фаиль';

  @override
  String get typePassiveParticiple => 'Исм мафуль';

  @override
  String get typeElative => 'Исм тафдиль';

  @override
  String get typeAdjective => 'Прилагат.';

  @override
  String get typeAdverb => 'Наречие';

  @override
  String get typeHal => 'Халь';

  @override
  String get typePronoun => 'Местоимение';

  @override
  String get typeDemonstrative => 'Указат. мест.';

  @override
  String get typeRelative => 'Относит. мест.';

  @override
  String get typeInterrogative => 'Вопр. частица';

  @override
  String get typePreposition => 'Харф-и джар';

  @override
  String get typeParticle => 'Частица';

  @override
  String get typeNumber => 'Числит.';

  @override
  String get typePhrase => 'Идафа';

  @override
  String get typeExpression => 'Выражение';

  @override
  String get typeIdiom => 'Идиома';

  @override
  String get siga01 => 'Прошедшее';

  @override
  String get siga02 => 'Настоящее';

  @override
  String get siga03 => 'Масдар';

  @override
  String get siga04 => 'Акт. причастие';

  @override
  String get siga05 => 'Пас. причастие';

  @override
  String get siga06 => 'Отриц. прош.';

  @override
  String get siga07 => 'Отриц. еще';

  @override
  String get siga08 => 'Отриц. наст.';

  @override
  String get siga09 => 'Отриц. буд.';

  @override
  String get siga10 => 'Усил. отр. буд.';

  @override
  String get siga11 => 'Повел. (3 л.)';

  @override
  String get siga12 => 'Запрет (3 л.)';

  @override
  String get siga13 => 'Повелительное';

  @override
  String get siga14 => 'Запретительное';

  @override
  String get siga15 => 'Имя места/врем.';

  @override
  String get siga16 => 'Имя орудия';

  @override
  String get siga17 => 'Имя кратности';

  @override
  String get siga18 => 'Имя вида';

  @override
  String get siga19 => 'Уменьшительное';

  @override
  String get siga20 => 'Относит. имя';

  @override
  String get siga21 => 'Интенсив';

  @override
  String get siga22 => 'Имя превосход.';

  @override
  String get siga23 => 'Восклицание 1';

  @override
  String get siga24 => 'Восклицание 2';

  @override
  String get dialectMs => 'Малайский';

  @override
  String get dialectBn => 'Бенгальский';

  @override
  String get dialectUz => 'Узбекский';

  @override
  String get dialectAz => 'Азербайджанский';

  @override
  String get prepositionsLabel => 'С предлогами';

  @override
  String get tashkeelToggle => 'Огласовки';

  @override
  String get tashkeelSettingHint =>
      'Показывать огласовки в определениях и примерах';

  @override
  String get rootMatches => 'Тот же корень';

  @override
  String get dictionaryLanguage => 'Язык словаря';

  @override
  String get dictionaryLanguageHint => 'Язык значений слов';

  @override
  String get arabicArabicDictionary => 'Арабско-арабский словарь';
}
