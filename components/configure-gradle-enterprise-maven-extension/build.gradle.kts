plugins {
    id("java")
}

repositories {
    mavenCentral()
}

dependencies {
    compileOnly("org.apache.maven:maven-core:3.9.6")
    compileOnly("org.codehaus.plexus:plexus-component-annotations:2.2.0")
    compileOnly("com.gradle:develocity-maven-extension:1.21.3")
    implementation("com.gradle:develocity-maven-extension-adapters:${rootProject.extra["develocityMavenExtensionAdaptersVersion"]}")
}

description = "Maven extension to capture the build scan URL"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(8))
        vendor.set(JvmVendorSpec.AZUL)
    }
}

tasks.withType(JavaCompile::class).configureEach {
    options.encoding = "UTF-8"
}
