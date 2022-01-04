# Gradle Enterprise build validation scripts

The purpose of the build validation scripts is to assist you in validating that your Gradle or Maven build is in an optimal state in terms of maximizing work avoidance. The validation scripts do not actually modify your build, but they surface what can be improved in your build to avoid unnecessary work in several scenarios.

Each script represents a so-called _experiment_. Each experiment has a very specific focus of what it validates in your build. The experiments are organized in a logical sequence that should be followed diligently to achieve incremental build improvements in an efficient manner. The experiments can be run on a fully unoptimized build, and they can also be run on a build that had already been optimized in the past in order to surface potential regressions.

There are currently [five experiments for Gradle](GRADLE.md) and [four experiments for Maven](MAVEN.md). You could also perform these experiments fully manually, but relying on the automation of the validation scripts will be faster, less error-prone, and more reproducible.

> Gradle Enterprise and its Build Scan:tm: service are instrumental to running these validation scripts. You can learn more about Gradle Enterprise at https://gradle.com.

## Gradle

You can find detailed instructions on how to use the build validation scripts for Gradle [here](GRADLE.md).

## Maven

You can find detailed instructions on how to use the build validation scripts for Maven [here](MAVEN.md).

## License

The Gradle Enterprise build validation scripts are open-source software released under the [Apache 2.0 License][apache-license].

[apache-license]: https://www.apache.org/licenses/LICENSE-2.0.html
