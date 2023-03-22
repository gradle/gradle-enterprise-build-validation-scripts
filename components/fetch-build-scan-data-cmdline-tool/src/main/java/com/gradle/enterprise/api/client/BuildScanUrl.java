package com.gradle.enterprise.api.client;

import java.net.MalformedURLException;
import java.net.URL;

public class BuildScanUrl {

    private final URL url;

    private BuildScanUrl(URL url) {
        this.url = url;
    }

    public static BuildScanUrl from(URL gradleEnterpriseServerUrl, String buildScanId) {
        try {
            return new BuildScanUrl(new URL(gradleEnterpriseServerUrl, "/s/" + buildScanId));
        } catch (MalformedURLException e) {
            throw new RuntimeException(e.getMessage(), e);
        }
    }

    @Override
    public String toString() {
        return url.toString();
    }
}
