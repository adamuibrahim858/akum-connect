# Flutter & Dart
-keepattributes Signature,Annotation,EnclosingMethod,InnerClasses
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.android.gms.ads.identifier.AdvertisingIdClient{ public *; }
-keep class com.google.android.gms.ads.identifier.AdvertisingIdClient$Info{ public *; }

# Hive
-keep class io.hive.** { *; }
-keep class io.flutter.plugins.hive.** { *; }

# General
-dontwarn android.test.**
-dontwarn android.net.**
-dontwarn com.google.android.gms.**
-dontwarn androidx.**
-dontwarn javax.annotation.**
-dontwarn io.flutter.plugins.**
-ignorewarnings

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Prevent R8 from stripping plugin classes that might be accessed via reflection
-keep public class * implements io.flutter.plugin.common.PluginRegistry$PluginRegistrant
-keep public class * implements io.flutter.embedding.engine.plugins.FlutterPlugin
-keep public class * implements io.flutter.embedding.engine.plugins.activity.ActivityAware


# Dio & Http
-keep class dio.** { *; }
-keep class dio.src.** { *; }
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn dio.**
