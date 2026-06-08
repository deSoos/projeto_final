allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val projectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(projectBuildDir)
    project.evaluationDependsOn(":app")
    plugins.withId("com.android.library") {
        extensions.getByType<com.android.build.gradle.LibraryExtension>().compileSdk = 36
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}