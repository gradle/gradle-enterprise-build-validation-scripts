import org.hidetake.gradle.swagger.generator.GenerateSwaggerCode

plugins {
    java
    application
    id("com.github.johnrengelman.shadow") version "7.1.2"
    id("org.hidetake.swagger.generator") version "2.19.2"
}

repositories {
    mavenCentral()
}

dependencies {
    swaggerCodegen("org.openapitools:openapi-generator-cli:5.4.0")

    implementation(platform("com.squareup.okhttp3:okhttp-bom:4.10.0"))
    implementation("com.squareup.okhttp3:okhttp")
    implementation("com.squareup.okhttp3:okhttp-tls")
    implementation("com.squareup.okhttp3:logging-interceptor")

    implementation("io.swagger:swagger-annotations:1.6.6")
    implementation("io.gsonfire:gson-fire:1.8.5")

    implementation("com.google.guava:guava:31.1-jre")
    implementation("info.picocli:picocli:4.6.3")
    annotationProcessor("info.picocli:picocli-codegen:4.6.3")
}

description = "Application to fetch build scan data using the Gradle Enterprise Export API"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(8))
    }
}

swaggerSources.register("gradleEnterprise") {
    setInputFile(layout.projectDirectory.file("src/main/openapi/openapi.yaml").asFile)
    code.apply {
        language = "java"
        components = listOf(
            "models",
            "modelTests=false",
            "modelDocs=false",
            "apis",
            "apiTests=false",
            "apiDocs=false",
            "supportingFiles",
            "log.level=error"
        )
        configFile = layout.projectDirectory.file("src/main/openapi/openapi-generator-config.json").asFile
    }

    sourceSets {
        main {
            java {
                srcDir(code)
            }
        }
    }
}

tasks.compileJava {
    options.compilerArgs.add("-Aproject=${project.group}/${project.name}")
    options.encoding = "UTF-8"
}

tasks.withType(GenerateSwaggerCode::class) {
    notCompatibleWithConfigurationCache("Accesses the project at execution time.")
}

application {
    mainClass.set("com.gradle.enterprise.Main")
}
