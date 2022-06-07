package com.gradle.enterprise.api.client;

import java.net.URL;

public class AuthenticationFailedException extends FailedRequestException {
    public AuthenticationFailedException(String buildScanId, URL gradleEnterpriseServer, int httpStatusCode, String responseBody) {
        super(String.format("Failed to authenticate while attempting to fetch build scan %s.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)),
            httpStatusCode, responseBody);
    }
}
