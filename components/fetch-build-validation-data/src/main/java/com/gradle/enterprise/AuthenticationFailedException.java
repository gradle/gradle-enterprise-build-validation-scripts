package com.gradle.enterprise;

import java.net.URL;

public class AuthenticationFailedException extends ExportApiClientException {
    public AuthenticationFailedException(String buildScanId, URL gradleEnterpriseServer) {
        super(String.format("Failed to authenticate while attempting to fetch build scan %s.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)));
    }
}
