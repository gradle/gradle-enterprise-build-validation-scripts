@file:Suppress("UnstableApiUsage", "HttpUrlsUsage")

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
            val testDevelocityServer = providers.gradleProperty("buildValidationTestDevelocityServer")

            onlyIf("has credentials for Develocity testing server") {
                val testDevelocityServerHost = testDevelocityServer.get().removePrefix("https://").removePrefix("http://")
                (develocityKeysFile.exists() && develocityKeysFile.readText().contains(testDevelocityServerHost))
                        || develocityKeysEnv.map { it.contains(testDevelocityServerHost) }.getOrElse(false)
            }

            jvmArgumentProviders.add(objects.newInstance<BuildValidationTestConfigurationProvider>().apply {
                develocityServer = testDevelocityServer
                jdk8HomeDirectory = javaLauncher.map { it.metadata.installationPath.asFile.absolutePath }
            })
        }
    }
}

tasks.processTestResources {
    from(gradleScriptsResolvable)
    from(mavenScriptsResolvable)
}

abstract class BuildValidationTestConfigurationProvider : CommandLineArgumentProvider {

    @get:Input
    abstract val develocityServer: Property<String>

    // JDK version is already an input to the test task.
    // Its location on disk doesn't matter.
    @get:Internal
    abstract val jdk8HomeDirectory: Property<String>

    override fun asArguments(): List<String> {
        return listOf(
            "-Dbuild-validation.test.develocity.server=${develocityServer.get()}",
            "-Dbuild-validation.test.jdk8-home=${jdk8HomeDirectory.get()}"
        )
    }

}
