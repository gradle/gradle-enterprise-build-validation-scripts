package com.gradle.enterprise;

import com.google.common.base.Strings;
import okhttp3.Authenticator;
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
        System.err.print("Fetching build scan data for " + buildScanUrl);
        var baseUrl = baseUrlFrom(buildScanUrl);
        var apiClient = new ExportApiClient(baseUrl, createAuthenticator(buildScanUrl), customValueKeys);

        var buildScanId = buildScanIdFrom(buildScanUrl);
        var data = apiClient.fetchBuildValidationData(buildScanId);

        System.err.println(", done.");
        return data;
    }

    private Authenticator createAuthenticator(URL buildScanUrl) {
        var accessKey = System.getenv("GRADLE_ENTERPRISE_ACCESS_KEY");
        if(!Strings.isNullOrEmpty(accessKey)) {
            return Authenticators.accessKey(accessKey);
        }

        var username = System.getenv("GRADLE_ENTERPRISE_USERNAME");
        var password = System.getenv("GRADLE_ENTERPRISE_PASSWORD");
        if(!Strings.isNullOrEmpty(username) && !Strings.isNullOrEmpty(password)) {
            return Authenticators.basic(username, password);
        }

        return Authenticators.accessKey(lookupAccessKey(buildScanUrl));
    }

    private String lookupAccessKey(URL buildScan) {
        var accessKeysFile = getGradleUserHomeDirectory().resolve("enterprise/keys.properties");

        if (Files.isRegularFile(accessKeysFile)) {
            try (var in = Files.newBufferedReader(accessKeysFile)) {
                var accessKeys = new Properties();
                accessKeys.load(in);

                if (!accessKeys.containsKey(buildScan.getHost())) {
                    throw new AccessKeyNotFound(buildScan);
                }
                return accessKeys.getProperty(buildScan.getHost());
            } catch (IOException e) {
                throw new AccessKeyNotFound(buildScan, e);
            }
        }
        throw new AccessKeyNotFound(buildScan);
    }

    private Path getGradleUserHomeDirectory() {
        if (Strings.isNullOrEmpty(System.getenv("GRADLE_USER_HOME"))) {
            return Paths.get(System.getProperty("user.home"), ".gradle");
        }
        return Paths.get(System.getenv("GRADLE_USER_HOME"));
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
        System.out.println("Root Project Name,Gradle Enterprise Server,Build Scan,Build Scan ID,Git URL,Git Branch,Git Commit Id,Requested Tasks,Build Outcome");
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
            buildValidationData.getBuildOutcome()
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
