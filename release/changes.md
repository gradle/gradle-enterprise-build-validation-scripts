> [!IMPORTANT]
> The distributions of the Develocity Build Validation Scripts prefixed with `gradle-enterprise` are deprecated and will be removed in a future release. Migrate to the distributions prefixed with `develocity` instead.

- [NEW] All user-facing text is updated to use Develocity naming
- [NEW] Add distributions prefixed with `develocity` and deprecate those prefixed with `gradle-enterprise`
- [NEW] Add command line argument `--develocity-server` and deprecate `--gradle-enterprise-server`
- [NEW] Add command line argument `--enable-develocity`  and deprecate `--enable-gradle-enterprise`
- [FIX] Gradle builds are configured using the legacy Gradle Enterprise API resulting in deprecation warnings
- [FIX] Enabling Develocity fails for builds that already apply the Develocity plugin
