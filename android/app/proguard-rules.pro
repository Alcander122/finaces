# ============================================================
# FLUTTER
# ============================================================

-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ============================================================
# FIREBASE
# ============================================================

-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ============================================================
# GOOGLE MOBILE ADS
# ============================================================

-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ============================================================
# GOOGLE PLAY SERVICES
# ============================================================

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ============================================================
# KOTLIN
# ============================================================

-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# ============================================================
# MULTIDEX
# ============================================================

-keep class androidx.multidex.** { *; }

# ============================================================
# DESUGARING
# ============================================================

-dontnote j$.util.**
-dontnote j$.time.**
-dontnote j$.concurrent.**

# ============================================================
# SERIALIZACIÓN
# ============================================================

-keepattributes Signature, InnerClasses, *Annotation*

# ============================================================
# PLAY CORE (Ignorar clases faltantes del motor Flutter)
# ============================================================
-dontwarn com.google.android.play.core.**

# ============================================================
# FLUTTER LOCAL NOTIFICATIONS
# ============================================================
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Gson rules (required by flutter_local_notifications)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# ============================================================
# FLUTTER TIMEZONE
# ============================================================
-keep class com.baseflow.fluttertimezone.** { *; }
-keep class es.antonborri.flutter_native_timezone.** { *; }