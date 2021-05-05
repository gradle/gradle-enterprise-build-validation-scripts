package com.gradle.enterprise;

import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Optional;
import java.util.Properties;
import java.util.concurrent.Callable;

@Command(
    name = "fetch-build-validation-data",
    mixinStandardHelpOptions = true,
    description = "Fetches data relevant to validating a build from a given build scan."
)
public class FetchBuildValidationData implements Callable<Integer> {

    public static class ExitCode {
        public static final int OK = 0;
    }

    @Parameters(index = "0", description = "The build scan to fetch.")
    private URL buildScan;

    @Option(names = { "-u", "--username"}, description = "Specifies the username to use when authenticating with Gradle Enterprise.")
    private String username;

    @Option(names = { "-p", "--password"}, description = "Specifies the password to use when authenticating with Gradle Enterprise.")
    private String password;

    @Override
    public Integer call() throws Exception {
        var accessKey = lookupAccessKey(buildScan);
        if (accessKey.isEmpty()) {
            System.out.println("An access key is currently required.");
            return 1;
        }

        var baseUrl = baseUrlFrom(buildScan);
        var buildScanId = buildScanIdFrom(buildScan);

        var apiClient = new ExportApiClient(baseUrl, Authenticators.accessKey(accessKey.get()));
        var buildValidationData = apiClient.fetchBuildValidationData(buildScanId);

        System.out.println("Gradle Enterprise Server\tBuild Scan ID\tGit Commit Id\tRequested Tasks\tBuild Successful");
        System.out.println(String.format("%s\t%s\t%s\t%s\t%s",
            baseUrl,
            buildScanId,
            buildValidationData.getCommitId(),
            String.join(" ", buildValidationData.getRequestedTasks()),
            buildValidationData.getBuildSuccessful()
        ));

        return ExitCode.OK;
    }

    public static void main(String[] args) {
        int exitCode = new CommandLine(new FetchBuildValidationData()).execute(args);
        System.exit(exitCode);
    }

    private Optional<String> lookupAccessKey(URL buildScan) throws IOException {
        var accessKeysFile = Paths.get(System.getProperty("user.home"), ".gradle/enterprise/keys.properties");

        try (var in = Files.newBufferedReader(accessKeysFile)) {
            var accessKeys = new Properties();
            accessKeys.load(in);
            return Optional.of(accessKeys.getProperty(buildScan.getHost()));
        }
    }

    private URL baseUrlFrom(URL buildScanUrl) throws MalformedURLException {
        var port = (buildScanUrl.getPort() != -1) ? ":" + buildScanUrl.getPort() : "";
        return new URL(buildScanUrl.getProtocol() + "://" + buildScanUrl.getHost() +  port);
    }

    private String buildScanIdFrom(URL buildScanUrl) {
        var pathSegments = buildScanUrl.getPath().split("/");
        // TODO handle the case where there are no path segments
        return pathSegments[pathSegments.length -1];
    }
}
