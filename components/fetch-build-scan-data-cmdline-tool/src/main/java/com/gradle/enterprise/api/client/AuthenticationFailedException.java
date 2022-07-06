package com.gradle.enterprise.api.client;

import java.net.URL;

public class AuthenticationFailedException extends FailedRequestException {
    public AuthenticationFailedException(URL gradleEnterpriseServer, String buildScanId, int httpStatusCode, String responseBody, Throwable cause) {
        super(String.format("Failed to authenticate while attempting to fetch build scan %s.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)),
            httpStatusCode, responseBody, cause);
    }
}
