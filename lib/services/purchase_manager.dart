import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'promo_code_service.dart';
import 'connectivity_service.dart';
import 'legacy_entitlements.dart';

const _apiKeyAndroid = 'goog_JUkLUxlscZqowPzLzmvYPKddTbE';
const _apiKeyIOS = 'appl_NZgrRHVUkpanVmNiCcqlEpQlMXo';

class PurchaseManager extends ChangeNotifier {
  static final PurchaseManager _instance = PurchaseManager._internal();
  factory PurchaseManager() => _instance;
  
  Future<void>? _loadCacheFuture;

  PurchaseManager._internal() {
    _loadLocalCache();
  }

  static const String _entitlementCacheKey = 'purchase_entitlement_snapshot_v1';

  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isRevenueCatConfigured = false;
  bool _customerInfoListenerAdded = false;
  bool _entitlementsResolved = false;
  bool _entitlementPending = true;
  bool _usingOfflineSnapshot = false;

  Future<void>? _initializeFuture;
  Future<void>? _offeringsFuture;
  Future<void>? _entitlementRefreshFuture;
  String? _entitlementRefreshUserId;
  StreamSubscription<User?>? _authSubscription;
  String? _lastAuthUserId;

  bool _isPremium = false;
  bool _isLifetimeNoAds = false;
  bool _isPromoPremium = false;
  bool _hasUsedPromo = false;
  Timer? _promoExpiryTimer;
  Set<String> _purchasedBooks = {};

  bool _legacyChecked = false;
  bool _cachedLegacyPremium = false;
  bool _cachedLegacyAdsFree = false;

  DateTime? _subscriptionExpiryDate;
  DateTime? _promoExpiryDate;
  DateTime? _lastVerifiedAt;
  String _entitlementSource = '';
  String _lastError = '';

  Offerings? _offerings;

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  bool get entitlementsResolved => _entitlementsResolved;
  bool get isEntitlementPending => _entitlementPending;
  bool get usingOfflineSnapshot => _usingOfflineSnapshot;

  // DÜZELTME: ham _isPremium yerine bitiş kontrolü yapan isPremium
  // getter'ı kullanılıyor. Yoksa süresi dolmuş ama timer henüz
  // tetiklenmemişken reklamlar gizli kalıyordu.
  bool get shouldShowAds =>
      !_entitlementPending &&
      !isPremium &&
      !_isLifetimeNoAds;

  bool get isPremium {
    // Bitiş tarihi geçmişse premium'u düşür (canlı kontrol).
    // _subscriptionExpiryDate == null => lifetime veya RevenueCat aktif
    // (tarihsiz) durumudur, premium korunur.
    if (_isSubscriptionExpired) {
      // Abonelik bitti; promo hâlâ geçerliyse ondan devam et.
      final promoExpiry = _promoExpiryDate;
      if (promoExpiry == null) return _isPromoPremium;
      if (DateTime.now().toUtc().isAfter(promoExpiry.toUtc())) {
        return false;
      }
      return _isPromoPremium;
    }
    return _isPremium || _isPromoPremium;
  }

  /// Abonelik süresi dolmuş mu? (canlı kontrol)
  bool get isSubscriptionExpired => _isSubscriptionExpired;
  bool get _isSubscriptionExpired {
    final exp = _subscriptionExpiryDate;
    if (exp == null) return false;
    return DateTime.now().toUtc().isAfter(exp.toUtc());
  }

  /// Promo dahil en geç bitiş tarihi bitmiş mi?
  bool get isEntitlementExpired {
    final exp = subscriptionExpiryDate;
    if (exp == null) {
      // Tarih yoksa: herhangi bir premium flag varsa lifetime say.
      return !_isPremium && !_isPromoPremium;
    }
    return DateTime.now().toUtc().isAfter(exp.toUtc());
  }
  bool get isPromoPremium => _isPromoPremium;
  bool get hasUsedPromo => _hasUsedPromo;
  bool get isLifetimeNoAds => _isLifetimeNoAds;
  bool get isAvailable => _isInitialized;
  String get lastError => _lastError;
  Set<String> get purchasedBooks => _purchasedBooks;
  DateTime? get subscriptionExpiryDate =>
      latestDate(_subscriptionExpiryDate, _promoExpiryDate);
  DateTime? get lastVerifiedAt => _lastVerifiedAt;
  String get entitlementSource => _entitlementSource;

  bool canAccessContent(String bookId, bool isFreeContent) {
    if (isFreeContent) return true;

    if (isPremium) {
      debugPrint('[PurchaseManager] Access granted ($bookId): premium active');
      return true;
    }

    if (_purchasedBooks.contains(bookId)) {
      debugPrint('[PurchaseManager] Access granted ($bookId): single purchase');
      return true;
    }

    if (_entitlementPending) {
      debugPrint(
        '[PurchaseManager] Access pending ($bookId): entitlements unresolved',
      );
    } else {
      debugPrint('[PurchaseManager] Access blocked ($bookId): not premium');
    }
    return false;
  }

  Future<void> bootstrapEntitlements() => initialize(fetchOfferings: false);

  Future<void> refreshEntitlements({
    bool includePromo = true,
    bool fetchOfferings = false,
  }) async {
    if (!_isInitialized) {
      await initialize(fetchOfferings: fetchOfferings);
      return;
    }

    await _ensureRevenueCatReady();

    await _handleAuthUser(
      FirebaseAuth.instance.currentUser,
      logOutOnNull: false,
      forceRefresh: true,
      includePromo: includePromo,
    );

    if (fetchOfferings) await fetchProducts();
  }

  Future<void> initialize({bool fetchOfferings = true}) async {
    // Önce hızlı yerel önbelleği bekle (constructor'da başlatıldı)
    await _loadLocalCache();

    if (_isInitialized) {
      await _handleAuthUser(
        FirebaseAuth.instance.currentUser,
        logOutOnNull: false,
      );
      if (fetchOfferings) await fetchProducts();
      return;
    }

    final existing = _initializeFuture;
    if (existing != null) {
      await existing;
      await _handleAuthUser(
        FirebaseAuth.instance.currentUser,
        logOutOnNull: false,
      );
      if (fetchOfferings) await fetchProducts();
      return;
    }

    _isInitializing = true;
    _initializeFuture = _initializeCore();

    try {
      await _initializeFuture;
    } finally {
      _isInitializing = false;
      if (!_isInitialized) {
        _initializeFuture = null;
      }
      notifyListeners();
    }

    if (fetchOfferings) await fetchProducts();
  }

  Future<void> _initializeCore() async {
    // Hızlı yerel önbellek zaten constructor'da yüklendi, sadece bekle
    await _loadLocalCache();
    // JSON snapshot'tan da yükle (daha fazla bilgi içerebilir)
    await _applyCachedEntitlementSnapshot();

    debugPrint('[RevenueCat] Initializing...');
    await _ensureRevenueCatReady();
    _attachAuthListener();

    await _handleAuthUser(
      FirebaseAuth.instance.currentUser,
      logOutOnNull: false,
    );

    _isInitialized = true;
    debugPrint('[RevenueCat] Initialized');
  }

  Future<void> _configureRevenueCat() async {
    if (_isRevenueCatConfigured) return;
    if (kIsWeb) return;

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

    final PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKeyAndroid);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKeyIOS);
    } else {
      return;
    }

    await Purchases.configure(
      configuration,
    ).timeout(const Duration(seconds: 8));
    _isRevenueCatConfigured = true;
  }

  Future<void> _ensureRevenueCatReady() async {
    if (_isRevenueCatConfigured || kIsWeb) return;

    try {
      await _configureRevenueCat();
      _attachCustomerInfoListener();
    } catch (e) {
      _lastError = 'RevenueCat baslatilamadi: $e';
      debugPrint('[RevenueCat] Configure error: $e');
    }
  }

  void _attachCustomerInfoListener() {
    if (_customerInfoListenerAdded || kIsWeb || !_isRevenueCatConfigured) {
      return;
    }
    _customerInfoListenerAdded = true;
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      unawaited(_updateCustomerStatus(customerInfo));
    });
  }

  void _attachAuthListener() {
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      unawaited(_handleAuthUser(user));
    });
  }

  Future<void> _handleAuthUser(
    User? user, {
    bool logOutOnNull = true,
    bool forceRefresh = false,
    bool includePromo = true,
  }) async {
    // İnterneti kontrol et. Çevrimdışıysa HEMEN çık ve önbellekten yükle.
    final hasInternet = await ConnectivityService().hasInternetConnection();
    // Çevrimdışı mod: önce JSON snapshot dene, sonra hızlı cache dene
    if (!hasInternet) {
      debugPrint('[PurchaseManager] Çevrimdışı mod — Auth değişimi es geçiliyor.');
      if (!_entitlementsResolved) {
        await _applyCachedEntitlementSnapshot();
        if (!_entitlementsResolved) {
          // Diske zorla tekrar bak (future zaten tamamlanmış olabilir)
          _loadCacheFuture = null;
          await _loadLocalCache();
        }
      }
      // Kesinlikle pending'i kapat, kullanıcıyı premium-suz bırakma
      if (_isPremium || _isLifetimeNoAds) {
        _entitlementPending = false;
        notifyListeners();
      }
      return;
    }

    final uid = user?.uid;

    // Null user çevrimiçide: kullanıcı giriş yapmamış veya çıkış yapmış
    if (uid == null) {
      _lastAuthUserId = null;
      _legacyChecked = false;
      _cachedLegacyPremium = false;
      _cachedLegacyAdsFree = false;
      _isPromoPremium = false;
      _hasUsedPromo = false;
      _promoExpiryDate = null;
      _promoExpiryTimer?.cancel();

      // Cihazın StoreKit / RevenueCat durumunu sorgula (Anonim satın almalar)
      if (_isRevenueCatConfigured) {
        try {
          final customerInfo = await Purchases.getCustomerInfo();
          await _updateCustomerStatus(customerInfo);
        } catch (e) {
          debugPrint('[RevenueCat] Anonim customerInfo hatası: $e');
        }
      }

      // Eğer StoreKit'ten aktif abonelik gelmediyse önbellekteki son durumu kontrol et
      if (!_isPremium && !_isLifetimeNoAds) {
        await _applyCachedEntitlementSnapshot();
      }

      _entitlementPending = false;
      _entitlementsResolved = true;
      notifyListeners();
      return;
    }

    if (!forceRefresh &&
        _lastAuthUserId == uid &&
        _entitlementsResolved &&
        !_usingOfflineSnapshot) {
      return;
    }

    final userChanged = _lastAuthUserId != uid;
    _lastAuthUserId = uid;
    if (userChanged) {
      _clearRuntimeEntitlements();
      _legacyChecked = false;
      _cachedLegacyPremium = false;
      _cachedLegacyAdsFree = false;
    }
    if (forceRefresh || _usingOfflineSnapshot) {
      _legacyChecked = false;
      _cachedLegacyPremium = false;
      _cachedLegacyAdsFree = false;
    }

    // Önce önbelleği yükle (hızlı premium gösterimi)
    await _applyCachedEntitlementSnapshot();

    if (!_usingOfflineSnapshot || !_entitlementsResolved) {
      _markEntitlementCheckPending();
    }

    if (_isRevenueCatConfigured) {
      try {
        await Purchases.logIn(uid).timeout(const Duration(seconds: 5));
        await Purchases.syncPurchases().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[RevenueCat] login/sync error: $e');
      }
    }

    await _refreshEntitlementsFromStores(includePromo: includePromo);
  }

  void _markEntitlementCheckPending() {
    if (_entitlementPending) return;
    _entitlementPending = true;
    notifyListeners();
  }

  void _clearRuntimeEntitlements() {
    _isPremium = false;
    _isLifetimeNoAds = false;
    _isPromoPremium = false;
    _hasUsedPromo = false;
    _purchasedBooks.clear();
    _subscriptionExpiryDate = null;
    _promoExpiryDate = null;
    _lastVerifiedAt = null;
    _entitlementSource = '';
    _usingOfflineSnapshot = false;
    _entitlementsResolved = false;
    _entitlementPending = true;
    _promoExpiryTimer?.cancel();
    // NOT: Diske YAZMA — yalnızca RAM'i temizle.
    // Sonraki initialize çevrimdışı açılışta diski tekrar okusun diye future'u sıfırla
    _loadCacheFuture = null;
  }

  Future<void> _refreshEntitlementsFromStores({
    bool includePromo = true,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final existing = _entitlementRefreshFuture;
    if (existing != null && _entitlementRefreshUserId == currentUid) {
      return existing;
    }

    _entitlementRefreshUserId = currentUid;
    _entitlementRefreshFuture =
        _refreshEntitlementsFromStoresInternal(
          includePromo: includePromo,
        ).whenComplete(() {
          _entitlementRefreshFuture = null;
          _entitlementRefreshUserId = null;
        });

    return _entitlementRefreshFuture;
  }

  Future<void> _refreshEntitlementsFromStoresInternal({
    required bool includePromo,
  }) async {
    var checkedLegacy = false;
    var legacyFailed = false;
    var revenueCatSucceeded = false;

    final tasks = <Future<void>>[
      (() async {
        try {
          revenueCatSucceeded = await _fetchCustomerInfo().timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('[RevenueCat] customerInfo timeout/error: $e');
        }
      })(),
      (() async {
        try {
          await _checkLegacyPermissions(
            onLegacyFound: (legacyPremium, legacyAdsFree) {
              _cachedLegacyPremium = legacyPremium;
              _cachedLegacyAdsFree = legacyAdsFree;
              _legacyChecked = true;
              checkedLegacy = true;
              if (legacyPremium) _isPremium = true;
              if (legacyAdsFree) _isLifetimeNoAds = true;
            },
          ).timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('[PurchaseManager] legacy timeout/error: $e');
          legacyFailed = true;
        }
      })(),
    ];

    if (includePromo) {
      tasks.add(
        checkPromoPremium().timeout(const Duration(seconds: 5)).catchError((e) {
          debugPrint('[PurchaseManager] promo timeout/error: $e');
        }),
      );
    }

    await Future.wait(tasks);

    // TÜM kaynaklar başarısız olduysa → mevcut state'i koru
    if (!checkedLegacy && !revenueCatSucceeded) {
      debugPrint('[PurchaseManager] Tüm veri kaynakları başarısız — mevcut premium durumu korunuyor');
      if (_entitlementPending && (_isPremium || _isLifetimeNoAds || _purchasedBooks.isNotEmpty)) {
        _entitlementPending = false;
        notifyListeners();
      }
      return;
    }

    // KORUMA: Legacy kontrol hata verdi VE premium düşürülecekse → iptal
    if (legacyFailed && !checkedLegacy) {
      final wouldDowngrade = !_isPremium && !_isLifetimeNoAds && _purchasedBooks.isEmpty;
      if (wouldDowngrade && _usingOfflineSnapshot) {
        debugPrint('[PurchaseManager] Legacy hata + offline snapshot → mevcut durum korunuyor');
        if (_entitlementPending) {
          _entitlementPending = false;
          notifyListeners();
        }
        return;
      }
    }

    if (_cachedLegacyPremium ||
        _cachedLegacyAdsFree ||
        _purchasedBooks.isNotEmpty) {
      _applyVerifiedEntitlements(
        isPremium: _isPremium || _cachedLegacyPremium,
        isLifetimeNoAds: _isLifetimeNoAds || _cachedLegacyAdsFree,
        purchasedBooks: _purchasedBooks,
        expiresAt: _subscriptionExpiryDate,
        source: 'firebase_legacy',
      );
    } else if (checkedLegacy) {
      // DÜZELTME: sadece pending'de değil, her zaman downgrade et.
      // Önceden stale cache'teki _isPremium=true burada tekrar uygulanıp
      // bitiş hiç düşürülemiyordu. Artık expiry kontrolü
      // _applyVerifiedEntitlements içinde yapılıyor ve bitmişse false
      // uygulanıyor.
      final expiryExpired = _subscriptionExpiryDate != null &&
          DateTime.now().toUtc().isAfter(_subscriptionExpiryDate!.toUtc());

      // RevenueCat başarılıysa _isPremium zaten taze RC sonucudur → onu kullan.
      // RC BAŞARISIZSA (ağ kesintisi, 5sn timeout) mevcut durumu DÜŞÜRME:
      // yerel cache'te premium görünüyorsa ve bitiş tarihi GELECEKTE ise
      // abonelik geçerlidir, korunmalı. Aksi halde aktif aboneli kullanıcı
      // anlık internet dalgalanmasında premium'unu kaybediyordu.
      final keepCachedPremium = _isPremium && !_isSubscriptionExpired;
      final effectivePremium =
          revenueCatSucceeded ? _isPremium : keepCachedPremium;

      _applyVerifiedEntitlements(
        isPremium: expiryExpired ? false : effectivePremium,
        isLifetimeNoAds: _isLifetimeNoAds || _cachedLegacyAdsFree,
        purchasedBooks: _purchasedBooks,
        expiresAt: _subscriptionExpiryDate,
        source: 'firebase_legacy',
      );
    }

    if (_isPremium || _isLifetimeNoAds || _purchasedBooks.isNotEmpty) {
      await _saveEntitlementSnapshot(source: 'verified');
    } else if (!_entitlementPending) {
      await _saveEntitlementSnapshot(source: 'verified');
    }
  }

  Future<bool> _fetchCustomerInfo() async {
    if (!_isRevenueCatConfigured) return false;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      await _updateCustomerStatus(customerInfo);
      return true;
    } catch (e) {
      debugPrint('[RevenueCat] CustomerInfo error: $e');
      return false;
    }
  }

  Future<void> _updateCustomerStatus(CustomerInfo customerInfo) async {
    // Çevrimdışıyken RevenueCat SDK eski cache ile listener tetikler.
    final hasInternet = await ConnectivityService().hasInternetConnection();
    if (!hasInternet) {
      debugPrint('[PurchaseManager] Çevrimdışı: RevenueCat CustomerInfo güncellemesi atlandı');
      return;
    }

    final entitlements = customerInfo.entitlements.all;
    final premiumEntitlement =
        entitlements['premium'] ??
        _firstActiveEntitlement(entitlements, const ['premium', 'pro', 'sub', 'yearly', 'annual', 'monthly']);
    final adsFreeEntitlement =
        entitlements['ads_free'] ??
        _firstActiveEntitlement(entitlements, const [
          'ads_free',
          'no_ads',
          'ad_free',
          'adsfree',
        ]);

    var newPremiumStatus = premiumEntitlement?.isActive ?? false;
    var newAdsFreeStatus = adsFreeEntitlement?.isActive ?? false;

    // STOREKIT DIRECT ACTIVE SUBSCRIPTIONS CHECK:
    // RevenueCat dashboard'da entitlement eşleştirilmemiş olsa dahi,
    // Apple'da aktif aboneliği olan kullanıcıyı KESİNLİKLE Premium yap!
    if (customerInfo.activeSubscriptions.isNotEmpty) {
      debugPrint('[PurchaseManager] Aktif StoreKit aboneliği algılandı: ${customerInfo.activeSubscriptions}');
      newPremiumStatus = true;
    }

    if (customerInfo.entitlements.active.isNotEmpty) {
      debugPrint('[PurchaseManager] Aktif Entitlement algılandı: ${customerInfo.entitlements.active.keys}');
      newPremiumStatus = true;
    }

    // Reklam kaldırma ürün kontrolü
    for (final id in customerInfo.allPurchasedProductIdentifiers) {
      final lower = id.toLowerCase();
      if (lower.contains('remove_ads') ||
          lower.contains('no_ads') ||
          lower.contains('ad_free') ||
          lower.contains('reklam')) {
        newAdsFreeStatus = true;
      }
    }

    DateTime? expiry = _parseDate(
      premiumEntitlement?.expirationDate ?? customerInfo.latestExpirationDate,
    );
    // NOT: expiry null ise uydurma tarih YAZMA.
    // RevenueCat aktif diyorsa o an için premium ver, ancak kalıcı
    // cache/Firestore'a "1 yıl" gibi sahte bitiş yazıp gerçek bitişi
    // maskeleme. expiry null kalır, bir sonraki refresh doğrusunu getirir.

    var legacyFailed = false;
    if (!_legacyChecked) {
      try {
        // ANR: Firestore takılırsa (kötü ağ) UI isolate'te bekleyen
        // future yığılmasın. Dış timeout zaten var ama bu yol
        // timeout'suz da çağrılıyordu (listener).
        await _checkLegacyPermissions(
          onLegacyFound: (legacyPremium, legacyAdsFree) {
            _cachedLegacyPremium = legacyPremium;
            _cachedLegacyAdsFree = legacyAdsFree;
            if (legacyPremium) newPremiumStatus = true;
            if (!newAdsFreeStatus && legacyAdsFree) newAdsFreeStatus = true;
          },
        ).timeout(const Duration(seconds: 4));
        _legacyChecked = true;
      } catch (e) {
        debugPrint('[PurchaseManager] Legacy kontrol hatası: $e');
        legacyFailed = true;
        // Önceki cached değerleri koru
        if (_cachedLegacyPremium) newPremiumStatus = true;
        if (_cachedLegacyAdsFree) newAdsFreeStatus = true;
      }
    } else {
      if (_cachedLegacyPremium) newPremiumStatus = true;
      if (!newAdsFreeStatus && _cachedLegacyAdsFree) {
        newAdsFreeStatus = true;
      }
    }

    // KORUMA: Legacy kontrol HATA verdi VE sonuç premium düşürülecekse → iptal
    final wouldDowngrade = (_isPremium || _isLifetimeNoAds || _usingOfflineSnapshot) &&
        !newPremiumStatus && !newAdsFreeStatus;
    if (legacyFailed && wouldDowngrade) {
      debugPrint('[PurchaseManager] Legacy hata + premium downgrade → mevcut durum korunuyor');
      return;
    }

    final verifiedExpiry = _cachedLegacyPremium
        ? _subscriptionExpiryDate
        : expiry;

    _applyVerifiedEntitlements(
      isPremium: newPremiumStatus,
      isLifetimeNoAds: newAdsFreeStatus,
      purchasedBooks: _purchasedBooks,
      expiresAt: verifiedExpiry,
      source: 'revenuecat',
    );

    await _saveEntitlementSnapshot(source: 'revenuecat');

    // Kullanıcı Firebase'e giriş yapmışsa Firestore'a da eşitle.
    // KRİTİK: sadece true değil, false (bitiş) durumu da yazılmalı.
    // Yoksa Firestore'da eski isPremium:true sonsuza kadar kalıp
    // legacy kontrolü tekrar premium yapar (sonsuz premium bug'ı).
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        if (newPremiumStatus) {
          // expiry null + aktif = RevenueCat tarihsiz aktiflik.
          // Bunu lifetime gibi Firestore'a null yazma; legacy tarafı
          // null expiry + isPremium:true'yu lifetime sanır.
          // Bu durumda premiumExpiry alanına dokunma (eski tarihi koru).
          final data = <String, Object?>{
            'isPremium': true,
            'premiumSource': 'storekit_revenuecat',
            'lastVerifiedAt': FieldValue.serverTimestamp(),
          };
          if (verifiedExpiry != null) {
            data['premiumExpiry'] = verifiedExpiry.toIso8601String();
          }
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set(data, SetOptions(merge: true));
        } else if (_legacyChecked &&
            !_cachedLegacyPremium &&
            !_isPromoPremium) {
          // StoreKit + legacy ikisi de premium yok diyor ve promo da yok:
          // bitişi Firestore'a işle ki legacy tekrar diriltmesin.
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'isPremium': false,
            'premiumSource': 'storekit_revenuecat_expired',
            'lastVerifiedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint('[PurchaseManager] Premium bitişi Firestore\'a işlendi');
        }
        debugPrint('✅ [PurchaseManager] Premium Firestore kullanıcı hesabına eşitlendi');
      } catch (e) {
        debugPrint('⚠️ [PurchaseManager] Firestore sync hatası: $e');
      }
    }
  }

  EntitlementInfo? _firstActiveEntitlement(
    Map<String, EntitlementInfo> entitlements,
    List<String> keywords,
  ) {
    for (final entry in entitlements.entries) {
      final id = entry.key.toLowerCase();
      final info = entry.value;
      if (!info.isActive) continue;
      if (keywords.any(id.contains)) return info;
    }
    return null;
  }

  void _applyVerifiedEntitlements({
    required bool isPremium,
    required bool isLifetimeNoAds,
    required Set<String> purchasedBooks,
    required DateTime? expiresAt,
    required String source,
  }) {
    // Bitiş tarihi geçmişse memory'de premium tutma.
    // expiresAt == null => lifetime / tarihsiz aktiflik, korunur.
    var effectivePremium = isPremium;
    if (expiresAt != null &&
        DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
      effectivePremium = false;
    }
    final changed =
        _isPremium != effectivePremium ||
        _isLifetimeNoAds != isLifetimeNoAds ||
        !_setEquals(_purchasedBooks, purchasedBooks) ||
        _subscriptionExpiryDate != expiresAt ||
        _entitlementPending ||
        !_entitlementsResolved ||
        _usingOfflineSnapshot;

    _isPremium = effectivePremium;
    _isLifetimeNoAds = isLifetimeNoAds;
    _purchasedBooks = Set<String>.from(purchasedBooks);
    _subscriptionExpiryDate = expiresAt;
    _lastVerifiedAt = DateTime.now().toUtc();
    _entitlementSource = source;
    _entitlementsResolved = true;
    _entitlementPending = false;
    _usingOfflineSnapshot = false;

    if (changed) {
      notifyListeners();
      debugPrint(
        '[PurchaseManager] Entitlements updated -> premium: $effectivePremium, adsFree: $isLifetimeNoAds, books: ${_purchasedBooks.length}, expires: $expiresAt',
      );
    }
    _startSubscriptionExpiryTimer();
    unawaited(_saveLocalCache());
  }

  bool get hasActiveBooks {
    if (_purchasedBooks.isEmpty) return false;
    return _purchasedBooks.any(
      (id) => !LegacyEntitlements.adsProductIds.contains(id.toLowerCase()),
    );
  }

  Future<void> _checkLegacyPermissions({
    required Function(bool isLegacyPremium, bool isLegacyAdsFree) onLegacyFound,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      onLegacyFound(false, false);
      return;
    }

    try {
      final legacyDocs = <Map<String, dynamic>>[];
      final docIds = <String>[
        user.uid,
        if ((user.email ?? '').isNotEmpty && user.email != user.uid)
          user.email!,
      ];

      final now = DateTime.now().toUtc();

      for (final docId in docIds.toSet()) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .get();
        if (doc.exists && doc.data() != null) {
          legacyDocs.add(doc.data()!);
        }
      }

      final email = user.email;
      if (email != null && email.isNotEmpty) {
        final emailQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(5)
            .get();
        for (final doc in emailQuery.docs) {
          legacyDocs.add(doc.data());
        }
      }

      final legacy = LegacyEntitlements.evaluate(legacyDocs, now: now);

      if (legacy.purchasedBooks.isNotEmpty) {
        _purchasedBooks = legacy.purchasedBooks;
      }

      if (legacy.premium) {
        _subscriptionExpiryDate = legacy.premiumExpiry;
      }

      onLegacyFound(legacy.premium, legacy.adsFree);
    } catch (e) {
      debugPrint('[PurchaseManager] Legacy check error: $e');
      onLegacyFound(false, false);
    }
  }

  static const List<String> monthlyProductIds = [
    'premium_monthly',
    'kavaid_premium_monthly',
    'kavaid_monthly_subscription',
    'kavaid_monthly_premium',
    'monthly_subscription',
    'kavaid_premium_1month',
    'kavaid_subscription_monthly',
  ];

  static const List<String> yearlyProductIds = [
    'premium_yearly',
    'kavaid_premium_yearly',
    'kavaid_yearly_subscription',
    'kavaid_yearly_premium',
    'yearly_subscription',
    'kavaid_premium_1year',
    'kavaid_annual_subscription',
    'kavaid_subscription_yearly',
  ];

  List<StoreProduct> _fallbackProducts = [];
  bool _isFetchingProducts = false;
  bool _hasFetchedProducts = false;

  bool get isFetchingProducts => _isFetchingProducts;
  bool get hasFetchedProducts => _hasFetchedProducts;
  List<StoreProduct> get fallbackProducts => _fallbackProducts;

  Future<void> fetchProducts() async {
    if (!_isInitialized) {
      await initialize(fetchOfferings: false);
    }
    await _ensureRevenueCatReady();
    if (!_isRevenueCatConfigured) return;
    if (_offeringsFuture != null) return _offeringsFuture;

    _offeringsFuture = _fetchProductsInternal().whenComplete(() {
      _offeringsFuture = null;
    });
    return _offeringsFuture;
  }

  Future<void> _fetchProductsInternal() async {
    _isFetchingProducts = true;
    try {
      _offerings = await Purchases.getOfferings().timeout(
        const Duration(seconds: 8),
      );
      debugPrint(
        '[RevenueCat] Offerings loaded: ${_offerings?.current?.availablePackages.length ?? 0}',
      );
    } catch (e) {
      debugPrint('[RevenueCat] Offerings error: $e');
    }

    // Fallback: Paketler offering içinde bulunamazsa StoreKit'ten doğrudan çekmeyi dene
    if (_offerings?.current == null || (_offerings?.current?.availablePackages.isEmpty ?? true)) {
      try {
        final allIds = [...monthlyProductIds, ...yearlyProductIds];
        _fallbackProducts = await Purchases.getProducts(allIds).timeout(
          const Duration(seconds: 8),
        );
        debugPrint('[RevenueCat] Fallback products loaded: ${_fallbackProducts.length}');
      } catch (e) {
        debugPrint('[RevenueCat] Fallback products error: $e');
      }
    }

    _hasFetchedProducts = true;
    _isFetchingProducts = false;
    notifyListeners();
  }

  String getPrice(String packageId) {
    // 1. Current Offering'den kontrol et
    if (_offerings != null && _offerings!.current != null) {
      try {
        if (packageId == 'monthly' && _offerings!.current!.monthly != null) {
          return _offerings!.current!.monthly!.storeProduct.priceString;
        } else if (packageId == 'yearly' && _offerings!.current!.annual != null) {
          return _offerings!.current!.annual!.storeProduct.priceString;
        } else {
          final package = _offerings!.current!.availablePackages.firstWhere(
            (p) {
              final id = p.identifier.toLowerCase();
              final storeId = p.storeProduct.identifier.toLowerCase();
              return id.contains(packageId.toLowerCase()) || storeId.contains(packageId.toLowerCase());
            },
          );
          return package.storeProduct.priceString;
        }
      } catch (_) {}
    }

    // 2. Diğer Offering'lerden kontrol et
    if (_offerings != null) {
      for (final offering in _offerings!.all.values) {
        try {
          final package = offering.availablePackages.firstWhere((p) {
            final id = p.identifier.toLowerCase();
            final storeId = p.storeProduct.identifier.toLowerCase();
            if (packageId == 'monthly') {
              return id.contains('monthly') || storeId.contains('monthly');
            } else {
              return id.contains('yearly') || id.contains('annual') || storeId.contains('yearly') || storeId.contains('annual');
            }
          });
          return package.storeProduct.priceString;
        } catch (_) {}
      }
    }

    // 3. Fallback doğrudan StoreKit ürünlerinden kontrol et
    if (_fallbackProducts.isNotEmpty) {
      final targetIds = packageId == 'monthly' ? monthlyProductIds : yearlyProductIds;
      for (final p in _fallbackProducts) {
        if (targetIds.contains(p.identifier) || p.identifier.toLowerCase().contains(packageId.toLowerCase())) {
          return p.priceString;
        }
      }
    }

    return '';
  }

  String getMonthlyCostForYearly() {
    try {
      StoreProduct? annualProduct = _offerings?.current?.annual?.storeProduct;
      if (annualProduct == null && _fallbackProducts.isNotEmpty) {
        for (final p in _fallbackProducts) {
          if (yearlyProductIds.contains(p.identifier) ||
              p.identifier.toLowerCase().contains('yearly') ||
              p.identifier.toLowerCase().contains('annual')) {
            annualProduct = p;
            break;
          }
        }
      }
      if (annualProduct != null) {
        final price = annualProduct.price;
        final monthlyCost = price / 12;
        final currencyCode = annualProduct.currencyCode;
        if (annualProduct.priceString.contains('₺') || currencyCode == 'TRY') {
          return '${monthlyCost.toStringAsFixed(0)}₺/ay';
        } else if (annualProduct.priceString.contains('\$') || currencyCode == 'USD') {
          return '\$${monthlyCost.toStringAsFixed(2)}/mo';
        } else if (annualProduct.priceString.contains('€') || currencyCode == 'EUR') {
          return '${monthlyCost.toStringAsFixed(2)}€/mo';
        }
        return '${monthlyCost.toStringAsFixed(0)} /ay';
      }
    } catch (_) {}
    return '';
  }

  Future<void> buyPackage(Package package) async {
    await initialize(fetchOfferings: false);
    try {
      _lastError = '';
      final customerInfo = (await Purchases.purchase(PurchaseParams.package(package))).customerInfo;
      await _updateCustomerStatus(customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        _lastError = 'Satın alma hatası: ${e.message ?? e.toString()}';
        debugPrint('[RevenueCat] Purchase error: $e');
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'Beklenmedik hata: $e';
      notifyListeners();
    }
  }

  Future<void> buyStoreProduct(StoreProduct product) async {
    await initialize(fetchOfferings: false);
    try {
      _lastError = '';
      final customerInfo = (await Purchases.purchase(PurchaseParams.storeProduct(product))).customerInfo;
      await _updateCustomerStatus(customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        _lastError = 'Satın alma hatası: ${e.message ?? e.toString()}';
        debugPrint('[RevenueCat] Purchase product error: $e');
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'Beklenmedik hata: $e';
      notifyListeners();
    }
  }

  Future<void> buyPremiumMonthly() async {
    await fetchProducts();
    Package? package = _offerings?.current?.monthly;

    if (package == null && _offerings?.current != null) {
      try {
        package = _offerings!.current!.availablePackages.firstWhere((p) {
          final id = p.identifier.toLowerCase();
          final storeId = p.storeProduct.identifier.toLowerCase();
          return id.contains('monthly') || storeId.contains('monthly') || monthlyProductIds.contains(p.storeProduct.identifier);
        });
      } catch (_) {}
    }

    if (package == null && _offerings != null) {
      for (final offering in _offerings!.all.values) {
        try {
          final found = offering.availablePackages.firstWhere((p) {
            final id = p.identifier.toLowerCase();
            final storeId = p.storeProduct.identifier.toLowerCase();
            return id.contains('monthly') || storeId.contains('monthly') || monthlyProductIds.contains(p.storeProduct.identifier);
          });
          package = found;
          break;
        } catch (_) {}
      }
    }

    if (package != null) {
      await buyPackage(package);
      return;
    }

    // Direct StoreProduct fallback
    StoreProduct? fallbackProduct;
    for (final p in _fallbackProducts) {
      if (monthlyProductIds.contains(p.identifier) || p.identifier.toLowerCase().contains('monthly')) {
        fallbackProduct = p;
        break;
      }
    }

    if (fallbackProduct != null) {
      await buyStoreProduct(fallbackProduct);
      return;
    }

    _lastError = 'Abonelik paketi yüklenemedi. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
    notifyListeners();
  }

  Future<void> buyPremiumYearly() async {
    await fetchProducts();
    Package? package = _offerings?.current?.annual;

    if (package == null && _offerings?.current != null) {
      try {
        package = _offerings!.current!.availablePackages.firstWhere((p) {
          final id = p.identifier.toLowerCase();
          final storeId = p.storeProduct.identifier.toLowerCase();
          return id.contains('yearly') || id.contains('annual') || storeId.contains('yearly') || storeId.contains('annual') || yearlyProductIds.contains(p.storeProduct.identifier);
        });
      } catch (_) {}
    }

    if (package == null && _offerings != null) {
      for (final offering in _offerings!.all.values) {
        try {
          final found = offering.availablePackages.firstWhere((p) {
            final id = p.identifier.toLowerCase();
            final storeId = p.storeProduct.identifier.toLowerCase();
            return id.contains('yearly') || id.contains('annual') || storeId.contains('yearly') || storeId.contains('annual') || yearlyProductIds.contains(p.storeProduct.identifier);
          });
          package = found;
          break;
        } catch (_) {}
      }
    }

    if (package != null) {
      await buyPackage(package);
      return;
    }

    // Direct StoreProduct fallback
    StoreProduct? fallbackProduct;
    for (final p in _fallbackProducts) {
      if (yearlyProductIds.contains(p.identifier) || p.identifier.toLowerCase().contains('yearly') || p.identifier.toLowerCase().contains('annual')) {
        fallbackProduct = p;
        break;
      }
    }

    if (fallbackProduct != null) {
      await buyStoreProduct(fallbackProduct);
      return;
    }

    _lastError = 'Abonelik paketi yüklenemedi. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
    notifyListeners();
  }

  Future<void> restorePurchases() async {
    await refreshEntitlements(includePromo: true);
    if (!_isRevenueCatConfigured) {
      _lastError = 'Satın alma kontrolü için internet bağlantısı gerekiyor.';
      notifyListeners();
      return;
    }
    try {
      _lastError = '';
      debugPrint('[RevenueCat] Restore...');
      final customerInfo = await Purchases.restorePurchases();
      await _updateCustomerStatus(customerInfo);

      if (customerInfo.entitlements.active.isEmpty &&
          customerInfo.activeSubscriptions.isEmpty &&
          !isPremium &&
          !_isLifetimeNoAds &&
          _purchasedBooks.isEmpty) {
        _lastError = 'Aktif bir abonelik bulunamadi.';
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'Restore hatasi: $e';
      notifyListeners();
    }
  }

  Future<void> loadUserPurchases() async {
    await refreshEntitlements(includePromo: true);
  }

  Future<void> checkPromoPremium() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      resetPromoState();
      return;
    }

    try {
      final promoService = PromoCodeService();
      final isPromo = await promoService.isPromoPremiumActive();
      final hasUsed = await promoService.hasUsedAnyPromoCode();
      final expiry = await promoService.getPromoExpiryDate();

      var changed = false;
      if (_isPromoPremium != isPromo) {
        _isPromoPremium = isPromo;
        changed = true;
      }
      if (_hasUsedPromo != hasUsed) {
        _hasUsedPromo = hasUsed;
        changed = true;
      }
      if (_promoExpiryDate != expiry) {
        _promoExpiryDate = expiry;
        changed = true;
      }

      if (_isPromoPremium) {
        _startPromoExpiryTimer();
      } else {
        _promoExpiryTimer?.cancel();
      }

      await _saveEntitlementSnapshot(source: 'promo');

      if (changed) notifyListeners();
    } catch (e) {
      debugPrint('[PurchaseManager] Promo check error: $e');
    }
  }

  void _startPromoExpiryTimer() {
    _promoExpiryTimer?.cancel();
    _promoExpiryTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final expiry = _promoExpiryDate;
      if (expiry != null && DateTime.now().toUtc().isAfter(expiry.toUtc())) {
        _isPromoPremium = false;
        _promoExpiryTimer?.cancel();
        _promoExpiryDate = null;
        await _saveEntitlementSnapshot(source: 'promo_expired');
        unawaited(_saveLocalCache());
        notifyListeners();
        debugPrint('[PurchaseManager] Promo süresi doldu, premium düşürüldü');
      }
    });
    // Abonelik bitişi de aynı periyotta kontrol edilsin.
    _startSubscriptionExpiryTimer();
  }

  Timer? _subscriptionExpiryTimer;

  /// Uygulama açıkken abonelik biterse premium'u düşür.
  /// RevenueCat listener her zaman tetiklenmeyebilir, bu timer garantiler.
  void _startSubscriptionExpiryTimer() {
    _subscriptionExpiryTimer?.cancel();
    final expiry = _subscriptionExpiryDate;
    if (expiry == null) return; // lifetime / tarihsiz -> timer yok
    if (DateTime.now().toUtc().isBefore(expiry.toUtc())) {
      final remaining = expiry.toUtc().difference(DateTime.now().toUtc());
      // En geç 5 dakikada bir kontrol et, bitiş anında da tetikle.
      final firstCheck = remaining < const Duration(minutes: 5)
          ? remaining + const Duration(seconds: 5)
          : const Duration(minutes: 5);
      _subscriptionExpiryTimer = Timer(firstCheck, () async {
        if (_isSubscriptionExpired && _isPremium) {
          debugPrint('[PurchaseManager] Abonelik süresi doldu, premium düşürülüyor');
          _isPremium = false;
          await _saveEntitlementSnapshot(source: 'subscription_expired');
          unawaited(_saveLocalCache());
          // Firestore'daki şişmiş isPremium:true'yu da temizle
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({
                'isPremium': false,
                'premiumSource': 'local_expiry',
                'lastVerifiedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            } catch (_) {}
          }
          notifyListeners();
        }
        // Hala premium varsa (lifetime'a dönmüş olabilir) tekrar kur.
        if (_isPremium && !_isSubscriptionExpired) {
          _startSubscriptionExpiryTimer();
        }
      });
    } else if (_isPremium) {
      // Zaten dolmuş ama flag hala true: hemen düşür.
      _isPremium = false;
      unawaited(_saveEntitlementSnapshot(source: 'subscription_expired'));
      unawaited(_saveLocalCache());
      notifyListeners();
    }
  }

  void resetPromoState() {
    _promoExpiryTimer?.cancel();
    if (_isPromoPremium || _hasUsedPromo || _promoExpiryDate != null) {
      _isPromoPremium = false;
      _hasUsedPromo = false;
      _promoExpiryDate = null;
      notifyListeners();
    }
  }

  Future<void> _applyCachedEntitlementSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_entitlementCacheKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final user = FirebaseAuth.instance.currentUser;
      final hasInternet = await ConnectivityService().hasInternetConnection();

      // Eğer internet varsa ve giriş yapılmış bir kullanıcı varsa, UID eşleşmeli.
      // İnternet yoksa (çevrimdışıysak) veya Firebase Auth henüz yüklenirken son başarılı snapshot'ı kurtarırız.
      if (hasInternet && user != null && decoded['userId'] != user.uid) {
        return;
      }

      final expiresAt = _parseMillis(decoded['expiresAt']);
      final lastVerifiedAt = _parseMillis(decoded['lastVerifiedAt']);
      final cachedPremium = decoded['isPremium'] == true;
      final books = (decoded['purchasedBooks'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toSet();

      // DÜZELTME: abonelik ve promo bitişini AYRI oku.
      // Eskiden ikisi 'expiresAt' içinde max() olarak birleştiriliyordu;
      // lifetime premium + promo olan kullanıcıda promo bitince
      // uygulama yeniden açıldığında lifetime premium da düşüyordu.
      final subExpiry = _parseMillis(decoded['subscriptionExpiresAt']);
      final promoExpiry = _parseMillis(decoded['promoExpiresAt']);
      final isPromoCached = decoded['isPromoPremium'] == true;

      // Yeni format varsa ayrı değerleri kullan, yoksa eski 'expiresAt'.
      final hasSeparateExpiry =
          decoded.containsKey('subscriptionExpiresAt') ||
              decoded.containsKey('promoExpiresAt');

      final now = DateTime.now().toUtc();
      final subActive = !hasSeparateExpiry
          ? (expiresAt == null || expiresAt.isAfter(now))
          : (subExpiry == null || subExpiry.isAfter(now));
      final promoActive = hasSeparateExpiry &&
          isPromoCached &&
          promoExpiry != null &&
          promoExpiry.isAfter(now);

      final activePremium = cachedPremium && (subActive || promoActive);

      _isPremium = activePremium;
      _isLifetimeNoAds = decoded['isLifetimeNoAds'] == true;
      _purchasedBooks = books;
      _subscriptionExpiryDate = hasSeparateExpiry ? subExpiry : expiresAt;
      _promoExpiryDate = promoActive ? promoExpiry : null;
      _isPromoPremium = promoActive;
      _lastVerifiedAt = lastVerifiedAt;
      _entitlementSource = decoded['source']?.toString() ?? 'cache';
      _entitlementsResolved = true;
      _entitlementPending = false;
      _usingOfflineSnapshot = true;
      if (promoActive) _startPromoExpiryTimer();
      _startSubscriptionExpiryTimer();
      notifyListeners();
      debugPrint(
        '[PurchaseManager] Snapshot yüklendi: premium=$activePremium, sub=$_subscriptionExpiryDate, promo=$promoActive',
      );
    } catch (e) {
      debugPrint('[PurchaseManager] Cache read error: $e');
    }
  }

  Future<void> _saveEntitlementSnapshot({required String source}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now().toUtc();
    _lastVerifiedAt = now;
    final expiresAt = subscriptionExpiryDate;

    final snapshot = <String, dynamic>{
      'userId': user.uid,
      'isPremium': isPremium,
      'isLifetimeNoAds': _isLifetimeNoAds,
      'purchasedBooks': _purchasedBooks.toList()..sort(),
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      // DÜZELTME: abonelik ve promo bitişini ayrı yaz. max() birleşimi
      // lifetime + promo senaryosunda lifetime'ı promo bitişine bağlıyordu.
      'subscriptionExpiresAt': _subscriptionExpiryDate?.millisecondsSinceEpoch,
      'promoExpiresAt': _promoExpiryDate?.millisecondsSinceEpoch,
      'isPromoPremium': _isPromoPremium,
      'lastVerifiedAt': now.millisecondsSinceEpoch,
      'source': source,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_entitlementCacheKey, jsonEncode(snapshot));
    } catch (e) {
      debugPrint('[PurchaseManager] Cache write error: $e');
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  DateTime? _parseMillis(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    if (value is String) {
      final millis = int.tryParse(value);
      if (millis != null) {
        return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
      }
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  Future<void> mockSetPremium() async {
    if (kDebugMode) {
      _isPremium = true;
      _entitlementPending = false;
      _entitlementsResolved = true;
      notifyListeners();
      unawaited(_saveLocalCache());
    }
  }

  Future<void> mockResetPremium() async {
    if (kDebugMode) {
      _isPremium = false;
      _isLifetimeNoAds = false;
      _isPromoPremium = false;
      _purchasedBooks.clear();
      _entitlementPending = false;
      _entitlementsResolved = true;
      notifyListeners();
      unawaited(_saveLocalCache());
    }
  }

  Future<void> _loadLocalCache() {
    _loadCacheFuture ??= _loadLocalCacheInternal();
    return _loadCacheFuture!;
  }

  Future<void> _loadLocalCacheInternal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      // UID eşleşmesi — eğer farklı kullanıcının cache'i varsa kullanma
      final cachedUid = prefs.getString('purchase_cached_user_id');
      if (cachedUid != null && currentUid != null && cachedUid != currentUid) {
        debugPrint('[PurchaseManager] Cache UID eşleşmedi ($cachedUid != $currentUid), atlanıyor.');
        return;
      }

      final isPremium = prefs.getBool('purchase_cached_is_premium') ?? false;
      final expiresAtMillis = prefs.getInt('purchase_cached_premium_expires_at');
      final isLifetimeNoAds = prefs.getBool('purchase_cached_is_lifetime_no_ads') ?? false;
      final booksList = prefs.getStringList('purchase_cached_purchased_books') ?? [];

      DateTime? expiresAt;
      if (expiresAtMillis != null) {
        expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMillis, isUtc: true);
      }

      // Abonelik süresi dolmuş mu kontrol et.
      // DÜZELTME: lifetime NoAds, premium aboneliği uzatmaz.
      // NoAds sadece reklamları kapatır, premium içerik için expiry şarttır.
      // expiresAt == null => lifetime premium (tarihsiz), korunur.
      final isExpired =
          expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc());
      final activePremium = isPremium && !isExpired;

      _isPremium = activePremium;
      _isLifetimeNoAds = isLifetimeNoAds;
      _purchasedBooks = booksList.toSet();
      _subscriptionExpiryDate = expiresAt;

      // Bir şey yüklendiyse kullanıcıyı hemen premium göster
      if (_isPremium || _isLifetimeNoAds || _purchasedBooks.isNotEmpty) {
        _entitlementsResolved = true;
        _entitlementPending = false;
        _usingOfflineSnapshot = true;
        notifyListeners();
      }

      debugPrint('[PurchaseManager] Hızlı önbellek yüklendi: premium=$activePremium, noAds=$isLifetimeNoAds, books=${booksList.length}, uid=$cachedUid');
    } catch (e) {
      debugPrint('[PurchaseManager] Hızlı önbellek okuma hatası: $e');
    }
  }

  Future<void> _saveLocalCache() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      // Kullanıcı yoksa kaydetme (çıkış yapmış kullanıcının premium'u silinmesin)
      // İstisna: lifetime veya books varsa kullanıcısız da sakla
      if (currentUid == null && !_isLifetimeNoAds && _purchasedBooks.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      if (currentUid != null) {
        await prefs.setString('purchase_cached_user_id', currentUid);
      }
      await prefs.setBool('purchase_cached_is_premium', _isPremium);
      if (_subscriptionExpiryDate != null) {
        await prefs.setInt(
          'purchase_cached_premium_expires_at',
          _subscriptionExpiryDate!.millisecondsSinceEpoch,
        );
      } else {
        await prefs.remove('purchase_cached_premium_expires_at');
      }
      await prefs.setBool('purchase_cached_is_lifetime_no_ads', _isLifetimeNoAds);
      await prefs.setStringList(
        'purchase_cached_purchased_books',
        _purchasedBooks.toList(),
      );
      debugPrint('[PurchaseManager] Hızlı önbellek kaydedildi: premium=$_isPremium, noAds=$_isLifetimeNoAds, uid=$currentUid, expires=$_subscriptionExpiryDate');
    } catch (e) {
      debugPrint('[PurchaseManager] Hızlı önbellek kaydetme hatası: $e');
    }
  }
}
