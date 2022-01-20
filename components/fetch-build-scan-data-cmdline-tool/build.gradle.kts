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
    swaggerCodegen("org.openapitools:openapi-generator-cli:5.3.0")

    implementation(platform("com.squareup.okhttp3:okhttp-bom:4.9.3"))
    implementation("com.squareup.okhttp3:okhttp")
    implementation("com.squareup.okhttp3:okhttp-sse")
    implementation("com.squareup.okhttp3:logging-interceptor")

    implementation("io.swagger:swagger-annotations:1.5.24")
    implementation("com.google.code.findbugs:jsr305:3.0.2")

    implementation("com.google.code.gson:gson:2.8.6")
    implementation("io.gsonfire:gson-fire:1.8.4")
    implementation("org.openapitools:jackson-databind-nullable:0.2.1")
    implementation("org.apache.commons:commons-lang3:3.10")
    implementation("org.threeten:threetenbp:1.4.3")
    implementation("jakarta.annotation:jakarta.annotation-api:1.3.5")

    implementation(platform("com.fasterxml.jackson:jackson-bom:2.13.3"))
    implementation("com.fasterxml.jackson.core:jackson-databind:2.13.3")

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
        configFile = layout.projectDirectory.file("src/main/openapi/openapi-generator-config.json").asFile
    }
}

sourceSets {
    main {
        java {
            srcDir(layout.buildDirectory.dir("swagger-code-gradleEnterprise/src/main/java"))
        }
    }
}

tasks.compileJava {
    dependsOn("generateSwaggerCode")  // TODO figure out how to eliminate the explicit dependency
    options.compilerArgs.add("-Aproject=${project.group}/${project.name}")
    options.encoding = "UTF-8"
}

application {
    mainClass.set("com.gradle.enterprise.Main")
}
