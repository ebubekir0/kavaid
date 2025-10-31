# Flutter için temel ProGuard kuralları

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Flutter WebView
-keep class io.flutter.plugins.webviewflutter.** { *; }

# In App Purchase
-keep class io.flutter.plugins.inapppurchase.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**


# JSON serialization
-keepattributes *Annotation*
-keepattributes Signature
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Model sınıfları
-keep class com.onbir.kavaid.models.** { *; }

# Reflection için
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations

# Enum sınıfları
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }
-keep class io.flutter.plugin.common.** { *; }

# Sqflite
-keep class com.tekartik.** { *; }
-keep class io.flutter.plugins.sqflite.** { *; }

# Connectivity Plus
-keep class com.baseflow.geolocator.** { *; }

# Google Play Core (Dynamic Delivery için gerekli)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Güvenlik için hassas bilgileri gizle
-printmapping mapping.txt
-verbose 