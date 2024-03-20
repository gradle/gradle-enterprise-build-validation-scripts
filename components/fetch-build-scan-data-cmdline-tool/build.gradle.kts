@file:Suppress("UnstableApiUsage")

plugins {
    id("application")
    id("java")
    id("jvm-test-suite")
    id("com.github.johnrengelman.shadow") version "8.1.1"
    id("org.openapi.generator") version "6.5.0"
}

description = "Application to fetch build scan data using the Gradle Enterprise Export API"

repositories {
    mavenCentral()
}

dependencies {
    implementation(platform("com.squareup.okhttp3:okhttp-bom:4.12.0"))
    implementation("com.squareup.okhttp3:okhttp")
    implementation("com.squareup.okhttp3:okhttp-tls")
    implementation("com.squareup.okhttp3:logging-interceptor")

    implementation("io.swagger:swagger-annotations:1.6.14")
    implementation("io.gsonfire:gson-fire:1.9.0")
    implementation("javax.ws.rs:jsr311-api:1.1.1")
    implementation("javax.ws.rs:javax.ws.rs-api:2.1.1")

    implementation("com.google.guava:guava:33.1.0-jre")
    implementation("info.picocli:picocli:4.7.4")
    annotationProcessor("info.picocli:picocli-codegen:4.7.4")
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

openApiGenerate {
    generatorName.set("java")
    inputSpec.set("$projectDir/src/main/openapi/openapi.yaml")
    outputDir.set("$buildDir/generated/gradle_enterprise_api")
    ignoreFileOverride.set("$projectDir/.openapi-generator-ignore")
    modelPackage.set("com.gradle.enterprise.api.model")
    apiPackage.set("com.gradle.enterprise.api")
    invokerPackage.set("com.gradle.enterprise.api.client")
    // see https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/java.md for a description of each configuration option
    configOptions.set(mapOf(
        "library" to "okhttp-gson",
        "dateLibrary" to "java8",
        "hideGenerationTimestamp" to "true",
        "openApiNullable" to "false",
        "useBeanValidation" to "false",
        "disallowAdditionalPropertiesIfNotPresent" to "false",
        "sourceFolder" to ""  // makes IDEs like IntelliJ more reliably interpret the class packages.
    ))
}

sourceSets {
    main {
        java {
            srcDir(tasks.openApiGenerate)
        }
    }
}

tasks.withType(JavaCompile::class).configureEach {
    options.compilerArgs.add("-Aproject=${project.group}/${project.name}")
    options.encoding = "UTF-8"
}

application {
    mainClass.set("com.gradle.enterprise.Main")
}
