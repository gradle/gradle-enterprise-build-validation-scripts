package com.gradle.enterprise.loader;

import com.gradle.enterprise.api.client.ApiException;
import com.gradle.enterprise.api.model.GradleAttributes;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenAttributes;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;

import java.net.MalformedURLException;
import java.net.URI;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

public final class OnlineBuildScanDataLoader implements BuildScanDataLoader {

    // Use a String as the key because using a URL as a map key is dangerous (partly becuase URL is mutable).
    private final Map<String, GradleEnterpriseApiClient> apiClientsByBaseUrl = new HashMap<>();
    private final Logger logger;

    public OnlineBuildScanDataLoader(Logger logger) {
        this.logger = logger;
    }

    @Override
    public BuildToolType determineBuildToolType(URI resource) {
        URL buildScanUrl = toBuildScanURL(resource);
        GradleEnterpriseApiClient apiClient = getOrCreateClient(buildScanUrl);
        String buildScanId = extractBuildScanId(buildScanUrl);

        try {
            return BuildToolType.valueOf(apiClient.fetchBuildToolType(buildScanId).toUpperCase());
        } catch (ApiException e) {
            throw new FailedRequestException(buildScanUrl, e);
        }
    }

    @Override
    public Pair<GradleAttributes, GradleBuildCachePerformance> loadDataForGradle(URI resource) {
        URL buildScanUrl = toBuildScanURL(resource);
        GradleEnterpriseApiClient apiClient = getOrCreateClient(buildScanUrl);
        String buildScanId = extractBuildScanId(buildScanUrl);

        try {
            return apiClient.loadDataForGradle(buildScanId);
        } catch (ApiException e) {
            throw new FailedRequestException(buildScanUrl, e);
        }
    }

    @Override
    public Pair<MavenAttributes, MavenBuildCachePerformance> loadDataForMaven(URI resource) {
        URL buildScanUrl = toBuildScanURL(resource);
        GradleEnterpriseApiClient apiClient = getOrCreateClient(buildScanUrl);
        String buildScanId = extractBuildScanId(buildScanUrl);

        try {
            return apiClient.loadDataForMaven(buildScanId);
        } catch (ApiException e) {
            throw new FailedRequestException(buildScanUrl, e);
        }
    }

    private synchronized GradleEnterpriseApiClient getOrCreateClient(URL buildScanUrl) {
        URL baseUrl = extractBaseUrl(buildScanUrl);
        return apiClientsByBaseUrl.computeIfAbsent(baseUrl.toString(), k -> new GradleEnterpriseApiClient(baseUrl, logger));
    }

    private static URL toBuildScanURL(URI resource) {
        try {
            return resource.toURL();
        } catch (MalformedURLException e) {
            throw new IllegalArgumentException(resource + " is not a valid Build Scan URL: " + e.getMessage(), e);
        }
    }

    //TODO duplicated in NumberedBuildScan
    private static URL extractBaseUrl(URL buildScanUrl) {
        String port = (buildScanUrl.getPort() != -1) ? ":" + buildScanUrl.getPort() : "";
        return toURL(buildScanUrl.getProtocol() + "://" + buildScanUrl.getHost() + port);
    }

    //TODO duplicated in NumberedBuildScan
    private static String extractBuildScanId(URL buildScanUrl) {
        String[] pathSegments = buildScanUrl.getPath().split("/");
        if (pathSegments.length <= 2 || !pathSegments[1].equals("s")) {
            throw new IllegalArgumentException("Invalid Build Scan URL: " + buildScanUrl);
        }
        return pathSegments[2];
    }

    //TODO duplicated in NumberedBuildScan
    private static URL toURL(String url) {
        try {
            return new URL(url);
        } catch (MalformedURLException e) {
            throw new IllegalArgumentException("Invalid Build Scan URL: " + url, e);
        }
    }
}
