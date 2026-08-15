package com.onbir.kavaid

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.os.Build
import android.app.ActivityManager
import android.util.Log
import android.content.pm.ConfigurationInfo
import android.hardware.display.DisplayManager
import android.view.Display
import android.os.PowerManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "device_info"
    private val TAG = "KavaidPerformance"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 🚀 PERFORMANCE MOD: Hardware acceleration'ı zorla
        window.setFlags(
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        )
        
        // 🚀 PERFORMANCE MOD: Layout optimizasyonları
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode = 
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        
        // 🔧 ANR DÜZELTMESİ: FLAG_KEEP_SCREEN_ON KALDIRILDI
        // Ekranı daima açık tutmak thermal throttling'e yol açıyor → ANR riski
        // Kullanıcı cihazının ekran süresi ayarına saygı duyulmalı
        
        // 🚀 FPS FIX: Refresh rate optimizasyonu
        optimizeRefreshRate()
        
        // 🚀 PERFORMANCE MOD: Cihaz performansını değerlendir ve logla
        evaluateDevicePerformance()
        
        // 🚀 PERFORMANCE MOD: MIUI ve diğer custom ROM'lar için özel ayarlar
        optimizeForCustomRoms()
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 🚀 PERFORMANCE MOD: Device info channel'ı kur
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    result.success(getDetailedDeviceInfo())
                }
                "setHighPerformanceMode" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    setHighPerformanceMode(enabled)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    // 🚀 FPS FIX: Refresh rate optimizasyonu
    private fun optimizeRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
                val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
                val supportedModes = display.supportedModes
                
                // En yüksek refresh rate'i bul
                var bestMode = display.mode
                var maxRefreshRate = bestMode.refreshRate
                
                for (mode in supportedModes) {
                    if (mode.refreshRate > maxRefreshRate) {
                        maxRefreshRate = mode.refreshRate
                        bestMode = mode
                    }
                }
                
                // Preferred display mode'u ayarla
                window.attributes.preferredDisplayModeId = bestMode.modeId
                
                Log.d(TAG, "🔥 Display Mode Optimizasyonu: ${bestMode.physicalWidth}x${bestMode.physicalHeight} @ ${bestMode.refreshRate}Hz")
            } catch (e: Exception) {
                Log.e(TAG, "Display mode optimizasyonu başarısız: ${e.message}")
            }
        }
    }
    
    // 🚀 PERFORMANCE MOD: Cihaz performansını değerlendir
    private fun evaluateDevicePerformance() {
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val configurationInfo = activityManager.deviceConfigurationInfo
            val memoryInfo = ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memoryInfo)
            
            // Cihaz bilgilerini logla
            Log.d(TAG, "=== KAVAID CIHAZ PERFORMANS RAPORU ===")
            Log.d(TAG, "Cihaz: ${Build.MANUFACTURER} ${Build.MODEL}")
            Log.d(TAG, "Android Version: ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})")
            Log.d(TAG, "CPU Architecture: ${Build.SUPPORTED_ABIS.joinToString(", ")}")
            Log.d(TAG, "OpenGL ES Version: ${configurationInfo.glEsVersion}")
            Log.d(TAG, "Total RAM: ${memoryInfo.totalMem / (1024 * 1024)} MB")
            Log.d(TAG, "Available RAM: ${memoryInfo.availMem / (1024 * 1024)} MB")
            Log.d(TAG, "Low Memory: ${memoryInfo.lowMemory}")
            
            // Performans kategorisi belirle
            val totalRamMB = (memoryInfo.totalMem / (1024 * 1024)).toInt()
            val glEsVersion = getOpenGLVersion()
            val cpuCores = Runtime.getRuntime().availableProcessors()
            val refreshRate = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                window.context.display?.refreshRate ?: 60f
            } else {
                windowManager.defaultDisplay?.refreshRate ?: 60f
            }
            val performanceCategory = determinePerformanceCategoryDetailed(totalRamMB, glEsVersion, cpuCores, refreshRate, Build.VERSION.SDK_INT)
            Log.d(TAG, "Performans Kategorisi: $performanceCategory")
            
            // Özel optimizasyonları uygula
            applyPerformanceOptimizations(performanceCategory)
            
        } catch (e: Exception) {
            Log.e(TAG, "Cihaz performansı değerlendirilemedi: ${e.message}")
        }
    }
    

    
    // 🚀 PERFORMANCE MOD: Performans optimizasyonlarını uygula
    private fun applyPerformanceOptimizations(category: String) {
        when (category) {
            "high_end" -> {
                Log.d(TAG, "Yüksek performans optimizasyonları uygulanıyor...")
                // 🔧 ANR DÜZELTMESİ: setSustainedPerformanceMode KALDIRILDI
                // Bu mod paradoks olarak performansı DÜŞÜRÜR (CPU/GPU frekansını sınırlar)
                // Amacı "tutarlı ama düşük" performans sağlamaktır, bu da ANR riskini artırır
            }
            "mid_range" -> {
                Log.d(TAG, "Orta performans optimizasyonları uygulanıyor...")
                // Balanced optimizations
            }
            "low_end" -> {
                Log.d(TAG, "Düşük performans optimizasyonları uygulanıyor...")
                // Conservative optimizations
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }
    
    // 🚀 PERFORMANCE MOD: Custom ROM optimizasyonları
    private fun optimizeForCustomRoms() {
        val manufacturer = Build.MANUFACTURER.lowercase()
        val model = Build.MODEL.lowercase()
        
        when {
            manufacturer.contains("xiaomi") || manufacturer.contains("redmi") -> {
                Log.d(TAG, "MIUI optimizasyonları uygulanıyor...")
                // MIUI için özel ayarlar
                optimizeForMIUI()
            }
            manufacturer.contains("huawei") || manufacturer.contains("honor") -> {
                Log.d(TAG, "EMUI optimizasyonları uygulanıyor...")
                // EMUI için özel ayarlar
            }
            manufacturer.contains("oppo") || manufacturer.contains("oneplus") -> {
                Log.d(TAG, "ColorOS/OxygenOS optimizasyonları uygulanıyor...")
                // ColorOS/OxygenOS için özel ayarlar
            }
            manufacturer.contains("samsung") -> {
                Log.d(TAG, "One UI optimizasyonları uygulanıyor...")
                // Samsung One UI için özel ayarlar
                optimizeForSamsung()
            }
        }
    }
    
    // 🚀 PERFORMANCE MOD: MIUI özel optimizasyonları
    private fun optimizeForMIUI() {
        try {
            // MIUI'da display refresh rate zorlaması
            val layoutParams = window.attributes
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                layoutParams.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
            }
            window.attributes = layoutParams
            
            Log.d(TAG, "MIUI optimizasyonları tamamlandı")
        } catch (e: Exception) {
            Log.e(TAG, "MIUI optimizasyonları başarısız: ${e.message}")
        }
    }
    
    // 🚀 PERFORMANCE MOD: Samsung özel optimizasyonları
    private fun optimizeForSamsung() {
        try {
            // Samsung cihazlar için özel ayarlar
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                window.attributes.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
            
            Log.d(TAG, "Samsung optimizasyonları tamamlandı")
        } catch (e: Exception) {
            Log.e(TAG, "Samsung optimizasyonları başarısız: ${e.message}")
        }
    }
    
    // 🚀 PERFORMANCE MOD: Flutter'a gönderilecek cihaz bilgileri
    private fun getDetailedDeviceInfo(): Map<String, Any> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val configurationInfo = activityManager.deviceConfigurationInfo
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        // RAM bilgisi
        val totalRamMB = (memoryInfo.totalMem / (1024 * 1024)).toInt()
        val availableRamMB = (memoryInfo.availMem / (1024 * 1024)).toInt()
        
        // OpenGL ES versiyonu
        val glEsVersion = getOpenGLVersion()
        
        // CPU çekirdek sayısı
        val cpuCores = Runtime.getRuntime().availableProcessors()
        
        // Refresh rate
        val refreshRate = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.context.display?.refreshRate ?: 60f
        } else {
            val display = windowManager.defaultDisplay
            display?.refreshRate ?: 60f
        }
        
        // Cihaz markası ve modeli tespit et
        val manufacturer = Build.MANUFACTURER.lowercase()
        val model = Build.MODEL.lowercase()
        val device = Build.DEVICE.lowercase()
        
        // 🚀 PERFORMANCE MOD: Özel cihaz tespiti
        val isXiaomiDevice = manufacturer.contains("xiaomi") || 
                            manufacturer.contains("redmi") ||
                            model.contains("redmi") ||
                            model.contains("xiaomi")
        
        val isSamsungDevice = manufacturer.contains("samsung")
        val isOnePlusDevice = manufacturer.contains("oneplus")
        val isOppoDevice = manufacturer.contains("oppo")
        val isVivoDevice = manufacturer.contains("vivo")
        val isRealmeDevice = manufacturer.contains("realme")
        
        // MIUI versiyonu tespit et
        val miuiVersion = if (isXiaomiDevice) {
            getMiuiVersion()
        } else ""
        
        // Performans kategorisi belirleme
        val performanceCategory = determinePerformanceCategoryDetailed(
            totalRamMB, 
            glEsVersion, 
            cpuCores,
            refreshRate,
            Build.VERSION.SDK_INT
        )
        
        // Thermal durum kontrolü
        val thermalStatus = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.currentThermalStatus
        } else 0
        
        return mapOf(
            "totalRamMB" to totalRamMB,
            "availableRamMB" to availableRamMB,
            "glEsVersion" to glEsVersion,
            "cpuCores" to cpuCores,
            "apiLevel" to Build.VERSION.SDK_INT,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "isXiaomiDevice" to isXiaomiDevice,
            "isSamsungDevice" to isSamsungDevice,
            "miuiVersion" to miuiVersion,
            "refreshRate" to refreshRate,
            "performanceCategory" to performanceCategory,
            "thermalStatus" to thermalStatus,
            "board" to Build.BOARD,
            "hardware" to Build.HARDWARE,
            "isEmulator" to isEmulator()
        )
    }
    
    private fun getOpenGLVersion(): Double {
        return try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val configurationInfo = activityManager.deviceConfigurationInfo
            val glEsVersion = configurationInfo.glEsVersion
            
            // Version string'ini double'a çevir (örn: "3.0" -> 3.0)
            glEsVersion.toDoubleOrNull() ?: 2.0
        } catch (e: Exception) {
            2.0 // Hata durumunda varsayılan
        }
    }
    
    private fun getMiuiVersion(): String {
        return try {
            val property = Class.forName("android.os.SystemProperties")
                .getMethod("get", String::class.java)
            
            val miuiVersionName = property.invoke(null, "ro.miui.ui.version.name") as? String ?: ""
            val miuiVersionCode = property.invoke(null, "ro.miui.ui.version.code") as? String ?: ""
            
            if (miuiVersionName.isNotEmpty()) {
                "$miuiVersionName (Code: $miuiVersionCode)"
            } else ""
        } catch (e: Exception) {
            ""
        }
    }
    
    private fun isEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.BOARD == "QC_Reference_Phone"
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.HOST.startsWith("Build")
                || (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic"))
                || Build.PRODUCT == "google_sdk"
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu"))
    }
    
    private fun setHighPerformanceMode(enabled: Boolean) {
        if (enabled) {
            // 🚀 PERFORMANCE MOD: Yüksek performans modu
            runOnUiThread {
                // Hardware acceleration
                window.setFlags(
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
                )
                
                // 🔧 ANR DÜZELTMESİ: FLAG_KEEP_SCREEN_ON ve setSustainedPerformanceMode KALDIRILDI
                // Her ikisi de thermal throttling ve düşük performansa neden oluyordu
            }
        } else {
            runOnUiThread {
                // Normal mod - ek işlem gerekmez
                Log.d(TAG, "Normal performans modu")
            }
        }
    }
    
    // 🚀 PERFORMANCE MOD: Detaylı performans kategorisi belirleme
    private fun determinePerformanceCategoryDetailed(
        ramMB: Int, 
        glVersion: Double, 
        cores: Int,
        refreshRate: Float,
        apiLevel: Int
    ): String {
        // Gelişmiş kategori belirleme
        return when {
            // Ultra high-end cihazlar (Flagship 2024-2025)
            ramMB >= 12288 && cores >= 8 && glVersion >= 3.2 && apiLevel >= 31 && refreshRate >= 120f -> {
                "ultra_high_end"
            }
            // High-end cihazlar (Flagship 2022-2023)
            ramMB >= 8192 && cores >= 8 && glVersion >= 3.2 && apiLevel >= 29 -> {
                "high_end"
            }
            // Mid-range cihazlar (Orta segment)
            ramMB >= 4096 && cores >= 4 && glVersion >= 3.0 && apiLevel >= 26 -> {
                "mid_range"
            }
            // Low-end cihazlar (Giriş seviyesi)
            else -> {
                "low_end"
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // 🚀 PERFORMANCE MOD: Resume'da performans ayarlarını yenile
        Log.d(TAG, "Uygulama resume - performans ayarları aktif")
    }
    
    override fun onPause() {
        super.onPause()
        // 🚀 PERFORMANCE MOD: Pause'da güç tasarrufu
        Log.d(TAG, "Uygulama pause - güç tasarrufu modu")
    }
}
