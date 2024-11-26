@file:Suppress("UnstableApiUsage")


plugins {
    id("groovy")
    id("jvm-test-suite")
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(8)
        vendor = JvmVendorSpec.AZUL
    }
}

val gradleScripts = configurations.dependencyScope("gradleScripts") {
    attributes.attribute(Usage.USAGE_ATTRIBUTE, objects.named("gradle-build-validation-scripts"))
}.get()

val gradleScriptsResolvable = configurations.resolvable("${gradleScripts.name}Resolvable") {
    extendsFrom(gradleScripts)
    attributes.attribute(Usage.USAGE_ATTRIBUTE, objects.named("gradle-build-validation-scripts"))
}

val mavenScripts = configurations.dependencyScope("mavenScripts") {
    attributes.attribute(Usage.USAGE_ATTRIBUTE, objects.named("maven-build-validation-scripts"))
}.get()

val mavenScriptsResolvable = configurations.resolvable("${mavenScripts.name}Resolvable") {
    extendsFrom(mavenScripts)
    attributes.attribute(Usage.USAGE_ATTRIBUTE, objects.named("maven-build-validation-scripts"))
}

repositories {
    mavenCentral()
}

dependencies {
    gradleScripts(project(":"))
    mavenScripts(project(":"))
}

val test by testing.suites.getting(JvmTestSuite::class) {
    useSpock()
    dependencies {
        implementation(gradleTestKit())
    }

    targets.configureEach {
        testTask {
            val develocityKeysFile = gradle.gradleUserHomeDir.resolve("develocity/keys.properties")
            val develocityKeysEnv = providers.environmentVariable("DEVELOCITY_ACCESS_KEY")
            val develocityTestingServer = providers.gradleProperty("develocityTestingServer")

            onlyIf("Has credentials for Develocity testing server") {
                val develocityTestingServerHost = develocityTestingServer.get().removePrefix("https://")
                (develocityKeysFile.exists() && develocityKeysFile.readText().contains(develocityTestingServerHost))
                    || develocityKeysEnv.map { it.contains(develocityTestingServerHost) }.getOrElse(false)
            }

            jvmArgumentProviders.add(objects.newInstance<Jdk8HomeArgumentProvider>().apply {
                jdk8HomeDirectory = javaLauncher.map { it.metadata.installationPath }
            })

            jvmArgumentProviders.add(objects.newInstance<DevelocityTestUrlArgumentProvider>().apply {
                this.develocityTestingServer = develocityTestingServer
            })
        }
    }
}

tasks.processTestResources {
    from(gradleScriptsResolvable)
    from(mavenScriptsResolvable)
}

abstract class Jdk8HomeArgumentProvider : CommandLineArgumentProvider {

    // JDK version is already an input to the test task.
    // Its location on disk doesn't matter.
    @get:Internal
    abstract val jdk8HomeDirectory: DirectoryProperty

    override fun asArguments(): List<String> {
        return listOf("-Djdk8.home=${jdk8HomeDirectory.get().asFile.absolutePath}")
    }

}

abstract class DevelocityTestUrlArgumentProvider : CommandLineArgumentProvider {

    @get:Input
    abstract val develocityTestingServer: Property<String>

    override fun asArguments(): List<String> {
        return listOf("-Ddevelocity.testing-server=${develocityTestingServer.get()}")
    }

}
