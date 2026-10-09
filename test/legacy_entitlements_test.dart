import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/services/legacy_entitlements.dart';

void main() {
  final now = DateTime.utc(2026, 6, 1);
  final future = DateTime.utc(2026, 12, 31);
  final past = DateTime.utc(2025, 1, 1);

  LegacyEntitlements evaluate(List<Map<String, dynamic>> docs) =>
      LegacyEntitlements.evaluate(docs, now: now);

  group('premium', () {
    test('belge yoksa premium değil', () {
      final result = evaluate([]);

      expect(result.premium, isFalse);
      expect(result.adsFree, isFalse);
      expect(result.purchasedBooks, isEmpty);
    });

    test('bitişsiz isPremium bayrağı premium verir', () {
      final result = evaluate([
        {'isPremium': true},
      ]);

      expect(result.premium, isTrue);
      expect(result.premiumExpiry, isNull);
    });

    test('bitişi geçmiş abonelik premium vermez', () {
      final result = evaluate([
        {'isPremium': true, 'premiumExpiry': past.toIso8601String()},
      ]);

      expect(result.premium, isFalse);
    });

    test('bitişi gelecekte olan abonelik bitiş tarihini taşır', () {
      final result = evaluate([
        {'is_premium': true, 'premium_expiry': future.millisecondsSinceEpoch},
      ]);

      expect(result.premium, isTrue);
      expect(result.premiumExpiry, future);
    });

    test('metin "true" ve 1 değerleri de bayrak sayılır', () {
      expect(evaluate([{'subscribed': 'true'}]).premium, isTrue);
      expect(evaluate([{'hasPremium': 1}]).premium, isTrue);
      expect(evaluate([{'isPremium': 'false'}]).premium, isFalse);
    });

    test('ömür boyu premium bitiş tarihi taşımaz', () {
      final result = evaluate([
        {'lifetimePremium': true, 'premiumExpiry': past.toIso8601String()},
      ]);

      expect(result.premium, isTrue);
      expect(result.premiumExpiry, isNull);
    });

    test('bayrak olmadan da gelecekteki bitiş tarihi premium verir', () {
      final result = evaluate([
        {'premiumUntil': Timestamp.fromDate(future)},
      ]);

      expect(result.premium, isTrue);
      expect(result.premiumExpiry, future);
    });

    test('durum metni "active" premium verir', () {
      expect(evaluate([{'subscriptionStatus': 'Active'}]).premium, isTrue);
      expect(evaluate([{'subscriptionStatus': 'expired'}]).premium, isFalse);
    });

    test('iç içe hak kaydı bitiş tarihine göre değerlendirilir', () {
      Map<String, dynamic> doc(DateTime expiry) => {
        'entitlements': {
          'premium': {'isActive': true, 'expiresAt': expiry.toIso8601String()},
        },
      };

      expect(evaluate([doc(future)]).premium, isTrue);
      expect(evaluate([doc(past)]).premium, isFalse);
    });

    test('birden çok belgede en geç bitiş tarihi seçilir', () {
      final later = DateTime.utc(2027, 3, 1);
      final result = evaluate([
        {'isPremium': true, 'premiumExpiry': future.toIso8601String()},
        {'isPremium': true, 'premiumExpiry': later.toIso8601String()},
      ]);

      expect(result.premiumExpiry, later);
    });
  });

  group('reklamsız ve kitaplar', () {
    test('reklam kaldırma bayrağı reklamsız yapar ama premium vermez', () {
      final result = evaluate([
        {'isAdsRemoved': true},
      ]);

      expect(result.adsFree, isTrue);
      expect(result.premium, isFalse);
    });

    test('purchasedBooks içindeki reklam ürünü reklamsız sayılır', () {
      final result = evaluate([
        {
          'purchasedBooks': ['kitab_kiraah_1', 'REMOVE_ADS'],
        },
      ]);

      expect(result.adsFree, isTrue);
      expect(result.purchasedBooks, {'kitab_kiraah_1', 'REMOVE_ADS'});
    });
  });

  group('parseFlexibleDate', () {
    test('saniye, milisaniye, ISO metni ve Timestamp haritasını çözer', () {
      final expected = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final seconds = expected.millisecondsSinceEpoch ~/ 1000;

      expect(parseFlexibleDate(seconds), expected);
      expect(parseFlexibleDate(expected.millisecondsSinceEpoch), expected);
      expect(parseFlexibleDate('$seconds'), expected);
      expect(parseFlexibleDate('2026-01-02T03:04:05Z'), expected);
      expect(parseFlexibleDate({'_seconds': seconds}), expected);
      expect(parseFlexibleDate(Timestamp.fromDate(expected)), expected);
    });

    test('tanınmayan değerler için null döner', () {
      expect(parseFlexibleDate(null), isNull);
      expect(parseFlexibleDate('yarın'), isNull);
      expect(parseFlexibleDate(true), isNull);
    });
  });
}
