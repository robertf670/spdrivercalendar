# Flutter/Dart general rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Google Play services rules
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.firebase.** { *; } # Keep Firebase if you use other Firebase services

# Keep certain attributes needed by some Google services
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Don't warn about missing classes in Google Play services (they might be optional)
-dontwarn com.google.android.gms.**

# Add any project-specific rules here.
# E.g., if you use reflection or specific native libraries that R8 might remove. 