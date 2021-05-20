package com.gradle.enterprise.export_api.client;

import java.net.URL;

public class BuildScanNotFoundException extends ExportApiClientException {
    public BuildScanNotFoundException(String buildScanId, URL gradleEnterpriseServer) {
        super(String.format("Build scan %s was not found.%nVerify the build scan exists and you have been granted the permission" +
                " 'Access build data via the Export API'.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)));
    }
}
