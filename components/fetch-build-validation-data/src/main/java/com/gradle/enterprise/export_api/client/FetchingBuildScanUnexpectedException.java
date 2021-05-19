package com.gradle.enterprise.export_api.client;

import java.net.URL;

public class FetchingBuildScanUnexpectedException extends ExportApiClientException {
    public FetchingBuildScanUnexpectedException(String buildScanId, URL gradleEnterpriseServer, Throwable cause) {
        super(String.format("An unexpected error occurred while fetching build scan %s:%n%s",
            buildScanUrl(gradleEnterpriseServer, buildScanId), cause.getMessage()),
            cause);
    }
}
