// Remove the plugins block we added previously
/*
plugins { 
    id(\"com.android.application\") version \"8.2.0\" apply false
    id(\"com.android.library\") version \"8.2.0\" apply false
    id(\"org.jetbrains.kotlin.android\") version \"1.8.22\" apply false 
    id(\"dev.flutter.flutter-gradle-plugin\") version \"1.0.0\" apply false
}
*/

// Top-level build file where configuration options are common to all sub-projects/modules.

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Removed Google Services classpath since we're not using the plugin
        // classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configure build directory (keep existing)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
