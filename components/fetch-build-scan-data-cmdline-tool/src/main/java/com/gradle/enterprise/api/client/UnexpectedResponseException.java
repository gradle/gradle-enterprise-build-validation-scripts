package com.gradle.enterprise.api.client;

import java.net.URL;

public class UnexpectedResponseException extends FailedRequestException {
    public UnexpectedResponseException(URL gradleEnterpriseServer, String buildScanId, int httpStatusCode, String responseBody, Throwable cause) {
        super(String.format("Encountered an unexpected response while fetching build scan %s.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)),
            httpStatusCode, responseBody, cause);
    }
}
