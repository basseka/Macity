# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dart / Gson / JSON
-keepattributes Signature,*Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Flutter Local Notifications (uses Gson TypeToken internally)
-keep class com.dexterous.** { *; }

# OkHttp (used by Dio)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# SharedPreferences
-keep class androidx.datastore.** { *; }

# SQLite (Drift)
-keep class org.sqlite.** { *; }
-keep class sqlite3.** { *; }

# Google Play Core (deferred components / split install)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
