> [!IMPORTANT]
> The distributions of the Develocity Build Validation Scripts prefixed with `gradle-enterprise` are deprecated and will be removed in a future release. Migrate to the distributions prefixed with `develocity` instead.

- [NEW] All user-facing text is updated to use Develocity naming
- [NEW] Distributions prefixed with `develocity` are available
- [NEW] Command line arguments `--develocity-server` and `--enable-develocity` are available
- [FIX] Gradle builds are configured using the legacy Gradle Enterprise API resulting in deprecation warnings
- [FIX] Enabling Develocity fails for builds that already apply the Develocity plugin
