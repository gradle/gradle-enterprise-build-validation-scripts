package com.gradle.enterprise.loader;

import java.net.MalformedURLException;
import java.net.URI;
import java.net.URL;

public class BuildScanUrlUtils {
    private BuildScanUrlUtils() {
    }

    public static URL toBuildScanURL(URI resource) {
        try {
            return resource.toURL();
        } catch (MalformedURLException e) {
            throw new IllegalArgumentException(resource + " is not a valid Build Scan URL: " + e.getMessage(), e);
        }
    }

    public static URL extractBaseUrl(URL buildScanUrl) {
        String port = (buildScanUrl.getPort() != -1) ? ":" + buildScanUrl.getPort() : "";
        return toURL(buildScanUrl.getProtocol() + "://" + buildScanUrl.getHost() + port);
    }

    public static String extractBuildScanId(URL buildScanUrl) {
        String[] pathSegments = buildScanUrl.getPath().split("/");
        if (pathSegments.length <= 2 || !pathSegments[1].equals("s")) {
            throw new IllegalArgumentException("Invalid Build Scan URL: " + buildScanUrl);
        }
        return pathSegments[2];
    }

    private static URL toURL(String url) {
        try {
            return new URL(url);
        } catch (MalformedURLException e) {
            throw new IllegalArgumentException("Invalid Build Scan URL: " + url, e);
        }
    }
}
