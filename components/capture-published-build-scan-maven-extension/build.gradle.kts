plugins {
    java
}

repositories {
    mavenLocal()
    mavenCentral()
}

dependencies {
    annotationProcessor("org.eclipse.sisu:org.eclipse.sisu.inject:0.3.4")
    compileOnly("org.apache.maven:maven-core:3.8.1")
    compileOnly("org.codehaus.plexus:plexus-component-annotations:1.7.1")
    compileOnly("com.gradle:gradle-enterprise-maven-extension:1.10.2")
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
