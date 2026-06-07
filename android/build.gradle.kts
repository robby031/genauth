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

fun forceCompileSdk36For(project: org.gradle.api.Project) {
    val androidExt = project.extensions.findByName("android") ?: return

    val setCompileSdk = androidExt.javaClass.methods.firstOrNull {
        it.name == "setCompileSdk" && it.parameterTypes.size == 1
    }
    if (setCompileSdk != null) {
        setCompileSdk.invoke(androidExt, 36)
        return
    }

    val setCompileSdkVersion = androidExt.javaClass.methods.firstOrNull {
        it.name == "setCompileSdkVersion" && it.parameterTypes.size == 1
    }
    setCompileSdkVersion?.invoke(androidExt, 36)
}

subprojects {
    plugins.withId("com.android.application") {
        forceCompileSdk36For(this@subprojects)
    }
    plugins.withId("com.android.library") {
        forceCompileSdk36For(this@subprojects)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
