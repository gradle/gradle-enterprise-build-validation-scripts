
plugins {
  id("base")
}

tasks.register<Zip>("assembleGradleScripts") {
  archiveAppendix.set("for-gradle")

  from(layout.projectDirectory.dir("src/gradle"))
  from(layout.projectDirectory.dir("src/")) {
    include("lib/**")
    exclude("lib/maven")
    exclude("**/*.m4")
  }
}

tasks.register<Zip>("assembleMavenScripts") {
  archiveAppendix.set("for-maven")

  from(layout.projectDirectory.dir("src/maven"))
  from(layout.projectDirectory.dir("src/")) {
    include("lib/**")
    exclude("lib/gradle")
    exclude("**/*.m4")
  }
}

tasks.named("assemble") {
  dependsOn("assembleGradleScripts")
  dependsOn("assembleMavenScripts")
}

