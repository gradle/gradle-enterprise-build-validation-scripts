plugins {
    java
    application
    id("com.github.johnrengelman.shadow") version "7.1.2"
}

description = "Application which mocks converting a scan dump to a CSV"

repositories {
    mavenCentral()
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(8))
    }
}

application {
    mainClass.set("com.gradle.enterprise.Main")
}

// See: https://github.com/gradle/gradle/issues/21364
tasks.withType<JavaExec>().configureEach {
    if (name.endsWith("main()")) {
        notCompatibleWithConfigurationCache("JavaExec created by IntelliJ")
    }
}
