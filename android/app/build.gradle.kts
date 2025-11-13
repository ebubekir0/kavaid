import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// key.properties dosyasını oku
val keystorePropertiesFile = file("../key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.onbir.kavaid"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.onbir.kavaid"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 3007
        versionName = "3.0.7"
        
        // Multidex desteği
        multiDexEnabled = true
        
        // PERFORMANCE MOD: Native optimizasyonlar
        // ABI kısıtlamasını kaldırdık; AAB tüm ABIs için split üretecek
        
        // 🚀 PERFORMANCE MOD: Render optimizasyonları
        renderscriptTargetApi = 19
        renderscriptSupportModeEnabled = true
        
        // 🚀 PERFORMANCE MOD: Vector drawable desteği
        vectorDrawables.useSupportLibrary = true
    }

    signingConfigs {
        create("release") {
            // Determine effective alias: if provided alias is 'onbir', override to 'upload'
            val providedAlias = keystoreProperties["keyAlias"] as String?
            val effectiveAlias = if (providedAlias == "onbir") "upload" else providedAlias ?: "upload"
            keyAlias = effectiveAlias
            keyPassword = keystoreProperties["keyPassword"] as String
            // Resolve storeFile with fallbacks
            val providedPath = keystoreProperties["storeFile"]?.toString()
            val candidates = mutableListOf<String>()
            if (!providedPath.isNullOrBlank()) candidates.add(providedPath)
            // Common relative locations from android/app (prefer project root first)
            candidates.addAll(listOf(
                "../../upload-keystore.jks",    // project root (kavaid/)
                "../upload-keystore.jks",       // android/
                "../../../upload-keystore.jks"  // workspace root (kavaid1111/)
            ))
            val resolvedStoreFile = candidates.map { file(it) }.firstOrNull { it.exists() }
            storeFile = resolvedStoreFile
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // Release build için signing config
            // Geçici bayrak: -PuseDebugSigning=true verilirse release'i debug keystore ile imzala
            val useDebugSigning = (project.findProperty("useDebugSigning") as String?) == "true"
            val releaseSigningConfig = signingConfigs.findByName("release")
            signingConfig = if (useDebugSigning) {
                signingConfigs.getByName("debug")
            } else if (releaseSigningConfig != null && releaseSigningConfig.storeFile?.exists() == true) {
                releaseSigningConfig
            } else {
                signingConfigs.getByName("debug")
            }
            
            // Performans optimizasyonları
            isMinifyEnabled = true
            isShrinkResources = true
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Daha iyi performans için optimizasyonlar
            isDebuggable = false
            isJniDebuggable = false
            isRenderscriptDebuggable = false
            
            // 🚀 PERFORMANCE MOD: Release optimizasyonları - Debug symbol stripping devre dışı
            ndk {
                debugSymbolLevel = "NONE"
            }
            
            // 🚀 PERFORMANCE MOD: Optimize edilmiş build flags
            packagingOptions {
                // Gereksiz dosyaları çıkar
                resources.excludes += listOf(
                    "META-INF/DEPENDENCIES",
                    "META-INF/LICENSE",
                    "META-INF/LICENSE.txt",
                    "META-INF/NOTICE",
                    "META-INF/NOTICE.txt"
                )
            }
            
            // APK boyutunu küçültmek için
            resValue("string", "app_name", "Kavaid")
        }
        
        debug {
            // Debug için suffix kaldırıldı - google-services.json uyumu için
            versionNameSuffix = "-debug"
            isDebuggable = true
            
            // 🚀 PERFORMANCE MOD: Debug'da da performans testleri için optimizasyonlar
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
            
            resValue("string", "app_name", "Kavaid Debug")
        }
        
        // 🚀 PERFORMANCE MOD: Mevcut profile build type'ını optimize et
        getByName("profile") {
            initWith(getByName("release"))
            versionNameSuffix = "-profile"
            // Profiling için debug bilgileri koru
            isDebuggable = false
            isProfileable = true
            
            // 🚀 PERFORMANCE MOD: Profile için özel optimizasyonlar
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
    

    
    // 🚀 PERFORMANCE MOD: Bundle optimizasyonları
    bundle {
        language {
            // Sadece gerekli dilleri ekle
            enableSplit = true
        }
        density {
            // Ekran yoğunluğu bazlı split
            enableSplit = true
        }
        abi {
            // ABI bazlı split
            enableSplit = true
        }
    }
    
    // Lint kontrollerini geçici olarak devre dışı bırak
    lint {
        abortOnError = false
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    // Google Mobile Ads SDK (explicit) - align with mediation adapter
    implementation("com.google.android.gms:play-services-ads:24.5.0")
}

// Google Services plugin'i apply et
apply(plugin = "com.google.gms.google-services")

// 🚀 PERFORMANCE MOD: Build optimizasyonları
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlinOptions {
        freeCompilerArgs += listOf(
            "-opt-in=kotlin.RequiresOptIn",
            "-Xjvm-default=all",
            "-Xlambdas=indy"
        )
    }
}
