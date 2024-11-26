/*
 * Transforms usages of 'System.getProperty' in the Develocity injection script
 * to 'gradle.startParameter'. This is required because 'System.getProperty'
 * cannot be used to reliably read system properties from init scripts in Gradle
 * 7.0.2 and earlier.
*/
class TransformDevelocityInjectionScript : (String) -> String {

    override fun invoke(content: String): String {
        return content
            .replace("static getInputParam(String name) {", "def getInputParam = { String name ->")
            .replace("System.getProperty(name)", "gradle.startParameter.systemPropertiesArgs[name]")

            // The 'getInputParam' method is no longer static so it must be redefined within the
            // 'enableDevelocityInjection' method
            .replace("void enableDevelocityInjection() {", """
            void enableDevelocityInjection() {
                def getInputParam = { String name ->
                    def ENV_VAR_PREFIX = ''
                    def envVarName = ENV_VAR_PREFIX + name.toUpperCase().replace('.', '_').replace('-', '_')
                    return gradle.startParameter.systemPropertiesArgs[name] ?: System.getenv(envVarName)
                }

        """.trimIndent())
    }

}
