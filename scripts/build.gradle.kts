import de.undercouch.gradle.tasks.download.Download

plugins {
    id("base")
    id("de.undercouch.download") version "4.1.1"
}

base.archivesBaseName = "gradle-enterprise-experiments"

val argbashVersion by extra("2.10.0")

tasks.register<Download>("downloadArgbash") {
    src("https://github.com/matejak/argbash/archive/refs/tags/${argbashVersion}.zip")
    dest(file("${buildDir}/argbash/argbash-${argbashVersion}.zip"))
    onlyIfModified(true)
}

tasks.register<Copy>("unpackArgbash") {
    from(zipTree(tasks.getByName("downloadArgbash").outputs.files.singleFile))
    into(layout.buildDirectory.dir("argbash"))
    dependsOn("downloadArgbash")
}

tasks.register("applyArgbash") {
    val scripts = fileTree("src") {
        include("**/parsing.sh")
    }
    inputs.files(scripts)
        .withPropertyName("scripts")
        .withPathSensitivity(PathSensitivity.RELATIVE)
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
    archiveAppendix.set("for-gradle")

    from(layout.projectDirectory.dir("src/gradle"))
    from(layout.projectDirectory.dir("src/")) {
        include("lib/**")
        exclude("lib/maven")
        exclude("**/*.m4")
    }
    filter { line: String -> line.replace("/../lib", "/lib") }
    dependsOn("applyArgbash")
}

tasks.register<Zip>("assembleMavenScripts") {
    archiveAppendix.set("for-maven")

    from(layout.projectDirectory.dir("src/maven")) {
        filter { line: String -> line.replace("/../lib", "/lib") }
    }
    from(layout.projectDirectory.dir("src/")) {
        include("lib/**")
        exclude("lib/gradle")
        exclude("**/*.m4")
        filter { line: String -> line.replace("/../lib", "/lib") }
    }
    from(rootProject.childProjects.get("capture-build-scans-maven-extension")!!.tasks.getByName("jar")) {
        into("lib/maven/")
    }
    dependsOn("applyArgbash")
}

tasks.named("assemble") {
    dependsOn("assembleGradleScripts")
    dependsOn("assembleMavenScripts")
}

