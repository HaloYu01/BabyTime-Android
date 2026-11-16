allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Kotlin 增量编译会把源文件路径按「相对 android/ 目录」写进缓存（RelocatableFileToPathConverter）。
// pub 缓存里的插件源码在 C 盘、工程在 D 盘时无法求出相对路径，KGP 2.4.0 会以
// "Could not close incremental caches ... different roots" 直接让 assembleDebug 失败（KT-63983）。
// 这里仅对 android/ 之外的子工程（即 pub 缓存中的 Flutter 插件）关闭增量编译，:app 保持增量。
subprojects {
    if (!projectDir.canonicalPath.startsWith(rootDir.canonicalPath)) {
        extra["kotlin.incremental"] = "false"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
