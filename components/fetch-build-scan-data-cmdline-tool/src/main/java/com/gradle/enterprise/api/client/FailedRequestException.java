package com.gradle.enterprise.api.client;

import java.net.URL;
import java.util.Optional;

public class FailedRequestException extends ApiClientException {

    private final int httpStatusCode;

    private final String responseBody;

    public static FailedRequestException fromApiException(URL baseUrl, String buildScanId, ApiException e) {
        final String message = buildMessage(baseUrl, buildScanId, e.getCode());
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

    private static String buildMessage(URL baseUrl, String buildScanId, int code) {
        final URL buildScanUrl = buildScanUrl(baseUrl, buildScanId);
        switch (code) {
            case StatusCodes.NOT_FOUND:
                return String.format("Build scan %s was not found.%nVerify the build scan exists and you have been" +
                        "granted the permission 'Access build data via the Export API'.", buildScanUrl);
            case StatusCodes.UNAUTHORIZED:
                return String.format("Failed to authenticate while attempting to fetch build scan %s.", buildScanUrl);
            case 0:
                return String.format("Unable to connect to server in order to fetch build scan %s.", buildScanUrl);
            default:
                return String.format("Encountered an unexpected response while fetching build scan %s.", buildScanUrl);
        }
    }
}
