plugins {
    id("java-library")
    id("org.openapi.generator") version "6.6.0"
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(platform("com.squareup.okhttp3:okhttp-bom:4.11.0"))
    implementation("com.squareup.okhttp3:okhttp")
    implementation("com.squareup.okhttp3:okhttp-tls")
    implementation("com.squareup.okhttp3:logging-interceptor")

    implementation("io.swagger:swagger-annotations:1.6.10")
    implementation("io.gsonfire:gson-fire:1.8.5")
    implementation("javax.ws.rs:jsr311-api:1.1.1")
    implementation("javax.ws.rs:javax.ws.rs-api:2.1.1")

    implementation("javax.annotation:javax.annotation-api:1.3.2")
    implementation("com.google.code.findbugs:jsr305:3.0.2")
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(8))
        vendor.set(JvmVendorSpec.AZUL)
    }
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
            "containerDefaultToNull" to "true",
            "sourceFolder" to ""
    ))
}

sourceSets {
    main {
        java {
            srcDir(tasks.openApiGenerate)
        }
    }
}
