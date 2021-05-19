package com.gradle.enterprise.export_api.client;

import java.net.URL;

public class FetchingBuildScanInterruptedException extends ExportApiClientException {
    public FetchingBuildScanInterruptedException(String buildScanId, URL gradleEnterpriseServer, InterruptedException cause) {
        super(String.format("Process interrupted while fetching build scan %s.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)), cause);
    }
}
