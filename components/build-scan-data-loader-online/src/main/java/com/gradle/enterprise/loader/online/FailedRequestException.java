package com.gradle.enterprise.loader.online;

import com.gradle.enterprise.api.client.ApiException;

import java.net.URL;
import java.util.Optional;

public class FailedRequestException extends RuntimeException {

    private final int httpStatusCode;

    private final String responseBody;

    public FailedRequestException(URL buildScanUrl, ApiException e) {
        super(buildMessage(buildScanUrl, e.getCode()), e);
        this.httpStatusCode = e.getCode();
        this.responseBody = e.getResponseBody();
    }

    public int httpStatusCode() {
        return httpStatusCode;
    }

    public Optional<String> getResponseBody() {
        return Optional.ofNullable(responseBody);
    }

    private static String buildMessage(URL buildScanUrl, int code) {
        switch (code) {
            case 404:
                return String.format("Build scan %s was not found.%nVerify the build scan exists and you have been " +
                        "granted the permission 'Access build data via the API'.", buildScanUrl);
            case 401:
                return String.format("Failed to authenticate while attempting to fetch build scan %s", buildScanUrl);
            case 0:
                return String.format("Unable to connect to server to fetch build scan %s", buildScanUrl);
            default:
                return String.format("Encountered an unexpected response while fetching build scan %s", buildScanUrl);
        }
    }
}
