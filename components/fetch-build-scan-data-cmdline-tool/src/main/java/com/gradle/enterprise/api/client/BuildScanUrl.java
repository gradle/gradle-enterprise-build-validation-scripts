package com.gradle.enterprise.api.client;

import java.net.MalformedURLException;
import java.net.URL;

/**
 * A value object representing a Gradle Enterprise Build Scan URL.
 *
 * <p>This class provides a convenient way to create a Gradle Enterprise Build
 * Scan URL, given the server's base URL and a Build Scan ID.
 */
public class BuildScanUrl {

    private final URL url;

    /**
     * Constructs a new {@code BuildScanUrl} instance from the specified
     * {@link URL}.
     *
     * @param url the URL of the Build Scan
     */
    private BuildScanUrl(URL url) {
        this.url = url;
    }

    /**
     * Creates a new {@code BuildScanUrl} instance from the specified Gradle
     * Enterprise server URL and Build Scan ID.
     *
     * @param gradleEnterpriseServerUrl the Gradle Enterprise server base URL
     * @param buildScanId the ID of the Build Scan
     * @return a new {@code BuildScanUrl} instance
     * @throws RuntimeException if the resulting URL is malformed
     */
    public static BuildScanUrl from(URL gradleEnterpriseServerUrl, String buildScanId) {
        try {
            return new BuildScanUrl(new URL(gradleEnterpriseServerUrl, "/s/" + buildScanId));
        } catch (MalformedURLException e) {
            throw new RuntimeException(e.getMessage(), e);
        }
    }

    /**
     * Returns the string representation of this {@code BuildScanUrl}.
     *
     * @return the string representation of this URL
     */
    @Override
    public String toString() {
        return url.toString();
    }
}
