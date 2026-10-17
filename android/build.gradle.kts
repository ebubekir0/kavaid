buildscript {
    // settings.gradle.kts'teki sürümlerle aynı olmalı
    val kotlinVersion = "2.2.21"

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.13.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Eski eklentiler (ör. flutter_displaymode) compileSdk 33 ile geliyor; Flutter'ın
// getirdiği androidx kütüphaneleri en az 34 istiyor. compileSdk yalnızca derlemeyi
// etkiler, çalışma davranışını (targetSdk) değiştirmez.
// evaluationDependsOn'dan önce olmalı: afterEvaluate değerlendirmeden önce kaydedilir.
subprojects {
    val raiseCompileSdk: (Project) -> Unit = { p ->
        p.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let {
            if ((it.compileSdk ?: 0) < 34) it.compileSdk = 36
        }
    }
    if (state.executed) raiseCompileSdk(this) else afterEvaluate { raiseCompileSdk(this) }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
