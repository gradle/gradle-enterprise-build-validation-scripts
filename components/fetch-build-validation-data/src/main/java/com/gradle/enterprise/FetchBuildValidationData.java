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
    description = "Fetches data relevant to build validation from the given build scans."
)
public class FetchBuildValidationData implements Callable<Integer> {

    public static class ExitCode {
        public static final int OK = 0;
    }

    @Parameters(paramLabel = "BUILD_SCAN", description = "The build scans to fetch.", arity = "1..*")
    private List<URL> buildScanUrls;

    @Option(names = {"-u", "--username"}, description = "Specifies the username to use when authenticating with Gradle Enterprise. If provided, HTTP Basic authentication will be used.")
    private String username;

    @Option(names = {"-p", "--password"}, description = "Specifies the password to use when authenticating with Gradle Enterprise. If provided, HTTP Basic authentication will be used.")
    private String password;

    @Option(names = {"-m", "--mapping-file"}, description = "Specifies a mapping file that configures the keys used to fetch important custom values.")
    private Optional<Path> customValueMappingFile;

    @Option(names = {"--debug"}, description = "Prints additional debugging information while running.")
    private Boolean debug;

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
        var accessKey = lookupAccessKey(buildScanUrl);
        if (accessKey.isEmpty()) {
            // TODO do something better here
            throw new RuntimeException("An access key is currently required.");
        }

        var baseUrl = baseUrlFrom(buildScanUrl);
        var apiClient = new ExportApiClient(baseUrl, Authenticators.accessKey(accessKey.get()), customValueKeys);

        var buildScanId = buildScanIdFrom(buildScanUrl);
        return apiClient.fetchBuildValidationData(buildScanId);
    }

    private Optional<String> lookupAccessKey(URL buildScan) {
        var accessKeysFile = Paths.get(System.getProperty("user.home"), ".gradle/enterprise/keys.properties");

        if (Files.isRegularFile(accessKeysFile)) {
            try (var in = Files.newBufferedReader(accessKeysFile)) {
                var accessKeys = new Properties();
                accessKeys.load(in);
                return Optional.of(accessKeys.getProperty(buildScan.getHost()));
            } catch (IOException e) {
                // TODO Is there a better way to print a warning?
                System.err.println(String.format("WARNING: Unable to read %s: %s", accessKeysFile, e.getMessage()));
                return Optional.empty();
            }
        } else {
            // TODO Print a warning here?
            return Optional.empty();
        }
    }

    private URL baseUrlFrom(URL buildScanUrl) {
        try {
            var port = (buildScanUrl.getPort() != -1) ? ":" + buildScanUrl.getPort() : "";
            return new URL(buildScanUrl.getProtocol() + "://" + buildScanUrl.getHost() + port);
        } catch (MalformedURLException e) {
            // It is highly unlikely this exception will ever be thrown. If it is thrown, then it is likely due to a
            // programming mistake (._.)
            throw new BadBuildScanUrl(buildScanUrl, e);
        }
    }

    private String buildScanIdFrom(URL buildScanUrl) {
        var pathSegments = buildScanUrl.getPath().split("/");

        if (pathSegments.length == 0) {
            throw new BadBuildScanUrl(buildScanUrl);
        }
        return pathSegments[pathSegments.length - 1];
    }

    public void printHeader() {
        System.out.println("Root Project Name,Gradle Enterprise Server,Build Scan,Build Scan ID,Git URL,Git Branch,Git Commit Id,Requested Tasks,Build Successful");
    }

    private void printRow(BuildValidationData buildValidationData) {
        System.out.println(String.format("%s,%s,%s,%s,%s,%s,%s,%s,%s",
            buildValidationData.getRootProjectName(),
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
        if (customValueMappingFile.isEmpty()) {
            return CustomValueKeys.DEFAULT;
        } else {
            return CustomValueKeys.loadFromFile(customValueMappingFile.get());
        }
    }

    public static void main(String[] args) {
        int exitCode = new CommandLine(new FetchBuildValidationData())
            .setExecutionExceptionHandler(new PrintExceptionHandler())
            .execute(args);
        System.exit(exitCode);
    }
}
