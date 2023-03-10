package com.gradle.enterprise.model;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.List;
import java.util.stream.Collectors;

import static java.lang.Integer.parseInt;

public class NumberedBuildScan {
    private final int runNum;
    private final URL baseUrl;
    private final String buildScanId;

    private NumberedBuildScan(int runNum, URL baseUrl, String buildScanId) {
        this.runNum = runNum;
        this.baseUrl = baseUrl;
        this.buildScanId = buildScanId;
    }

    public static List<NumberedBuildScan> parse(List<String> runNumsAndBuildScanUrls) {
        return runNumsAndBuildScanUrls.stream().map(NumberedBuildScan::parse).collect(Collectors.toList());
    }

    public static NumberedBuildScan parse(String runNumAndBuildScanUrl) {
        String[] parts = runNumAndBuildScanUrl.split(",");
        if (parts.length != 2) {
            throw new IllegalArgumentException("Invalid numbered Build Scan URL: " + runNumAndBuildScanUrl);
        }

        String runNum = parts[0];
        URL buildScanUrl = toURL(parts[1]);

        return new NumberedBuildScan(
            parseInt(runNum),
            extractBaseUrl(buildScanUrl),
            extractBuildScanId(buildScanUrl)
        );
    }

    public int runNum() {
        return runNum;
    }

    public URL baseUrl() {
        return baseUrl;
    }

    public String buildScanId() {
        return buildScanId;
    }

    private static URL extractBaseUrl(URL buildScanUrl) {
        String port = (buildScanUrl.getPort() != -1) ? ":" + buildScanUrl.getPort() : "";
        return toURL(buildScanUrl.getProtocol() + "://" + buildScanUrl.getHost() + port);
    }

    private static String extractBuildScanId(URL buildScanUrl) {
        String[] pathSegments = buildScanUrl.getPath().split("/");
        if (pathSegments.length == 0) {
            throw new IllegalArgumentException("Invalid Build Scan URL: " + buildScanUrl);
        }
        return pathSegments[pathSegments.length - 1];
    }

    private static URL toURL(String url) {
        try {
            return new URL(url);
        } catch (MalformedURLException e) {
            throw new IllegalArgumentException("Invalid Build Scan URL: " + url, e);
        }
    }

}
