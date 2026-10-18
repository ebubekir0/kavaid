import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/services/purchase_manager.dart';

void main() {
  group('Premium önbelleği yalnızca sahibine uygulanır', () {
    test('oturum kapalıyken önceki hesabın önbelleği uygulanmaz', () {
      expect(PurchaseManager.cacheBelongsTo('uid-1', null), isFalse);
    });

    test('hesapsız satın alım önbelleği oturum kapalıyken uygulanır', () {
      expect(PurchaseManager.cacheBelongsTo(null, null), isTrue);
      expect(PurchaseManager.cacheBelongsTo('', null), isTrue);
    });

    test('aynı hesap uygulanır, başka hesap uygulanmaz', () {
      expect(PurchaseManager.cacheBelongsTo('uid-1', 'uid-1'), isTrue);
      expect(PurchaseManager.cacheBelongsTo('uid-1', 'uid-2'), isFalse);
      expect(PurchaseManager.cacheBelongsTo('', 'uid-1'), isFalse);
    });

    test('ayrıntılı kayıt yalnızca aynı girişli hesaba uygulanır', () {
      expect(PurchaseManager.snapshotBelongsTo('uid-1', 'uid-1'), isTrue);
      expect(PurchaseManager.snapshotBelongsTo('uid-1', null), isFalse);
      expect(PurchaseManager.snapshotBelongsTo('uid-1', 'uid-2'), isFalse);
      expect(PurchaseManager.snapshotBelongsTo(null, null), isFalse);
    });
  });
}
