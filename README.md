# Gradle Enterprise build validation scripts

The purpose of the build validation scripts is to assist you in validating that your Gradle or Maven build is in an optimal state in terms of maximizing work avoidance. The validation scripts do not actually modify your build, but they surface what can be improved in your build to avoid unnecessary work in several scenarios.

Each script represents a so-called _experiment_. Each experiment has a very specific focus of what it validates in your build. The experiments are organized in a logical sequence that should be followed diligently to achieve incremental build improvements in an efficient manner. The experiments can be run on a fully unoptimized build, and they can also be run on a build that had already been optimized in the past in order to surface potential regressions.

There are currently five experiments for Gradle and four experiments for Maven. You could also perform these experiments fully manually, but relying on the automation of the validation scripts will be faster, less error-prone, and more reproducible.

> Gradle Enterprise and its Build Scan:tm: service are instrumental to running these validation scripts. You can learn more about Gradle Enterprise at https://gradle.com.

## Usage

The build validation scripts are bundled and documented separately for Gradle and Maven. There are specific instructions on
* how to use the [build validation scripts for Gradle](Gradle.md)
* how to use the [build validation scripts for Maven](Maven.md)

## Building from source

The build validation scripts are available as pre-built, executable Bash scripts. You can also assemble the build validation scripts from source via a Gradle build. Run the following command from the root folder of this GitHub repository.

```bash
./gradlew build
```

Once the build has finished successfully, you can find two .zip files in the build/distributions folder: one .zip file containing the build validation scripts for Gradle and one .zip file containing the build validation scripts for Maven.

If the build fails with _You need the 'autom4te' utility_, then you will need to install 'autoconf' before you can run the build successfully. For example, on macOS with Homebrew, you can install autoconf with `brew install autoconf`.

## License

The Gradle Enterprise build validation scripts are open-source software released under the [Apache 2.0 License][apache-license].

[apache-license]: https://www.apache.org/licenses/LICENSE-2.0.html
