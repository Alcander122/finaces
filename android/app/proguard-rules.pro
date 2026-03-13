# ==============================================================================
# SOLUCIÓN: Silenciar notas informativas de Desugaring (j$.)
# ==============================================================================
-dontnote j$.util.**
-dontnote j$.concurrent.**
-dontnote j$.time.**

# ==============================================================================
# REGLAS RECOMENDADAS PARA FLUTTER Y FIREBASE
# ==============================================================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ==============================================================================
# SOLUCIÓN PARA PLAY CORE (Evita errores de Missing Classes)
# ==============================================================================
-dontwarn com.google.android.play.core.**

# Si usas Deferred Components, mantén estas clases
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }

# Mantener atributos necesarios para serialización (Firebase/Gson)
-keepattributes Signature,Annotation,Exceptions