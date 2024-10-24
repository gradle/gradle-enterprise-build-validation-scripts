package com.gradle;

import com.gradle.develocity.agent.maven.adapters.BuildScanApiAdapter;
import com.gradle.develocity.agent.maven.adapters.DevelocityAdapter;
import org.apache.maven.execution.MavenSession;
import org.codehaus.plexus.logging.Logger;

import javax.inject.Inject;
import java.io.File;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;

import static java.lang.Boolean.parseBoolean;
import static java.nio.file.StandardOpenOption.*;

public class ConfigureDevelocityAdaptor {

    private static final String EXPERIMENT_DIR = System.getProperty("com.gradle.enterprise.build-validation.expDir");

    private final RootProjectExtractor rootProjectExtractor;
    private final Logger logger;

    @Inject
    public ConfigureDevelocityAdaptor(RootProjectExtractor rootProjectExtractor, Logger logger) {
        this.rootProjectExtractor = rootProjectExtractor;
        this.logger = logger;
    }

    public void configure(DevelocityAdapter api, MavenSession session) {
        logger.debug("Configuring build scan published event...");

        BuildScanApiAdapter buildScan = api.getBuildScan();

        String geUrl = System.getProperty("gradle.enterprise.url");
        String geAllowUntrustedServer = System.getProperty("gradle.enterprise.allowUntrustedServer");

        if (geUrl != null && !geUrl.isEmpty()) {
            buildScan.setServer(geUrl);
        }
        if (geAllowUntrustedServer != null && !geAllowUntrustedServer.isEmpty()) {
            buildScan.setAllowUntrustedServer(Boolean.parseBoolean(geAllowUntrustedServer));
        }

        String rootProjectName = rootProjectExtractor.extractRootProject(session).getName();

        registerBuildScanActions(buildScan, rootProjectName);
        configureBuildScanPublishing(buildScan);
    }

    private static void registerBuildScanActions(BuildScanApiAdapter buildScan, String rootProjectName) {
        buildScan.buildFinished(buildResult -> {
            // communicate via error file that no GE server is set
            boolean omitServerUrlValidation = parseBoolean(System.getProperty("com.gradle.enterprise.build-validation.omitServerUrlValidation"));
            if (buildScan.getServer() == null && !omitServerUrlValidation) {
                buildScan.publishAlwaysIf(false); // disable publishing, otherwise scans.gradle.com will be used
                File errorFile = new File(EXPERIMENT_DIR, "errors.txt");
                append(errorFile, "The Develocity server URL has not been configured in the project or on the command line.");
            }
        });

        buildScan.buildFinished(buildResult -> {
            String expId = System.getProperty("com.gradle.enterprise.build-validation.expId");
            addCustomValueAndSearchLink(buildScan, "Experiment id", expId);
            buildScan.tag(expId);

            String runId = System.getProperty("com.gradle.enterprise.build-validation.runId");
            addCustomValueAndSearchLink(buildScan, "Experiment run id", runId);

            String scriptsVersion = System.getProperty("com.gradle.enterprise.build-validation.scriptsVersion");
            buildScan.value("Build validation scripts", scriptsVersion);
        });

        buildScan.buildScanPublished(scan -> {
            String runNum = System.getProperty("com.gradle.enterprise.build-validation.runNum");
            URI buildScanUri = scan.getBuildScanUri();
            String buildScanId = scan.getBuildScanId();
            String port = buildScanUri.getPort() != -1 ? ":" + buildScanUri.getPort() : "";
            String baseUrl = String.format("%s://%s%s", buildScanUri.getScheme(), buildScanUri.getHost(), port);

            File scanFile = new File(EXPERIMENT_DIR, "build-scans.csv");
            append(scanFile, String.format("%s,%s,%s,%s,%s\n", runNum, rootProjectName, baseUrl, buildScanUri, buildScanId));
        });
    }

    private static void configureBuildScanPublishing(BuildScanApiAdapter buildScan) {
        buildScan.publishAlways();
        buildScan.capture(t -> t.setGoalInputFiles(true)); // also set via sys prop
        buildScan.setUploadInBackground(false);
    }

    private static void addCustomValueAndSearchLink(BuildScanApiAdapter buildScan, String label, String value) {
        buildScan.value(label, value);
        if (buildScan.getServer() != null) {
            String server = buildScan.getServer();
            String searchParams = "search.names=" + urlEncode(label) + "&search.values=" + urlEncode(value);
            String url = appendIfMissing(server, "/") + "scans?" + searchParams + "#selection.buildScanB=" + urlEncode("{SCAN_ID}");
            buildScan.link(label + " build scans", url);
        }
    }

    private static String appendIfMissing(String str, String suffix) {
        return str.endsWith(suffix) ? str : str + suffix;
    }

    private static String urlEncode(String str) {
        try {
            return URLEncoder.encode(str, StandardCharsets.UTF_8.name());
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException(e);
        }
    }

    private static void append(File file, String text) {
        try {
            Files.write(file.toPath(), text.getBytes(), CREATE, WRITE, APPEND);
        } catch (IOException e) {
            throw new RuntimeException(String.format("Unable to write to file %s: %s", file.getName(), e.getMessage()), e);
        }
    }

}
