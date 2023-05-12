@file:Suppress("UnstableApiUsage")

plugins {
    id("application")
    id("java")
    id("jvm-test-suite")
    id("com.github.johnrengelman.shadow") version "8.1.1"
}

description = "Application to fetch build scan data using the Gradle Enterprise Export API"

repositories {
    mavenCentral()
}

dependencies {
    implementation(project(":build-scan-data-loader-api"))
    implementation(project(":build-scan-data-loader-online"))
    implementation(project(":build-scan-data-loader-offline"))

    implementation("info.picocli:picocli:4.7.3")
    annotationProcessor("info.picocli:picocli-codegen:4.7.3")
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(8))
        vendor.set(JvmVendorSpec.AZUL)
    }
}

val test by testing.suites.getting(JvmTestSuite::class) {
    useJUnitJupiter()
}

tasks.withType(JavaCompile::class).configureEach {
    options.compilerArgs.add("-Aproject=${project.group}/${project.name}")
    options.encoding = "UTF-8"
}

application {
    mainClass.set("com.gradle.enterprise.Main")
}
