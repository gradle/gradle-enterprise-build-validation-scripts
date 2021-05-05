import de.undercouch.gradle.tasks.download.Download

plugins {
    id("base")
    id("de.undercouch.download") version "4.1.1"
}

base {
  distsDirName = rootDir.resolve("../").toString()
}

val components by configurations.creating

dependencies {
    components("com.gradle:capture-published-build-scan-maven-extension:1.0.0-SNAPSHOT")
}

val argbashVersion by extra("2.10.0")

tasks.register<Download>("downloadArgbash") {
    group = "argbash"
    description = "Downloads Argbash."
    src("https://github.com/matejak/argbash/archive/refs/tags/${argbashVersion}.zip")
    dest(file("${buildDir}/argbash/argbash-${argbashVersion}.zip"))
    overwrite(false)
}

tasks.register<Copy>("unpackArgbash") {
    group = "argbash"
    description = "Unpacks the downloaded Argbash archive."
    from(zipTree(tasks.getByName("downloadArgbash").outputs.files.singleFile))
    into(layout.buildDirectory.dir("argbash"))
    dependsOn("downloadArgbash")
}

tasks.register("generateBashCliParsers") {
    group = "argbash"
    description = "Uses Argbash to generate Bash command line argument parsing code."
    val scripts = fileTree("../scripts") {
        include("**/*-cli-parser.sh")
        exclude("gradle/data/")
        exclude("maven/data/")
    }
    inputs.files(scripts)
        .withPropertyName("scripts")
        .withPathSensitivity(PathSensitivity.RELATIVE)
    inputs.files(fileTree("src") {
        include("**/*.m4")
        exclude("gradle/data/")
        exclude("maven/data/")
    })
        .withPropertyName("templates")
        .withPathSensitivity(PathSensitivity.RELATIVE)
    outputs.files(scripts)
    val argbash = "${buildDir}/argbash/argbash-${argbashVersion}/bin/argbash"
    inputs.dir("${buildDir}/argbash/argbash-${argbashVersion}/")
        .withPropertyName("argbash")
        .withPathSensitivity(PathSensitivity.RELATIVE)
    dependsOn("unpackArgbash")
    doLast {
        scripts.forEach { file: File ->
            logger.info("Applying argbash to $file")
            exec {
                commandLine(argbash, "-i", file)
            }
        }
    }
}

tasks.register<Zip>("assembleGradleScripts") {
    group = "build"
    description = "Packages the Gradle experiment scripts in a zip archive."
    baseName = "gradle-enterprise-gradle-build-validation"

    from(layout.projectDirectory.dir("../scripts/gradle")) {
        exclude("data/")
    }
    from(layout.projectDirectory.dir("../scripts")) {
        include("lib/**")
        exclude("lib/maven")
        exclude("**/*.m4")
    }
    filter { line: String -> line.replace("/../lib", "/lib") }
    into(baseName)
    dependsOn("generateBashCliParsers")
}

tasks.register<Zip>("assembleMavenScripts") {
    group = "build"
    description = "Packages the Maven experiment scripts in a zip archive."
    baseName = "gradle-enterprise-maven-build-validation"

    from(layout.projectDirectory.dir("../scripts/maven")) {
        filter { line: String -> line.replace("/../lib", "/lib") }
        exclude("data/")
    }
    from(layout.projectDirectory.dir("../scripts/")) {
        include("lib/**")
        exclude("lib/gradle")
        exclude("**/*.m4")
        filter { line: String -> line.replace("/../lib", "/lib") }
    }
    from(components) {
        into("lib/maven/")
    }
    into(baseName)
    dependsOn("generateBashCliParsers")
}

tasks.named("assemble") {
    dependsOn("assembleGradleScripts")
    dependsOn("assembleMavenScripts")
}

