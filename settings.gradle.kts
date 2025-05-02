pluginManagement {
    repositories {
        google() // A Google Maven repository-ja (AndroidX, stb.)
        mavenCentral() // A Maven Central repository-ja (sok általános könyvtár)
        gradlePluginPortal() // A Gradle pluginok repository-ja
    }
}
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        // Add the jitpack repository here
        maven { url = uri("https://jitpack.io") }
    }
}
plugins {
    id("com.android.application") version "8.9.1" apply false
    id("com.android.library") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}
