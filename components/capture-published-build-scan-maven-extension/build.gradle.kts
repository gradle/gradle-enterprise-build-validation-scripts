plugins {
    java
}

repositories {
    mavenCentral()
}

dependencies {
    annotationProcessor("org.eclipse.sisu:org.eclipse.sisu.inject:0.3.5")
    compileOnly("org.apache.maven:maven-core:3.8.4")
    compileOnly("org.codehaus.plexus:plexus-component-annotations:2.1.1")
    compileOnly("com.gradle:gradle-enterprise-maven-extension:1.12")
}

description = "A maven extension to capture the URL of published Gradle Enterprise Build Scans"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(8))
    }
}

tasks.withType<JavaCompile>() {
    options.encoding = "UTF-8"
}
