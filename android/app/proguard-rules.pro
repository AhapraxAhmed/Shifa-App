# Firebase
-keep class com.google.firebase.** { *; }
-keepclassmembers class * {
    @com.google.firebase.** *;
}

# Riverpod
-keep class **Provider { *; }

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**