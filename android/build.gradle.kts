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
    // flutter_facebook_auth 7.1.1 compileSdk 31 ile geliyor; androidx bağımlılıkları 34+ istiyor
    if (name == "flutter_facebook_auth") {
        afterEvaluate {
            val a = extensions.getByName("android")
            a.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType).invoke(a, 36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
