import org.gradle.api.DefaultTask
import org.gradle.api.file.ConfigurableFileTree
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.ProjectLayout
import org.gradle.api.model.ObjectFactory
import org.gradle.api.provider.Property
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import org.gradle.process.ExecOperations
import javax.inject.Inject

@CacheableTask
abstract class ApplyArgbash @Inject constructor(
    private val layout: ProjectLayout,
    private val objects: ObjectFactory,
    private val execOperations: ExecOperations
) : DefaultTask() {

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val scriptTemplates: Property<ConfigurableFileTree>

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val supportingTemplates: Property<ConfigurableFileTree>

    @get:Input
    @get:Optional
    val argbashVersion: Property<String> = objects.property<String>(String::class.java).apply {
        set("2.10.0")
    }

    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    val argbashHome: DirectoryProperty = objects.directoryProperty().apply {
        set(layout.buildDirectory.dir("argbash/argbash-${argbashVersion.get()}/"))
    }

    @get:OutputDirectory
    val outputDir: DirectoryProperty = objects.directoryProperty().apply {
      set(layout.buildDirectory.get().dir("generated/scripts"))
    }

    @TaskAction
    fun applyArgbash() {
        val argbash = argbashHome.get().file("bin/argbash").asFile
        scriptTemplates.get().visit {
            if(!it.isDirectory) {
                val relPath = it.relativePath.parent.pathString
                val basename = it.file.nameWithoutExtension
                val outputFile = outputDir.get().file("${relPath}/${basename}.sh").asFile
                outputFile.parentFile.mkdirs()

                logger.info("Applying argbash to $it.file")
                execOperations.exec { execSpec ->
                    execSpec.commandLine(argbash, it.file, "-o", outputFile)
                }
            }
        }
    }
}
