@file:Suppress("HasPlatformType")

plugins {
    id("java-library")
    id("org.openapi.generator") version "6.6.0"
}

val gradleEnterpriseVersion = "2022.4"

repositories {
    mavenCentral()

    exclusiveContent {
        forRepository {
            ivy {
                url = uri("https://docs.gradle.com/")
                patternLayout {
                    artifact("[organisation]/api-manual/ref/[artifact]-[revision]-api.[ext]")
                }
                metadataSources {
                    artifact()
                }
            }
        }
        filter {
            includeModule("enterprise", "gradle-enterprise")
        }
    }
}

val openApiSpec by configurations.creating

dependencies {
    openApiSpec("enterprise:gradle-enterprise:$gradleEnterpriseVersion@yaml")

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
    inputSpec.set(providers.provider { openApiSpec.singleFile.absolutePath })
    outputDir.set("$buildDir/generated/gradle_enterprise_api")
    ignoreFileOverride.set("$projectDir/.openapi-generator-ignore")
    apiPackage.set("com.gradle.enterprise.api")
    modelPackage.set("com.gradle.enterprise.api.model")
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