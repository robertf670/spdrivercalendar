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

# Additional Google Sign-In specific rules
-keep class com.google.android.gms.signin.** { *; }
-keep class com.google.android.gms.safetynet.** { *; }
-keep class com.google.android.gms.security.** { *; }
-keep class com.google.api.** { *; }
-keep class com.google.gson.** { *; }

# OAuth and authentication rules
-keep class * extends java.util.ListResourceBundle {
    protected java.lang.Object[][] getContents();
}
-keep class com.google.android.gms.internal.** { *; }

# Credential Manager rules
-if class androidx.credentials.CredentialManager
-keep class androidx.credentials.playservices.** {
  *;
}

# Keep certain attributes needed by some Google services
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Don't warn about missing classes in Google Play services (they might be optional)
-dontwarn com.google.android.gms.**
-dontwarn com.google.api.**
-dontwarn com.google.gson.**

# Add any project-specific rules here.
# E.g., if you use reflection or specific native libraries that R8 might remove. 