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

const _apiKeyAndroid = 'goog_JUkLUxlscZqowPzLzmvYPKddTbE';
const _apiKeyIOS = 'appl_JUkLUxlscZqowPzLzmvYPKddTbE';

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

  bool get shouldShowAds =>
      !_entitlementPending &&
      !_isPremium &&
      !_isLifetimeNoAds &&
      !_isPromoPremium;

  bool get isPremium => _isPremium || _isPromoPremium;
  bool get isPromoPremium => _isPromoPremium;
  bool get hasUsedPromo => _hasUsedPromo;
  bool get isLifetimeNoAds => _isLifetimeNoAds;
  bool get isAvailable => _isInitialized;
  String get lastError => _lastError;
  Set<String> get purchasedBooks => _purchasedBooks;
  DateTime? get subscriptionExpiryDate =>
      _latestDate(_subscriptionExpiryDate, _promoExpiryDate);
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

    // Null user çevrimiçide: gerçek çıkış yaptı, entitlements temizle
    if (uid == null) {
      if (!forceRefresh &&
          _lastAuthUserId == null &&
          _entitlementsResolved) {
        return; // Zaten temizlenmiş
      }
      _lastAuthUserId = null;
      _clearRuntimeEntitlements();
      if (logOutOnNull &&
          _isRevenueCatConfigured &&
          !(await Purchases.isAnonymous)) {
        await Purchases.logOut();
      }
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
    } else if (checkedLegacy && _entitlementPending) {
      _applyVerifiedEntitlements(
        isPremium: _isPremium,
        isLifetimeNoAds: _isLifetimeNoAds,
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
        _firstActiveEntitlement(entitlements, const ['premium', 'pro']);
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

    final expiry = _parseDate(
      premiumEntitlement?.expirationDate ?? customerInfo.latestExpirationDate,
    );

    var legacyFailed = false;
    if (!_legacyChecked) {
      try {
        await _checkLegacyPermissions(
          onLegacyFound: (legacyPremium, legacyAdsFree) {
            _cachedLegacyPremium = legacyPremium;
            _cachedLegacyAdsFree = legacyAdsFree;
            if (legacyPremium) newPremiumStatus = true;
            if (!newAdsFreeStatus && legacyAdsFree) newAdsFreeStatus = true;
          },
        );
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

    // KORUMA: Legacy kontrol HATA verdİ VE sonuç premium düşürülecekse → iptal
    // Çünkü veri eksik — Firestore'a ulaşılamadı.
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
    final changed =
        _isPremium != isPremium ||
        _isLifetimeNoAds != isLifetimeNoAds ||
        !_setEquals(_purchasedBooks, purchasedBooks) ||
        _subscriptionExpiryDate != expiresAt ||
        _entitlementPending ||
        !_entitlementsResolved ||
        _usingOfflineSnapshot;

    _isPremium = isPremium;
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
        '[PurchaseManager] Entitlements updated -> premium: $isPremium, adsFree: $isLifetimeNoAds, books: ${_purchasedBooks.length}',
      );
    }
    unawaited(_saveLocalCache());
  }

  static const List<String> _legacyAdsIds = [
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

  bool get hasActiveBooks {
    if (_purchasedBooks.isEmpty) return false;
    return _purchasedBooks.any(
      (id) => !_legacyAdsIds.contains(id.toLowerCase()),
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
      var legacyPremium = false;
      var legacyAdsFree = false;
      DateTime? legacyPremiumExpiry;
      final books = <String>{};
      final legacyDocs = <Map<String, dynamic>>[];
      final docIds = <String>[
        user.uid,
        if ((user.email ?? '').isNotEmpty && user.email != user.uid)
          user.email!,
      ];

      bool checkBoolField(Map<String, dynamic> data, String field) {
        final val = data[field];
        if (val == true) return true;
        if (val is String && val.toLowerCase() == 'true') return true;
        if (val is int && val == 1) return true;
        return false;
      }

      bool isActiveFlag(Object? value) {
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

      bool checkActiveStringField(Map<String, dynamic> data, String field) {
        return isActiveFlag(data[field]);
      }

      DateTime? firstDateField(Map<String, dynamic> data, List<String> fields) {
        for (final field in fields) {
          final parsed = _parseFlexibleDate(data[field]);
          if (parsed != null) return parsed;
        }
        return null;
      }

      bool activeNestedEntitlement(Map<String, dynamic> data, String field) {
        final value = data[field];
        if (value is! Map) return false;
        final nested = Map<String, dynamic>.from(value);
        final nestedExpiry = firstDateField(nested, const [
          'expiresAt',
          'expirationDate',
          'expiry',
          'expires',
          'until',
          'premiumUntil',
          'premiumExpiry',
          'subscriptionExpiry',
        ]);
        final hasActiveMarker =
            isActiveFlag(nested['active']) ||
            isActiveFlag(nested['isActive']) ||
            isActiveFlag(nested['enabled']) ||
            isActiveFlag(nested['status']) ||
            isActiveFlag(nested['state']);
        return hasActiveMarker &&
            (nestedExpiry == null ||
                nestedExpiry.isAfter(DateTime.now().toUtc()));
      }

      bool activeNamedNestedEntitlement(
        Map<String, dynamic> data,
        String containerField,
        List<String> entitlementKeys,
      ) {
        final container = data[containerField];
        if (container is! Map) return false;
        for (final key in entitlementKeys) {
          final value = container[key];
          if (value is Map) {
            final nested = {key: Map<String, dynamic>.from(value)};
            if (activeNestedEntitlement(nested, key)) return true;
          } else if (isActiveFlag(value)) {
            return true;
          }
        }
        return false;
      }

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

      for (final data in legacyDocs) {
        final hasLifetimePremium =
            checkBoolField(data, 'lifetimePremium') ||
            checkBoolField(data, 'isLifetimePremium') ||
            checkBoolField(data, 'premiumForever') ||
            checkBoolField(data, 'permanentPremium') ||
            checkBoolField(data, 'lifetimeAdsFree');

        final hasPremiumFlag =
            checkBoolField(data, 'isPremium') ||
            checkBoolField(data, 'is_premium') ||
            checkBoolField(data, 'premium') ||
            checkBoolField(data, 'premiumActive') ||
            checkBoolField(data, 'isPremiumActive') ||
            checkBoolField(data, 'hasPremium') ||
            checkBoolField(data, 'premiumMember') ||
            checkBoolField(data, 'subscriptionActive') ||
            checkBoolField(data, 'isSubscribed') ||
            checkBoolField(data, 'subscribed') ||
            checkActiveStringField(data, 'premiumStatus') ||
            checkActiveStringField(data, 'subscriptionStatus') ||
            activeNestedEntitlement(data, 'premium') ||
            activeNestedEntitlement(data, 'subscription') ||
            activeNestedEntitlement(data, 'entitlement') ||
            activeNestedEntitlement(data, 'entitlements') ||
            activeNamedNestedEntitlement(data, 'entitlements', const [
              'premium',
              'pro',
              'subscription',
              'kavaid_premium',
            ]) ||
            activeNamedNestedEntitlement(data, 'purchases', const [
              'premium',
              'pro',
              'subscription',
              'kavaid_premium',
            ]);

        final premiumExpiry = firstDateField(data, const [
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
        ]);

        if (hasLifetimePremium) {
          legacyPremium = true;
          legacyPremiumExpiry = null;
        } else if (hasPremiumFlag &&
            (premiumExpiry == null || premiumExpiry.isAfter(now))) {
          legacyPremium = true;
          legacyPremiumExpiry = _latestDate(legacyPremiumExpiry, premiumExpiry);
        } else if (!hasPremiumFlag &&
            premiumExpiry != null &&
            premiumExpiry.isAfter(now)) {
          legacyPremium = true;
          legacyPremiumExpiry = _latestDate(legacyPremiumExpiry, premiumExpiry);
        }

        if (checkBoolField(data, 'lifetimeAdsFree') ||
            checkBoolField(data, 'isAdsRemoved') ||
            checkBoolField(data, 'adsRemoved') ||
            checkBoolField(data, 'ads_removed') ||
            checkBoolField(data, 'removeAds') ||
            checkBoolField(data, 'is_ads_removed')) {
          legacyAdsFree = true;
        }

        if (data['purchasedBooks'] is List) {
          final docBooks = data['purchasedBooks'] as List<dynamic>;
          books.addAll(docBooks.map((e) => e.toString()));

          if (docBooks.any(
            (bookId) => _legacyAdsIds.contains(bookId.toString().toLowerCase()),
          )) {
            legacyAdsFree = true;
          }
        }
      }

      if (books.isNotEmpty) {
        _purchasedBooks = books;
      }

      if (legacyPremium) {
        _subscriptionExpiryDate = legacyPremiumExpiry;
      }

      onLegacyFound(legacyPremium, legacyAdsFree);
    } catch (e) {
      debugPrint('[PurchaseManager] Legacy check error: $e');
      onLegacyFound(false, false);
    }
  }

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
    try {
      _offerings = await Purchases.getOfferings().timeout(
        const Duration(seconds: 8),
      );
      debugPrint(
        '[RevenueCat] Offerings loaded: ${_offerings?.current?.availablePackages.length ?? 0}',
      );
      notifyListeners();
    } catch (e) {
      _lastError = 'Urunler yuklenemedi: $e';
      debugPrint('[RevenueCat] Offerings error: $e');
      notifyListeners();
    }
  }

  String getPrice(String packageId) {
    if (_offerings == null || _offerings!.current == null) return '';

    try {
      var priceStr = '';
      if (packageId == 'monthly' && _offerings!.current!.monthly != null) {
        priceStr = _offerings!.current!.monthly!.storeProduct.priceString;
      } else if (packageId == 'yearly' && _offerings!.current!.annual != null) {
        priceStr = _offerings!.current!.annual!.storeProduct.priceString;
      } else {
        final package = _offerings!.current!.availablePackages.firstWhere(
          (p) => p.identifier.toLowerCase().contains(packageId.toLowerCase()),
        );
        priceStr = package.storeProduct.priceString;
      }
      final cleanPrice = priceStr
          .replaceAll('TRY', '')
          .replaceAll('₺', '')
          .trim();
      return '$cleanPrice₺';
    } catch (_) {
      return '';
    }
  }

  String getMonthlyCostForYearly() {
    try {
      final annualPackage = _offerings?.current?.annual;
      if (annualPackage != null) {
        final price = annualPackage.storeProduct.price;
        final monthlyCost = price / 12;
        return '${monthlyCost.toStringAsFixed(0)}₺ /ay';
      }
    } catch (_) {}
    return '';
  }

  Future<void> buyPackage(Package package) async {
    await initialize(fetchOfferings: false);
    try {
      _lastError = '';
      final customerInfo = await Purchases.purchasePackage(package);
      await _updateCustomerStatus(customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        _lastError = 'Satin alma hatasi: ${e.message}';
        debugPrint('[RevenueCat] Purchase error: $e');
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'Beklenmedik hata: $e';
      notifyListeners();
    }
  }

  Future<void> buyPremiumMonthly() async {
    await fetchProducts();
    var package = _offerings?.current?.monthly;

    if (package == null && _offerings?.current != null) {
      try {
        package = _offerings!.current!.availablePackages.firstWhere(
          (p) => p.identifier.toLowerCase().contains('monthly'),
        );
      } catch (_) {}
    }

    if (package != null) {
      await buyPackage(package);
    } else {
      _lastError = 'Aylik paket bulunamadi.';
      notifyListeners();
    }
  }

  Future<void> buyPremiumYearly() async {
    await fetchProducts();
    var package = _offerings?.current?.annual;

    if (package == null && _offerings?.current != null) {
      try {
        package = _offerings!.current!.availablePackages.firstWhere((p) {
          final id = p.identifier.toLowerCase();
          return id.contains('yearly') || id.contains('annual');
        });
      } catch (_) {}
    }

    if (package != null) {
      await buyPackage(package);
    } else {
      _lastError = 'Yillik paket bulunamadi.';
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    await refreshEntitlements(includePromo: true);
    if (!_isRevenueCatConfigured) {
      _lastError = 'Satin alma kontrolu icin internet baglantisi gerekiyor.';
      notifyListeners();
      return;
    }
    try {
      _lastError = '';
      debugPrint('[RevenueCat] Restore...');
      final customerInfo = await Purchases.restorePurchases();
      await _updateCustomerStatus(customerInfo);

      if (customerInfo.entitlements.active.isEmpty &&
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
    _promoExpiryTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      final expiry = _promoExpiryDate;
      if (expiry != null && DateTime.now().toUtc().isAfter(expiry.toUtc())) {
        _isPromoPremium = false;
        _promoExpiryTimer?.cancel();
        await _saveEntitlementSnapshot(source: 'promo_expired');
        notifyListeners();
      }
    });
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
      final activePremium =
          cachedPremium &&
          (expiresAt == null || expiresAt.isAfter(DateTime.now().toUtc()));
      final books = (decoded['purchasedBooks'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toSet();

      _isPremium = activePremium;
      _isLifetimeNoAds = decoded['isLifetimeNoAds'] == true;
      _purchasedBooks = books;
      _subscriptionExpiryDate = expiresAt;
      _lastVerifiedAt = lastVerifiedAt;
      _entitlementSource = decoded['source']?.toString() ?? 'cache';
      _entitlementsResolved = true;
      _entitlementPending = false;
      _usingOfflineSnapshot = true;
      notifyListeners();
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

  DateTime? _parseFlexibleDate(Object? value) {
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

  DateTime? _latestDate(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isAfter(second) ? first : second;
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

      // Abonelik süresi dolmuş mu kontrol et (lifetime ise sona ermez)
      final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now().toUtc());
      // Lifetime NoAds veya books varsa süre dolsa da geçerli
      final activePremium = isPremium && (!isExpired || isLifetimeNoAds);

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
