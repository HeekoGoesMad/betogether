allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(rootProject.layout.projectDirectory.dir("../build"))

// subprojects {
//     project.layout.buildDirectory.set(rootProject.layout.buildDirectory.map { it.dir(project.name) })
// }

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    fun configureCompatibility() {
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
    if (state.executed) {
        configureCompatibility()
    } else {
        afterEvaluate {
            configureCompatibility()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

