plugins {
    java
}

repositories {
    mavenCentral()
}

dependencies {
    annotationProcessor("org.eclipse.sisu:org.eclipse.sisu.inject:0.3.5")
    compileOnly("org.apache.maven:maven-core:3.8.2")
    compileOnly("org.codehaus.plexus:plexus-component-annotations:2.1.1")
    compileOnly("com.gradle:gradle-enterprise-maven-extension:1.12")
}

group = "com.gradle"
version = "1.0.0-SNAPSHOT"
description = "Gradle Enterprise Capture Published Build Scan Maven Extension"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(8))
    }
}

tasks.withType<JavaCompile>() {
    options.encoding = "UTF-8"
}
