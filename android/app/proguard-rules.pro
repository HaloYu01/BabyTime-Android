# Flutter 引擎、插件注册与嵌入层（避免 R8 裁掉反射调用的入口）
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# 保留注解信息（部分插件/序列化依赖）
-keepattributes *Annotation*
# Flutter 引擎的延迟组件（deferred components）引用 Play Core；
# 本项目未使用动态功能、未引入 Play Core 依赖，忽略缺失类警告。
-dontwarn com.google.android.play.core.**