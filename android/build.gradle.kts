buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ Android Gradle Plugin (ensure compatibility with your Gradle wrapper)
        classpath("com.android.tools.build:gradle:7.3.0")

        // ✅ Kotlin Plugin
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.7.10")

        // ✅ Google Services plugin (needed for Firebase)
        classpath("com.google.gms:google-services:4.4.2") // use latest stable
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Optional (keeps Flutter’s build artifacts in a shared location)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// ✅ Ensure ":app" is evaluated before others
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
