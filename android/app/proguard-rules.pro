# Flutter engine
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.app.**  { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# flutter_secure_storage (uses reflection on Android Keystore classes)
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Retain generic type information for Gson/Serialization used by plugins
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions

# Suppress missing class warnings for unused transitive dependencies (Apache Tika)
-dontwarn javax.xml.stream.XMLStreamException
-dontwarn org.apache.tika.**
-dontwarn javax.xml.stream.**
-dontwarn org.xml.sax.**
