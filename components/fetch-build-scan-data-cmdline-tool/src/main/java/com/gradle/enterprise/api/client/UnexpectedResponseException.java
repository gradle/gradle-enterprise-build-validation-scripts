package com.gradle.enterprise.api.client;

import java.net.URL;

public class UnexpectedResponseException extends FailedRequestException {
    public UnexpectedResponseException(String buildScanId, URL gradleEnterpriseServer, int httpStatusCode, String responseBody) {
        super(String.format("Encountered an unexpected response while fetching build scan %s.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)),
            httpStatusCode, responseBody);
    }
}
