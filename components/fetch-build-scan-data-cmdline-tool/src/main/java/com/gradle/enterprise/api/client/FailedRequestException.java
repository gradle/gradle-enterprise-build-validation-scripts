package com.gradle.enterprise.api.client;

import com.gradle.enterprise.cli.FetchToolException;

import java.util.Optional;

public class FailedRequestException extends FetchToolException {

    private final int httpStatusCode;

    private final String responseBody;

    public FailedRequestException(BuildScanUrl buildScanUrl, ApiException e) {
        super(buildMessage(buildScanUrl, e.getCode()));
        this.httpStatusCode = e.getCode();
        this.responseBody = e.getResponseBody();
    }

    public int httpStatusCode() {
        return httpStatusCode;
    }

    public Optional<String> getResponseBody() {
        return Optional.ofNullable(responseBody);
    }

    private static String buildMessage(BuildScanUrl buildScanUrl, int code) {
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
