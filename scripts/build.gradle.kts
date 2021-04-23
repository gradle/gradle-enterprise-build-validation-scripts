
plugins {
  id("base")
}

base.archivesBaseName = "gradle-enterprise-experiments"

tasks.register<Zip>("assembleGradleScripts") {
  archiveAppendix.set("for-gradle")

  from(layout.projectDirectory.dir("src/gradle"))
  from(layout.projectDirectory.dir("src/")) {
    include("lib/**")
    exclude("lib/maven")
    exclude("**/*.m4")
  }
  filter { line: String -> line.replace("/../lib","/lib") }
}

tasks.register<Zip>("assembleMavenScripts") {
  archiveAppendix.set("for-maven")

  from(layout.projectDirectory.dir("src/maven")) {
    filter { line: String -> line.replace("/../lib","/lib") }
  }
  from(layout.projectDirectory.dir("src/")) {
    include("lib/**")
    exclude("lib/gradle")
    exclude("**/*.m4")
    filter { line: String -> line.replace("/../lib","/lib") }
  }
  from(rootProject.childProjects.get("capture-build-scans-maven-extension")!!.tasks.getByName("jar")) {
    into("lib/maven/")
  }
}

tasks.named("assemble") {
  dependsOn("assembleGradleScripts")
  dependsOn("assembleMavenScripts")
}

