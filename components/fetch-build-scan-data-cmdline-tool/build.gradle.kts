plugins {
    java
    application
    id("com.github.johnrengelman.shadow") version "7.1.2"
    id("org.hidetake.swagger.generator") version "2.18.2"
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(platform("com.squareup.okhttp3:okhttp-bom:4.9.3"))
    implementation("com.squareup.okhttp3:okhttp")
    implementation("com.squareup.okhttp3:okhttp-sse")

    implementation(platform("com.fasterxml.jackson:jackson-bom:2.13.1"))
    implementation("com.fasterxml.jackson.core:jackson-databind:2.13.1")

    implementation("com.google.guava:guava:31.0.1-jre")
    implementation("info.picocli:picocli:4.6.2")
    annotationProcessor("info.picocli:picocli-codegen:4.6.2")
}

description = "Application to fetch build scan data using the Gradle Enterprise Export API"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(8))
    }
}

tasks.compileJava {
    options.compilerArgs.add("-Aproject=${project.group}/${project.name}")
    options.encoding = "UTF-8"
}

application {
    mainClass.set("com.gradle.enterprise.Main")
}
