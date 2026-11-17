# Flutter 引擎、插件注册与嵌入层（避免 R8 裁掉反射调用的入口）
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# 保留注解信息（部分插件/序列化依赖）
-keepattributes *Annotation*