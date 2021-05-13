package com.gradle.enterprise;

import picocli.CommandLine;
import picocli.CommandLine.ArgGroup;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

import javax.naming.AuthenticationException;
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

    @ArgGroup(exclusive = true)
    private AuthenticationArgs authenticationArgs;

    private static class AuthenticationArgs {
        @Option(names = {"-A", "--access-key"}, description = "Specifies the access key to use when authenticating with Gradle Enterprise.")
        private String accessKey;

        @ArgGroup(exclusive = false)
        private UsernamePassword usernamePassword;

        private static class UsernamePassword {
            @Option(names = {"-U", "--username"}, required = true, description = "Specifies the username to use when authenticating with Gradle Enterprise.")
            private String username;

            @Option(names = {"-P", "--password"}, required = true, description = "Specifies the password to use when authenticating with Gradle Enterprise.")
            private String password;
        }
    }

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
        var baseUrl = baseUrlFrom(buildScanUrl);
        var apiClient = new ExportApiClient(baseUrl, createAuthenticator(buildScanUrl), customValueKeys);

        var buildScanId = buildScanIdFrom(buildScanUrl);
        return apiClient.fetchBuildValidationData(buildScanId);
    }

    private okhttp3.Authenticator createAuthenticator(URL buildScanUrl) {
        if(authenticationArgs != null && authenticationArgs.usernamePassword != null) {
            return Authenticators.basic(authenticationArgs.usernamePassword.username, authenticationArgs.usernamePassword.password);
        }
        else if(authenticationArgs != null && authenticationArgs.accessKey != null) {
            return Authenticators.accessKey(authenticationArgs.accessKey);
        }
        return Authenticators.accessKey(lookupAccessKey(buildScanUrl));
    }

    private String lookupAccessKey(URL buildScan) {
        var accessKeysFile = Paths.get(System.getProperty("user.home"), ".gradle/enterprise/keys.properties");

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
