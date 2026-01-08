# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Gson specific classes
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Dio
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**
-keepattributes Exceptions, InnerClasses
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable
-keep class okhttp3.logging.** { *; }
-dontwarn okhttp3.logging.**
-keep class com.squareup.okhttp3.** { *; }
-dontwarn com.squareup.okhttp3.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.firebase.firestore.** { *; }

# GetX
-keep class com.github.jonataslaw.** { *; }
-keep class get.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes AnnotationDefault

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep R class
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep custom model classes (adjust package name as needed)
-keep class com.example.driver_tracking_airport.** { *; }

# Keep data classes used in JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Preserve line numbers for stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Don't warn about missing classes
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn sun.misc.**
-dontwarn java.lang.management.**
-dontwarn android.net.http.AndroidHttpClient
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Keep generic signature of Call, Response (R8 full mode strips signatures from non-kept items).
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class retrofit2.Response

# With R8 full mode generic signatures are stripped for classes that are not
# kept. Suspend functions are wrapped in continuations where the type argument
# is used.
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# Camera and Image Picker
-keep class androidx.camera.** { *; }
-keep class io.flutter.plugins.camera.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# Location Services
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.**

# SQLite
-keep class io.flutter.plugins.sqflite.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Video Player
-keep class io.flutter.plugins.videoplayer.** { *; }

# Connectivity
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Image Cropper
-keep class vn.hunghd.flutter.plugins.imagecropper.** { *; }

# Signature
-keep class com.github.4sh.dataclasses.** { *; }

# Polyline Points
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Thumbnail
-keep class io.flutter.plugins.videothumbnail.** { *; }

# Preserve annotation default values
-keepattributes AnnotationDefault

# Keep setters in Views so that animations can still work.
-keepclassmembers public class * extends android.view.View {
   void set*(***);
   *** get*();
}

# We want to keep methods in Activity that could be used in the XML attribute onClick
-keepclassmembers class * extends android.app.Activity {
   public void *(android.view.View);
}

# For enumeration classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Keep all model classes that might be used with JSON
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep application classes
-keep public class * extends android.app.Application
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider



