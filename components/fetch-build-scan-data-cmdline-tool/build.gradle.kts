@file:Suppress("UnstableApiUsage")

plugins {
    id("application")
    id("java")
    id("jvm-test-suite")
    id("com.github.johnrengelman.shadow") version "8.1.1"
    id("org.openapi.generator") version "6.5.0"
    id("org.graalvm.buildtools.native") version "0.9.21"

}

description = "Application to fetch build scan data using the Gradle Enterprise Export API"

repositories {
    mavenCentral()
}

graalvmNative {
    testSupport.set(false)

    binaries {
        named("main") {
            verbose.set(true)
            buildArgs.apply {
                add("--enable-url-protocols=https")
                add("--enable-url-protocols=http")
                add("--enable-url-protocols=ws")
                add("--enable-https")
                add("--enable-http")
                add("-H:+AddAllCharsets")
                add("-H:+ReportUnsupportedElementsAtRuntime")
                add("-H:+ReportExceptionStackTraces")
                add("-H:ReflectionConfigurationFiles=${projectDir}/src/main/resources/META-INF/native-image/reflect-config.json")

//                initializedAtBuildTime(
//                    "ch.qos.logback.classic.Logger",
//                    "org.slf4j.impl.StaticLoggerBinder",
//                    "org.slf4j.LoggerFactory",
//                    "ch.qos.logback.classic.Logger",
//                    "ch.qos.logback.core.spi.AppenderAttachableImpl",
//                    "ch.qos.logback.core.status.StatusBase",
//                    "ch.qos.logback.classic.Level",
//                    "ch.qos.logback.core.status.InfoStatus",
//                    "ch.qos.logback.classic.PatternLayout",
//                    "ch.qos.logback.core.CoreConstants",
//                    "org.slf4j.MDC",
//                    "org.jcodings.spi.Charsets",
//                    "org.apache.logging.log4j.core.impl.Log4jContextFactory",
//                    "org.apache.logging.log4j.util.Constants",
//                    "org.apache.logging.log4j.spi.StandardLevel",
//                    "org.apache.logging.log4j.util.PropertiesUtil",
//                    "org.apache.logging.log4j.util.LoaderUtil",
//                    "org.apache.logging.log4j.status.StatusLogger",
//                    "org.apache.logging.log4j.Level",
//                    "org.apache.logging.log4j.util.Strings",
//                    "org.apache.logging.log4j.simple.SimpleLogger",
//                    "org.apache.logging.log4j.util.PropertySource\$Util",
//                    "org.apache.logging.log4j.spi.AbstractLogger",
//                    "javax.script.ScriptEngineManager"
//                )
            }
//            javaLauncher.set(javaToolchains.launcherFor {
//                languageVersion.set(JavaLanguageVersion.of(11))
//                vendor.set(JvmVendorSpec.GRAAL_VM)
//            })
        }
    }
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

    implementation("com.google.guava:guava:31.1-jre")
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

val native by configurations.creating {
    isCanBeConsumed = true
    isCanBeResolved = false
}

artifacts {
    add("native", tasks.nativeCompile)
}