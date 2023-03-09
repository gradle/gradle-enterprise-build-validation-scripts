package com.gradle.enterprise.cli;

import com.gradle.enterprise.api.client.FailedRequestException;
import com.gradle.enterprise.api.client.GradleEnterpriseApiClient;
import com.gradle.enterprise.model.Build;
import com.gradle.enterprise.model.BuildValidationData;
import com.gradle.enterprise.model.CustomValueNames;
import com.gradle.enterprise.network.NetworkSettingsConfigurator;
import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.file.Path;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.Callable;
import java.util.stream.Collectors;

@Command(
    name = "fetch-build-scan-data-cmdline-tool",
    mixinStandardHelpOptions = true,
    description = "Fetches data relevant to build validation from the given build scans."
)
public class FetchBuildValidationDataCommand implements Callable<Integer> {

    private final CommandLine.Help.ColorScheme colorScheme;
    private ConsoleLogger logger;

    public FetchBuildValidationDataCommand(CommandLine.Help.ColorScheme colorScheme) {
        this.colorScheme = colorScheme;
    }

    public static class ExitCode {
        public static final int OK = 0;
    }

    @Parameters(paramLabel = "BUILD_SCAN", description = "The build scans to fetch. Each build scan URL is preceeded by the run num that produced the build scan.", arity = "1..*")
    private List<String> runNumsAndBuildScanUrls;

    @Option(names = {"--mapping-file"}, description = "Specifies a mapping file that configures the keys used to fetch important custom values.")
    private Optional<Path> customValueMappingFile;

    @Option(names = {"--network-settings-file"}, description = "Specifies a file that configures HTTP(S) Proxy and SSL settings.")
    private Optional<Path> networkSettingsFile;

    @Option(names = {"--debug"}, description = "Prints additional debugging information while running.")
    private boolean debug;

    @Option(names = {"--brief-logging"}, description = "Only log a short message about fetching build scan data and when it completes.")
    private boolean briefLogging;

    private boolean someScansFailedToFetch;

    @Override
    public Integer call() throws Exception {
        List<Build> builds = buildsFrom(runNumsAndBuildScanUrls);
        // Use System.err for logging since we're going to write out the CSV to System.out
        logger = new ConsoleLogger(System.err, colorScheme, debug);

        networkSettingsFile.ifPresent(settingsFile -> NetworkSettingsConfigurator.configureNetworkSettings(settingsFile, logger));

        CustomValueNames customValueKeys = loadCustomValueKeys(customValueMappingFile);

        logStartFetchingBuildScans();
        List<BuildValidationData> buildValidationData = builds.stream()
            .map(build -> fetchBuildScanData(build.runNum(), build.buildScanUrl(), customValueKeys))
            .collect(Collectors.toList());

        logFinishedFetchingBuildScans();
        logFetchResults(buildValidationData, customValueKeys);

        printHeader();
        buildValidationData.forEach(this::printRow);

        return ExitCode.OK;
    }

    private BuildValidationData fetchBuildScanData(int runNum, URL buildScanUrl, CustomValueNames customValueNames) {
        logStartFetchingBuildScan(runNum);
        URL baseUrl = null;
        String buildScanId = "";
        try {
            baseUrl = baseUrlFrom(buildScanUrl);
            buildScanId = buildScanIdFrom(buildScanUrl);

            GradleEnterpriseApiClient apiClient = new GradleEnterpriseApiClient(baseUrl, customValueNames, logger);
            BuildValidationData data = apiClient.fetchBuildValidationData(runNum, buildScanId);

            logFinishedFetchingBuildScan();
            return data;
        } catch (RuntimeException e) {
            printException(e);
            return new BuildValidationData(
                runNum,
                "",
                buildScanId,
                baseUrl,
                "",
                "",
                "",
                Collections.emptyList(),
                "",
                null,
                Collections.emptyMap(),
                null,
                null);
        }
    }

    private void printException(RuntimeException e) {
        someScansFailedToFetch = true;
        if (logger.isDebugEnabled()) {
            logger.error(e);
            if (e instanceof FailedRequestException) {
                printFailedRequest((FailedRequestException) e);
            }
        } else {
            logger.error("ERROR: " + e.getMessage());
        }
    }

    private void printFailedRequest(FailedRequestException e) {
        logger.error("Response status code: " + e.httpStatusCode());
        if (e.getResponseBody() != null) {
            logger.error("Response body:");
            logger.error(e.getResponseBody());
            logger.error("--------------------------");
        }
    }

    private String runNumToOrdinal(int i) {
        switch(i + 1) {
            case 1: return "first";
            case 2: return "second";
            case 3: return "third";
            case 4: return "fourth";
            case 5: return "fifth";
            case 6: return "sixth";
            case 7: return "seventh";
            case 8: return "eighth";
            case 9: return "ninth";
            case 10: return "tenth";
            default: return String.valueOf(i);
        }
    }

    private List<Build> buildsFrom(List<String> runNumsAndBuildScanUrls) {
        return runNumsAndBuildScanUrls.stream().map(this::buildFrom)
            .collect(Collectors.toList());
    }

    private Build buildFrom(String runNumAndBuildScanUrl) {
        String[] parts = runNumAndBuildScanUrl.split(",");
        String runNum = parts[0];
        String buildScanUrl = parts[1];
        try {
            return new Build(Integer.parseInt(runNum), new URL(buildScanUrl));
        } catch (MalformedURLException e) {
            throw new BadBuildScanUrlException(buildScanUrl, e);
        }
    }

    private URL baseUrlFrom(URL buildScanUrl) {
        try {
            String port = (buildScanUrl.getPort() != -1) ? ":" + buildScanUrl.getPort() : "";
            return new URL(buildScanUrl.getProtocol() + "://" + buildScanUrl.getHost() + port);
        } catch (MalformedURLException e) {
            // It is highly unlikely this exception will ever be thrown. If it is thrown, then it is likely due to a
            // programming mistake (._.)
            throw new BadBuildScanUrlException(buildScanUrl, e);
        }
    }

    private String buildScanIdFrom(URL buildScanUrl) {
        String[] pathSegments = buildScanUrl.getPath().split("/");

        if (pathSegments.length == 0) {
            throw new BadBuildScanUrlException(buildScanUrl);
        }
        return pathSegments[pathSegments.length - 1];
    }

    private void logStartFetchingBuildScans() {
        if (briefLogging) {
            logger.infoNoNewline("Fetching build scan data");
            if (logger.isDebugEnabled()) {
                logger.info("");
            }
        }
    }

    private void logFinishedFetchingBuildScans() {
        if (briefLogging) {
            if (logger.isDebugEnabled() || someScansFailedToFetch) {
                logger.info("done.");
            } else {
                logger.info(", done.");
            }
        }
    }

    private void logFinishedFetchingBuildScan() {
        if (!briefLogging) {
            if (logger.isDebugEnabled() || someScansFailedToFetch) {
                logger.info("done.");
            } else {
                logger.info(", done.");
            }
        }
    }

    private void logStartFetchingBuildScan(int index) {
        if (!briefLogging) {
            logger.infoNoNewline(fetchingMessageFor(index));
            if (logger.isDebugEnabled()) {
                logger.info("");
            }
        }
    }

    private String fetchingMessageFor(int runNum) {
        if (runNumsAndBuildScanUrls.size() <= 10) {
            return String.format("Fetching build scan data for the %s build", runNumToOrdinal(runNum));
        }
        return String.format("Fetching build scan data for build %s", runNum + 1);
    }

    private void logFetchResults(List<BuildValidationData> buildValidationData, CustomValueNames customValueKeys) {
        if (!briefLogging) {
            buildValidationData.forEach(validationData -> {
                logger.info("");

                logFetchResultFor(validationData.runNum(), "Git repository", customValueKeys.getGitRepositoryKey(), validationData.isGitUrlFound());
                logFetchResultFor(validationData.runNum(), "Git branch", customValueKeys.getGitBranchKey(), validationData.isGitBranchFound());
                logFetchResultFor(validationData.runNum(), "Git commit id", customValueKeys.getGitCommitIdKey(), validationData.isGitCommitIdFound());
            });
        }
    }

    private void logFetchResultFor(int index, String property, String customValueKey, boolean found) {
        String ordinal = runNumToOrdinal(index);
        logger.info("Looking up %s from custom value with name '%s' from the %s build scan, %s.", property, customValueKey, ordinal, found ? "found": "not found");
    }

    public void printHeader() {
        List<String> labels = Fields.ordered().map(f -> f.label).collect(Collectors.toList());
        System.out.println(String.join(",", labels));
    }

    private void printRow(BuildValidationData buildValidationData) {
        List<String> values = Fields.ordered().map(f -> f.value.apply(buildValidationData)).collect(Collectors.toList());
        System.out.println(String.join(",", values));
    }

    private CustomValueNames loadCustomValueKeys(Optional<Path> customValueMappingFile) throws IOException {
        if (customValueMappingFile.isPresent()) {
            return CustomValueNames.loadFromFile(customValueMappingFile.get());
        } else {
            return CustomValueNames.DEFAULT;
        }
    }
}
