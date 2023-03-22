package com.gradle.enterprise.api.client;

import java.net.URL;
import java.util.Optional;

public class FailedRequestException extends ApiClientException {

    private final int httpStatusCode;

    private final String responseBody;

    public static FailedRequestException fromApiException(URL baseUrl, String buildScanId, ApiException e) {
        final String message = buildMessage(baseUrl, buildScanId, e);
        return new FailedRequestException(message, e.getCode(), e.getResponseBody(), e);
    }

    private FailedRequestException(String message, int httpStatusCode, String responseBody, Throwable cause) {
        super(message, cause);
        this.httpStatusCode = httpStatusCode;
        this.responseBody = responseBody;
    }

    public int httpStatusCode() {
        return httpStatusCode;
    }

    public Optional<String> getResponseBody() {
        return Optional.ofNullable(responseBody);
    }

    private static String buildMessage(URL baseUrl, String buildScanId, ApiException e) {
        switch (e.getCode()) {
            case StatusCodes.NOT_FOUND:
                return String.format("Build scan %s was not found.%nVerify the build scan exists and you have been" +
                        "granted the permission 'Access build data via the Export API'.",
                        buildScanUrl(baseUrl, buildScanId));
            case StatusCodes.UNAUTHORIZED:
                return String.format("Failed to authenticate while attempting to fetch build scan %s.",
                        buildScanUrl(baseUrl, buildScanId));
            case 0:
                return String.format("Unable to connect to %s in order to fetch build scan %s: %s",
                        baseUrl, buildScanId, e.getMessage());
            default:
                return String.format("Encountered an unexpected response while fetching build scan %s.",
                        buildScanUrl(baseUrl, buildScanId));
        }
    }
}
