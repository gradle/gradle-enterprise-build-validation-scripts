package com.gradle.enterprise;

import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Optional;
import java.util.Properties;
import java.util.concurrent.Callable;
import java.util.stream.Collectors;

@Command(
    name = "fetch-build-validation-data",
    mixinStandardHelpOptions = true,
    description = "Fetches data relevant to validating a build from a given build scan."
)
public class FetchBuildValidationData implements Callable<Integer> {

    public static class ExitCode {
        public static final int OK = 0;
    }

    @Parameters(paramLabel = "BUILD_SCAN", description = "The build scans to fetch.", arity = "1..*")
    private List<URL> buildScanUrls;

    @Option(names = {"-u", "--username"}, description = "Specifies the username to use when authenticating with Gradle Enterprise.")
    private String username;

    @Option(names = {"-p", "--password"}, description = "Specifies the password to use when authenticating with Gradle Enterprise.")
    private String password;

    @Option(names = {"-m", "--mapping-file"}, description = "Specifies a file that configures the keys of various custom values.")
    private Optional<Path> customValueMappingFile;

    @Override
    public Integer call() throws Exception {
        var customValueKeys = loadCustomValueKeys(customValueMappingFile);
        var buildValidationData = buildScanUrls.stream()
            .map((URL buildScanUrl) -> fetchBuildValidationData(buildScanUrl, customValueKeys))
            .collect(Collectors.toList());

        printHeader();
        buildValidationData.stream().forEach(this::printRow);

        return ExitCode.OK;
    }

    private BuildValidationData fetchBuildValidationData(URL buildScanUrl, CustomValueKeys customValueKeys) {
        try {
            var accessKey = lookupAccessKey(buildScanUrl);
            if (accessKey.isEmpty()) {
                // TODO do something better here
                throw new RuntimeException("An access key is currently required.");
            }

            var baseUrl = baseUrlFrom(buildScanUrl);
            var apiClient = new ExportApiClient(baseUrl, Authenticators.accessKey(accessKey.get()), customValueKeys);

            var buildScanId = buildScanIdFrom(buildScanUrl);
            return apiClient.fetchBuildValidationData(buildScanId);
        } catch (Exception e) {
            // TODO Yuck!
            throw new RuntimeException(e.getMessage(), e);
        }
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
        return new URL(buildScanUrl.getProtocol() + "://" + buildScanUrl.getHost() + port);
    }

    private String buildScanIdFrom(URL buildScanUrl) {
        var pathSegments = buildScanUrl.getPath().split("/");
        // TODO handle the case where there are no path segments
        return pathSegments[pathSegments.length - 1];
    }

    public void printHeader() {
        System.out.println("Gradle Enterprise Server,Build Scan,Build Scan ID,Git URL,Git Branch,Git Commit Id,Requested Tasks,Build Successful");
    }

    private void printRow(BuildValidationData buildValidationData) {
        System.out.println(String.format("%s,%s,%s,%s,%s,%s,%s,%s",
            buildValidationData.getGradleEnterpriseServerUrl(),
            buildValidationData.getBuildScanUrl(),
            buildValidationData.getBuildScanId(),
            buildValidationData.getGitUrl(),
            buildValidationData.getGitBranch(),
            buildValidationData.getGitCommitId(),
            String.join(" ", buildValidationData.getRequestedTasks()),
            buildValidationData.getBuildSuccessful()
        ));
    }

    private CustomValueKeys loadCustomValueKeys(Optional<Path> customValueMappingFile) throws IOException {
        if(customValueMappingFile.isEmpty()) {
            return CustomValueKeys.DEFAULT;
        } else {
            return CustomValueKeys.loadFromFile(customValueMappingFile.get());
        }
    }

    public static void main(String[] args) {
        int exitCode = new CommandLine(new FetchBuildValidationData()).execute(args);
        System.exit(exitCode);
    }
}
