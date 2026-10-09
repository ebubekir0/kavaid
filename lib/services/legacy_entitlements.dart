import 'package:cloud_firestore/cloud_firestore.dart';

/// Eski (RevenueCat öncesi) satın alma kayıtlarının değerlendirme sonucu.
///
/// Firestore'daki `users` belgelerinde yıllar içinde çok farklı alan
/// adlarıyla tutulmuş premium / reklamsız / kitap izlerini tek bir sonuca
/// indirger. Ağ erişimi yapmaz, bu yüzden birim testle doğrulanabilir.
///
/// GÜVENLİK NOTU: Bu alanlar kullanıcının kendi belgesinde durduğu için
/// Firestore kurallarında istemcinin bu alanları yazması engellenmelidir;
/// aksi halde kullanıcı kendine premium verebilir.
class LegacyEntitlements {
  const LegacyEntitlements({
    required this.premium,
    required this.adsFree,
    required this.premiumExpiry,
    required this.purchasedBooks,
  });

  final bool premium;
  final bool adsFree;

  /// Premium bitiş tarihi (UTC). Ömür boyu premium veya bitiş bilinmiyorsa null.
  final DateTime? premiumExpiry;

  final Set<String> purchasedBooks;

  /// Reklam kaldırma ürünlerinin eski kimlikleri (purchasedBooks içinde
  /// tutulmuş olabilir; bunlar kitap sayılmaz).
  static const List<String> adsProductIds = [
    'remove_ads',
    'ads_remove',
    'reklam_kaldir',
    'reklam_kaldirma',
    'ads_free',
    'no_ads',
    'ad_free',
    'premium_ads',
    'adsfree',
    'noads',
    'lifetime_ads',
    'removeads',
  ];

  static const List<String> _lifetimePremiumFields = [
    'lifetimePremium',
    'isLifetimePremium',
    'premiumForever',
    'permanentPremium',
    'lifetimeAdsFree',
  ];

  static const List<String> _premiumBoolFields = [
    'isPremium',
    'is_premium',
    'premium',
    'premiumActive',
    'isPremiumActive',
    'hasPremium',
    'premiumMember',
    'subscriptionActive',
    'isSubscribed',
    'subscribed',
  ];

  static const List<String> _premiumExpiryFields = [
    'premiumExpiry',
    'premium_expiry',
    'premiumExpiresAt',
    'premium_expires_at',
    'premiumUntil',
    'premium_until',
    'subscriptionExpiry',
    'subscription_expiry',
    'subscriptionExpiresAt',
    'subscription_expires_at',
    'expiresAt',
  ];

  static const List<String> _nestedExpiryFields = [
    'expiresAt',
    'expirationDate',
    'expiry',
    'expires',
    'until',
    'premiumUntil',
    'premiumExpiry',
    'subscriptionExpiry',
  ];

  static const List<String> _adsFreeFields = [
    'lifetimeAdsFree',
    'isAdsRemoved',
    'adsRemoved',
    'ads_removed',
    'removeAds',
    'is_ads_removed',
  ];

  static const List<String> _namedEntitlementKeys = [
    'premium',
    'pro',
    'subscription',
    'kavaid_premium',
  ];

  /// [docs] içindeki tüm belgeleri birlikte değerlendirir; herhangi biri
  /// premium/reklamsız ise sonuç da öyledir. [now] UTC olmalıdır.
  static LegacyEntitlements evaluate(
    Iterable<Map<String, dynamic>> docs, {
    required DateTime now,
  }) {
    var premium = false;
    var adsFree = false;
    DateTime? premiumExpiry;
    final books = <String>{};

    for (final data in docs) {
      final hasLifetimePremium = _lifetimePremiumFields.any(
        (field) => _isTrue(data[field]),
      );

      final hasPremiumFlag =
          _premiumBoolFields.any((field) => _isTrue(data[field])) ||
          _isActiveFlag(data['premiumStatus']) ||
          _isActiveFlag(data['subscriptionStatus']) ||
          _activeNestedEntitlement(data['premium'], now) ||
          _activeNestedEntitlement(data['subscription'], now) ||
          _activeNestedEntitlement(data['entitlement'], now) ||
          _activeNestedEntitlement(data['entitlements'], now) ||
          _activeNamedEntitlement(data['entitlements'], now) ||
          _activeNamedEntitlement(data['purchases'], now);

      final docExpiry = _firstDate(data, _premiumExpiryFields);

      if (hasLifetimePremium) {
        premium = true;
        premiumExpiry = null;
      } else if (hasPremiumFlag &&
          (docExpiry == null || docExpiry.isAfter(now))) {
        premium = true;
        premiumExpiry = latestDate(premiumExpiry, docExpiry);
      } else if (!hasPremiumFlag &&
          docExpiry != null &&
          docExpiry.isAfter(now)) {
        premium = true;
        premiumExpiry = latestDate(premiumExpiry, docExpiry);
      }

      if (_adsFreeFields.any((field) => _isTrue(data[field]))) {
        adsFree = true;
      }

      final docBooks = data['purchasedBooks'];
      if (docBooks is List) {
        books.addAll(docBooks.map((e) => e.toString()));
        if (docBooks.any(
          (id) => adsProductIds.contains(id.toString().toLowerCase()),
        )) {
          adsFree = true;
        }
      }
    }

    return LegacyEntitlements(
      premium: premium,
      adsFree: adsFree,
      premiumExpiry: premiumExpiry,
      purchasedBooks: books,
    );
  }

  static bool _isTrue(Object? value) {
    if (value == true) return true;
    if (value is String && value.toLowerCase() == 'true') return true;
    if (value is int && value == 1) return true;
    return false;
  }

  static bool _isActiveFlag(Object? value) {
    if (value == true) return true;
    if (value is int && value == 1) return true;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' ||
          normalized == 'active' ||
          normalized == 'premium' ||
          normalized == 'paid' ||
          normalized == 'subscribed' ||
          normalized == 'valid' ||
          normalized == 'enabled';
    }
    return false;
  }

  static DateTime? _firstDate(Map<dynamic, dynamic> data, List<String> fields) {
    for (final field in fields) {
      final parsed = parseFlexibleDate(data[field]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// `{active: true, expiresAt: ...}` biçimindeki iç içe hak kaydı aktif mi?
  static bool _activeNestedEntitlement(Object? value, DateTime now) {
    if (value is! Map) return false;
    final expiry = _firstDate(value, _nestedExpiryFields);
    final hasActiveMarker =
        _isActiveFlag(value['active']) ||
        _isActiveFlag(value['isActive']) ||
        _isActiveFlag(value['enabled']) ||
        _isActiveFlag(value['status']) ||
        _isActiveFlag(value['state']);
    return hasActiveMarker && (expiry == null || expiry.isAfter(now));
  }

  /// `{premium: {...}}` veya `{premium: true}` biçimindeki adlandırılmış
  /// hak kayıtlarından biri aktif mi?
  static bool _activeNamedEntitlement(Object? container, DateTime now) {
    if (container is! Map) return false;
    for (final key in _namedEntitlementKeys) {
      final value = container[key];
      if (value is Map) {
        if (_activeNestedEntitlement(value, now)) return true;
      } else if (_isActiveFlag(value)) {
        return true;
      }
    }
    return false;
  }
}

/// Firestore Timestamp, DateTime, saniye/milisaniye (sayı veya metin),
/// ISO-8601 metni ya da `{_seconds, _nanoseconds}` haritasını UTC tarihe
/// çevirir. Tanınmayan değerler için null döner.
DateTime? parseFlexibleDate(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is int) {
    final millis = value.abs() < 10000000000 ? value * 1000 : value;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
  if (value is double) {
    final raw = value.toInt();
    final millis = raw.abs() < 10000000000 ? raw * 1000 : raw;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
  if (value is String) {
    final trimmed = value.trim();
    final numeric = int.tryParse(trimmed);
    if (numeric != null) {
      final millis = numeric.abs() < 10000000000 ? numeric * 1000 : numeric;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
    return DateTime.tryParse(trimmed)?.toUtc();
  }
  if (value is Map) {
    final seconds = value['_seconds'] ?? value['seconds'];
    final nanos = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;
    if (seconds is int) {
      final millis = seconds * 1000 + ((nanos is int ? nanos : 0) ~/ 1000000);
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
  }
  return null;
}

/// İki tarihten daha geç olanı (biri null ise diğerini) döndürür.
DateTime? latestDate(DateTime? first, DateTime? second) {
  if (first == null) return second;
  if (second == null) return first;
  return first.isAfter(second) ? first : second;
}
