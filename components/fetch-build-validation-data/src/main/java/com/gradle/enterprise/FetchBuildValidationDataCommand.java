package com.gradle.enterprise;

import com.gradle.enterprise.export_api.client.Authenticators;
import com.gradle.enterprise.export_api.client.ExportApiClient;
import com.gradle.enterprise.export_api.client.FailedRequestException;
import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.file.Path;
import java.util.*;
import java.util.concurrent.Callable;

@Command(
    name = "fetch-build-validation-data",
    mixinStandardHelpOptions = true,
    description = "Fetches data relevant to build validation from the given build scans."
)
public class FetchBuildValidationDataCommand implements Callable<Integer> {

    private final CommandLine.Help.ColorScheme colorScheme;

    public FetchBuildValidationDataCommand(CommandLine.Help.ColorScheme colorScheme) {
        this.colorScheme = colorScheme;
    }

    public static class ExitCode {
        public static final int OK = 0;
    }

    @Parameters(paramLabel = "BUILD_SCAN", description = "The build scans to fetch.", arity = "1..*")
    private List<URL> buildScanUrls;

    @Option(names = {"-m", "--mapping-file"}, description = "Specifies a mapping file that configures the keys used to fetch important custom values.")
    private Optional<Path> customValueMappingFile;

    @Option(names = {"--debug"}, description = "Prints additional debugging information while running.")
    private boolean debug;

    @Override
    public Integer call() throws Exception {
        var customValueKeys = loadCustomValueKeys(customValueMappingFile);

        var buildValidationData = new ArrayList<BuildValidationData>();
        for (int i = 0; i < buildScanUrls.size(); i++) {
            BuildValidationData validationData = fetchBuildValidationData(i, buildScanUrls.get(i), customValueKeys);
            buildValidationData.add(validationData);
        }

        printHeader();
        buildValidationData.forEach(this::printRow);

        return ExitCode.OK;
    }

    private BuildValidationData fetchBuildValidationData(int index, URL buildScanUrl, CustomValueNames customValueNames) {
        System.err.print(fetchingMessageFor(index));
        URL baseUrl = null;
        String buildScanId = "";
        try {
            baseUrl = baseUrlFrom(buildScanUrl);
            buildScanId = buildScanIdFrom(buildScanUrl);

            var apiClient = new ExportApiClient(baseUrl, Authenticators.createForUrl(buildScanUrl), customValueNames);
            var data = apiClient.fetchBuildValidationData(buildScanId);

            System.err.println(", done.");
            return data;
        } catch (RuntimeException e) {
            printException(e);
            return new BuildValidationData(
                "",
                buildScanId,
                baseUrl,
                "",
                "",
                "",
                Collections.emptyList(),
                "",
                null);
        }
    }

    private void printException(RuntimeException e) {
        if (debug) {
            System.err.println(colorScheme.errorText(" " + colorScheme.stackTraceText(e)));
            if (e instanceof FailedRequestException) {
                printFailedRequestDetails((FailedRequestException) e);
            }
        } else {
            System.err.println(colorScheme.errorText(" ERROR: " + e.getMessage()));
        }
    }

    private void printFailedRequestDetails(FailedRequestException e) {
        System.err.println(colorScheme.errorText("Request " + e.getRequest()));
        System.err.println(colorScheme.errorText("--------------------------"));
        if(e.getRequest().body() != null) {
            System.err.println(colorScheme.errorText(e.getRequest().body().toString()));
            System.err.println(colorScheme.errorText("--------------------------"));
        }
        System.err.println(colorScheme.errorText("Response " + e.getResponse()));
        System.err.println(colorScheme.errorText("--------------------------"));
        if(e.getResponseBody() != null) {
            System.err.println("Response body:");
            System.err.println(colorScheme.errorText(e.getResponseBody()));
            System.err.println(colorScheme.errorText("--------------------------"));
        }
    }

    private String fetchingMessageFor(int index) {
        if (buildScanUrls.size() <= 10) {
            return String.format("Fetching build scan data for the %s build", buildScanIndexToOrdinal(index));
        }
        return String.format("Fetching build scan data for build %s", index + 1);
    }

    private String buildScanIndexToOrdinal(int i) {
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

    private URL baseUrlFrom(URL buildScanUrl) {
        try {
            var port = (buildScanUrl.getPort() != -1) ? ":" + buildScanUrl.getPort() : "";
            return new URL(buildScanUrl.getProtocol() + "://" + buildScanUrl.getHost() + port);
        } catch (MalformedURLException e) {
            // It is highly unlikely this exception will ever be thrown. If it is thrown, then it is likely due to a
            // programming mistake (._.)
            throw new BadBuildScanUrlException(buildScanUrl, e);
        }
    }

    private String buildScanIdFrom(URL buildScanUrl) {
        var pathSegments = buildScanUrl.getPath().split("/");

        if (pathSegments.length == 0) {
            throw new BadBuildScanUrlException(buildScanUrl);
        }
        return pathSegments[pathSegments.length - 1];
    }

    public void printHeader() {
        System.out.println("Root Project Name,Gradle Enterprise Server,Build Scan,Build Scan ID,Git URL,Git Branch,Git Commit Id,Requested Tasks,Build Outcome,Remote Build Cache URL,Remote Build Cache Shard");
    }

    private void printRow(BuildValidationData buildValidationData) {
        System.out.printf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s%n",
            buildValidationData.getRootProjectName(),
            toStringSafely(buildValidationData.getGradleEnterpriseServerUrl()),
            toStringSafely(buildValidationData.getBuildScanUrl()),
            buildValidationData.getBuildScanId(),
            buildValidationData.getGitUrl(),
            buildValidationData.getGitBranch(),
            buildValidationData.getGitCommitId(),
            String.join(" ", buildValidationData.getRequestedTasks()),
            buildValidationData.getBuildOutcome(),
            buildValidationData.getRemoteBuildCacheUrl() == null ? "" : buildValidationData.getRemoteBuildCacheUrl().toString(),
            buildValidationData.getRemoteBuildCacheShard()
        );
    }

    private String toStringSafely(Object object) {
        if (object == null) {
            return "";
        }
        return object.toString();
    }

    private CustomValueNames loadCustomValueKeys(Optional<Path> customValueMappingFile) throws IOException {
        if (customValueMappingFile.isEmpty()) {
            return CustomValueNames.DEFAULT;
        } else {
            return CustomValueNames.loadFromFile(customValueMappingFile.get());
        }
    }
}
