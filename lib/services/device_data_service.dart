import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';

class DeviceDataService {
  static final DeviceDataService _instance = DeviceDataService._internal();
  factory DeviceDataService() => _instance;
  DeviceDataService._internal();

  static const String _deviceIdKey = 'device_id';
  String? _cachedDeviceId;

  /// Benzersiz cihaz ID'si al veya oluştur
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_deviceIdKey);

      if (deviceId == null) {
        // Yeni cihaz ID'si oluştur
        deviceId = await _generateDeviceId();
        await prefs.setString(_deviceIdKey, deviceId);
        debugPrint('🆔 Yeni cihaz ID oluşturuldu: $deviceId');
      }

      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      debugPrint('❌ Cihaz ID alma hatası: $e');
      // Fallback: Random ID oluştur
      final fallbackId = _generateRandomId();
      _cachedDeviceId = fallbackId;
      return fallbackId;
    }
  }

  /// Platform-specific cihaz ID'si oluştur
  Future<String> _generateDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Android ID ve model kombinasyonu
        deviceId = '${androidInfo.id}_${androidInfo.model}'.replaceAll(' ', '_');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // iOS identifier ve model kombinasyonu
        deviceId = '${iosInfo.identifierForVendor}_${iosInfo.model}'.replaceAll(' ', '_');
      } else {
        // Web veya diğer platformlar için
        deviceId = _generateRandomId();
      }

      // ID'yi kısalt ve güvenli hale getir
      deviceId = deviceId.toLowerCase();
      if (deviceId.length > 20) {
        deviceId = deviceId.substring(0, 20);
      }

      return deviceId;
    } catch (e) {
      debugPrint('❌ Platform-specific ID oluşturma hatası: $e');
      return _generateRandomId();
    }
  }

  /// Random ID oluştur (fallback)
  String _generateRandomId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Cihaz bilgilerini al
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      Map<String, dynamic> info = {};

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info = {
          'platform': 'Android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'version': iosInfo.systemVersion,
        };
      } else {
        info = {
          'platform': 'Unknown',
          'model': 'Unknown',
        };
      }

      return info;
    } catch (e) {
      debugPrint('❌ Cihaz bilgisi alma hatası: $e');
      return {
        'platform': 'Unknown',
        'model': 'Unknown',
        'error': e.toString(),
      };
    }
  }

  /// Kullanıcı adı oluştur (cihaz ID'sine dayalı)
  Future<String> generateUserName() async {
    final deviceId = await getDeviceId();
    final deviceInfo = await getDeviceInfo();
    
    // Cihaz modeline dayalı kullanıcı adı
    String model = deviceInfo['model']?.toString() ?? 'Device';
    model = model.replaceAll(' ', '').toLowerCase();
    
    // İlk 6 karakter + model kısaltması
    final idPart = deviceId.length >= 6 ? deviceId.substring(0, 6) : deviceId;
    final modelPart = model.length >= 3 ? model.substring(0, 3) : model;
    
    return 'User_${modelPart}_$idPart';
  }

  /// Cache'i temizle
  void clearCache() {
    _cachedDeviceId = null;
  }

  /// Firebase için cihaz verilerini al (mevcut sistemle uyumluluk)
  Future<Map<String, dynamic>> getDeviceData() async {
    try {
      final deviceId = await getDeviceId();
      final deviceInfo = await getDeviceInfo();
      
      return {
        'deviceId': deviceId,
        'platform': deviceInfo['platform'] ?? 'Unknown',
        'model': deviceInfo['model'] ?? 'Unknown',
        'brand': deviceInfo['brand'] ?? 'Unknown',
        'version': deviceInfo['version'] ?? 'Unknown',
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('❌ Device data alma hatası: $e');
      final deviceId = await getDeviceId();
      return {
        'deviceId': deviceId,
        'platform': 'Unknown',
        'model': 'Unknown',
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'error': e.toString(),
      };
    }
  }

  /// Firebase'e cihaz verilerini kaydet (mevcut sistemle uyumluluk)
  Future<bool> saveDeviceData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Her bir veriyi ayrı ayrı kaydet
      for (final entry in data.entries) {
        final key = 'device_data_${entry.key}';
        final value = entry.value;
        
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else {
          // Diğer türleri string olarak kaydet
          await prefs.setString(key, value.toString());
        }
      }
      
      // Son kaydetme zamanını güncelle
      await prefs.setInt('device_data_last_saved', DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('✅ Device data kaydedildi: ${data.keys.toList()}');
      return true;
    } catch (e) {
      debugPrint('❌ Device data kaydetme hatası: $e');
      return false;
    }
  }

  /// Kaydedilmiş cihaz verilerini al
  Future<Map<String, dynamic>> getSavedDeviceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> savedData = {};
      
      // Tüm device_data_ ile başlayan anahtarları al
      final keys = prefs.getKeys().where((key) => key.startsWith('device_data_'));
      
      for (final key in keys) {
        final cleanKey = key.replaceFirst('device_data_', '');
        final value = prefs.get(key);
        if (value != null) {
          savedData[cleanKey] = value;
        }
      }
      
      return savedData;
    } catch (e) {
      debugPrint('❌ Saved device data alma hatası: $e');
      return {};
    }
  }
}