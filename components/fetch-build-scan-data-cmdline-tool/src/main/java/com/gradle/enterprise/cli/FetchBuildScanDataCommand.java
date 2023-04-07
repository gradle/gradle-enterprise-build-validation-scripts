package com.gradle.enterprise.cli;

import com.gradle.enterprise.api.client.FailedRequestException;
import com.gradle.enterprise.api.client.GradleEnterpriseApiClient;
import com.gradle.enterprise.model.BuildScanData;
import com.gradle.enterprise.model.CustomValueNames;
import com.gradle.enterprise.model.NumberedBuildScan;
import com.gradle.enterprise.network.NetworkSettingsConfigurator;
import org.jetbrains.annotations.NotNull;
import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

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
public class FetchBuildScanDataCommand implements Callable<Integer> {

    private final CommandLine.Help.ColorScheme colorScheme;
    private ConsoleLogger logger;

    public FetchBuildScanDataCommand(CommandLine.Help.ColorScheme colorScheme) {
        this.colorScheme = colorScheme;
    }

    public static class ExitCode {
        public static final int OK = 0;
    }

    @Parameters(paramLabel = "BUILD_SCAN", description = "The build scans to fetch. Each build scan URL is preceded by the run num that produced the build scan.", arity = "1..*")
    private List<String> runNumsAndBuildScanUrls;

    @Option(names = {"--mapping-file"}, description = "Specifies a mapping file that configures the names used to fetch important custom values.")
    private Optional<Path> customValuesMappingFile;

    @Option(names = {"--network-settings-file"}, description = "Specifies a file that configures HTTP(S) Proxy and SSL settings.")
    private Optional<Path> networkSettingsFile;

    @Option(names = {"--debug"}, description = "Prints additional debugging information while running.")
    private boolean debug;

    @Option(names = {"--brief-logging"}, description = "Only log a short message about fetching build scan data and when it completes.")
    private boolean briefLogging;

    @Override
    public Integer call() {
        // Use System.err for logging since we're going to write out the CSV to System.out
        logger = new ConsoleLogger(System.err, colorScheme, debug);

        networkSettingsFile.ifPresent(settingsFile -> NetworkSettingsConfigurator.configureNetworkSettings(settingsFile, logger));

        List<NumberedBuildScan> buildScans = NumberedBuildScan.parse(runNumsAndBuildScanUrls);
        CustomValueNames customValueKeys = customValuesMappingFile
            .map(CustomValueNames::loadFromFile)
            .orElse(CustomValueNames.DEFAULT);

        logStartFetchingAllBuildScanData();
        List<BuildScanData> buildScanData = fetchBuildScanData(buildScans, customValueKeys);

        logFinishedFetchingAllBuildScanData();
        logFetchResults(buildScanData, customValueKeys);

        BuildInsightsPrinter.printInsights(buildScanData);

        return ExitCode.OK;
    }

    @NotNull
    private List<BuildScanData> fetchBuildScanData(List<NumberedBuildScan> buildScans, CustomValueNames customValueKeys) {
        return buildScans.stream()
            .parallel()
            .map(buildScan -> fetchBuildScanData(buildScan, customValueKeys))
            .collect(Collectors.toList());
    }

    private BuildScanData fetchBuildScanData(NumberedBuildScan buildScan, CustomValueNames customValueNames) {
        logStartFetchingBuildScanData(buildScan);
        try {
            GradleEnterpriseApiClient apiClient = new GradleEnterpriseApiClient(buildScan.baseUrl(), customValueNames, logger);
            BuildScanData data = apiClient.fetchBuildScanData(buildScan);

            logFinishedFetchingBuildScanData(buildScan);
            return data;
        } catch (RuntimeException e) {
            logException(e);
            return new BuildScanData(
                buildScan.runNum(),
                "",
                buildScan.buildScanId(),
                buildScan.baseUrl(),
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

    private void logException(RuntimeException e) {
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
        e.getResponseBody().ifPresent(responseBody -> {
            logger.error("Response body:");
            logger.error(responseBody);
            logger.error("--------------------------");
        });
    }

    private void logStartFetchingAllBuildScanData() {
        if (briefLogging) {
            logger.info("Fetching Build Scan data for all builds");
        }
    }

    private void logFinishedFetchingAllBuildScanData() {
        if (briefLogging) {
            logger.info("Finished fetching Build Scan data for all builds");
        }
    }

    private void logStartFetchingBuildScanData(NumberedBuildScan buildScan) {
        if (!briefLogging) {
            logger.info("Fetching Build Scan data for %s build", toOrdinal(buildScan.runNum()));
        }
    }

    private void logFinishedFetchingBuildScanData(NumberedBuildScan buildScan) {
        if (!briefLogging) {
            logger.info("Finished fetching Build Scan data for %s build", toOrdinal(buildScan.runNum()));
        }
    }

    private void logFetchResults(List<BuildScanData> buildScanData, CustomValueNames customValueKeys) {
        if (!briefLogging) {
            buildScanData.forEach(validationData -> {
                logger.info("");

                logFetchResultFor(validationData.runNum(), "Git repository", customValueKeys.getGitRepositoryKey(), validationData.isGitUrlFound());
                logFetchResultFor(validationData.runNum(), "Git branch", customValueKeys.getGitBranchKey(), validationData.isGitBranchFound());
                logFetchResultFor(validationData.runNum(), "Git commit id", customValueKeys.getGitCommitIdKey(), validationData.isGitCommitIdFound());
            });
        }
    }

    private void logFetchResultFor(int runNum, String property, String customValueKey, boolean found) {
        logger.info(
            "%s %s from custom value with name '%s' for %s build",
            found ? "Found": "Did not find", property, customValueKey, toOrdinal(runNum)
        );
    }

    private static String toOrdinal(int i) {
        switch(i + 1) {
            case 1: return "first";
            case 2: return "second";
            case 3: return "third";
            default: return (i + 1) + "th";
        }
    }
}
