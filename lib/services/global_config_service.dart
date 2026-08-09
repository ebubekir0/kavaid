import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class GlobalConfigService extends ChangeNotifier {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final DatabaseReference _configRef = _database.ref().child('config');
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Singleton instance
  static final GlobalConfigService _instance = GlobalConfigService._internal();
  factory GlobalConfigService() => _instance;
  GlobalConfigService._internal();

  // Değişkenin ilk değeri kDebugMode'a göre ayarlanır.
  int _aiBatchSyncThreshold = kDebugMode ? 2 : 10;
  bool _subscriptionDisabled = false;
  bool _campaignEnabled = false; // Kampanya açık mı?
  bool _isInitialized = false;

  // Getter'lar
  int get aiBatchSyncThreshold => _aiBatchSyncThreshold;
  bool get subscriptionDisabled => _subscriptionDisabled;
  bool get campaignEnabled => _campaignEnabled;
  bool get isInitialized => _isInitialized;
  
  // Ana başlatma metodu
  Future<void> init() async {
    if (_isInitialized) return;
    
    // İki başlatma işlemini aynı anda yap
    await Future.wait([
      _initializeRemoteConfig(), // Remote Config'i başlat
      _loadInitialRealtimeValues(), // Realtime DB'den ilk değerleri yükle
    ]);

    _initializeRealtimeListener(); // Realtime DB dinleyicisini başlat

    _isInitialized = true;
    notifyListeners();
  }
  
  // 1. Remote Config'i başlat ve değeri çek
  Future<void> _initializeRemoteConfig() async {
    debugPrint('⚙️ [RemoteConfig] Başlatılıyor...');
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      // Varsayılan değerler de kDebugMode'a göre ayarlanır.
      await _remoteConfig.setDefaults(const {
        'ai_batch_sync_threshold': kDebugMode ? 2 : 10,
      });
      await _remoteConfig.fetchAndActivate();
      _aiBatchSyncThreshold = _remoteConfig.getInt('ai_batch_sync_threshold');
      debugPrint('✅ [RemoteConfig] ai_batch_sync_threshold değeri çekildi: $_aiBatchSyncThreshold');

      // Değişiklikleri dinle
      _remoteConfig.onConfigUpdated.listen((event) async {
        await _remoteConfig.fetchAndActivate();
        final newThreshold = _remoteConfig.getInt('ai_batch_sync_threshold');
        if (_aiBatchSyncThreshold != newThreshold) {
           debugPrint('🔄 [RemoteConfig] ai_batch_sync_threshold güncellendi: $newThreshold');
          _aiBatchSyncThreshold = newThreshold;
          notifyListeners();
        }
      });

    } catch (e) {
      debugPrint('❌ [RemoteConfig] Başlatma hatası: $e. Varsayılan değer ($_aiBatchSyncThreshold) kullanılacak.');
    }
  }

  // 2. Realtime Database dinleyicisini başlat (sadece subscription için)
  void _initializeRealtimeListener() {
    debugPrint('🌐 [GlobalConfig] Realtime DB listener başlatılıyor (subscription_disabled için)...');
    _configRef.child('subscription_disabled').onValue.listen((event) {
      final value = event.snapshot.value;
      bool newValue = false;
      
      if (value != null) {
        if (value is bool) {
          newValue = value;
        } else if (value is String) {
          newValue = value.toLowerCase() == 'true';
        }
      }
      
      if (_subscriptionDisabled != newValue) {
        debugPrint('🔄 [GlobalConfig] subscription_disabled değişti: $_subscriptionDisabled -> $newValue');
        _subscriptionDisabled = newValue;
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('❌ [GlobalConfig] Realtime DB dinleme hatası: $error');
    });

    // Kampanya durumu dinleyicisi
    _configRef.child('campaign_enabled').onValue.listen((event) {
      final value = event.snapshot.value;
      bool newValue = false;
      
      if (value != null) {
        if (value is bool) {
          newValue = value;
        } else if (value is String) {
          newValue = value.toLowerCase() == 'true';
        }
      }
      
      if (_campaignEnabled != newValue) {
        debugPrint('🔄 [GlobalConfig] campaign_enabled değişti: $_campaignEnabled -> $newValue');
        _campaignEnabled = newValue;
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('❌ [GlobalConfig] Campaign dinleme hatası: $error');
    });
  }
  
  // 3. Realtime Database'den ilk değeri yükle (sadece subscription için)
  Future<void> _loadInitialRealtimeValues() async {
    debugPrint('🌐 [GlobalConfig] Realtime DB ilk değerleri yükleniyor...');
    try {
      final subSnapshot = await _configRef.child('subscription_disabled').get();

      if (subSnapshot.exists && subSnapshot.value != null) {
        final value = subSnapshot.value;
        if (value is bool) {
          _subscriptionDisabled = value;
        } else if (value is String) {
          _subscriptionDisabled = value.toLowerCase() == 'true';
        }
      }
      debugPrint('✅ [GlobalConfig] İlk değer yüklendi: subscription_disabled = $_subscriptionDisabled');

      // Kampanya durumunu yükle
      final campSnapshot = await _configRef.child('campaign_enabled').get();
      if (campSnapshot.exists && campSnapshot.value != null) {
        final campValue = campSnapshot.value;
        if (campValue is bool) {
          _campaignEnabled = campValue;
        } else if (campValue is String) {
          _campaignEnabled = campValue.toLowerCase() == 'true';
        }
      }
      debugPrint('✅ [GlobalConfig] İlk değer yüklendi: campaign_enabled = $_campaignEnabled');
    } catch (e) {
      debugPrint('❌ [GlobalConfig] İlk Realtime DB değeri yükleme hatası: $e');
    }
  }

  // Subscription durumunu toggle et
  Future<bool> toggleSubscriptionStatus() async {
    try {
      final newValue = !_subscriptionDisabled;
      
      debugPrint('🔄 [GlobalConfig] Subscription durumu değiştiriliyor: $newValue');
      await _configRef.child('subscription_disabled').set(newValue);
      debugPrint('✅ [GlobalConfig] Firebase\'e yazıldı: subscription_disabled = $newValue');
      
      // Local değeri hemen güncelle (listener ile de gelecek ama anında yanıt için)
      _subscriptionDisabled = newValue;
      notifyListeners();
      
      return true;
      
    } catch (e) {
      debugPrint('❌ [GlobalConfig] Toggle hatası: $e');
      return false;
    }
  }

  // Kampanya durumunu toggle et
  Future<bool> toggleCampaignStatus() async {
    try {
      final newValue = !_campaignEnabled;
      
      debugPrint('🔄 [GlobalConfig] Kampanya durumu değiştiriliyor: $newValue');
      await _configRef.child('campaign_enabled').set(newValue);
      debugPrint('✅ [GlobalConfig] Firebase\'e yazıldı: campaign_enabled = $newValue');
      
      // Local değeri hemen güncelle
      _campaignEnabled = newValue;
      notifyListeners();
      
      return true;
      
    } catch (e) {
      debugPrint('❌ [GlobalConfig] Kampanya toggle hatası: $e');
      return false;
    }
  }
} 