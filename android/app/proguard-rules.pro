# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class com.baseflow.** { *; }
-dontwarn io.flutter.embedding.android.FlutterFragment
-dontwarn io.flutter.embedding.android.FlutterFragmentActivity
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Generated Flutter code
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ML Kit Vision & Text Recognition
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_vision_text.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**

# Play Core & GMS
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.internal.**
-dontwarn com.google.android.gms.common.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Hive
-keep class net.bytebuddy.** { *; }
-dontwarn net.bytebuddy.**

# Generic Android & Java
-dontwarn java.lang.invoke.*
-dontwarn **.R$*
-keep class **.R$* {
    <fields>;
}

# Desugaring
-dontwarn com.android.tools.desugar.**
