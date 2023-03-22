package com.gradle.enterprise.api.client;

import com.gradle.enterprise.cli.FetchToolException;

import java.util.Optional;

/**
 * Exception thrown when a request to the Gradle Enterprise API fails.
 */
public class FailedRequestException extends FetchToolException {

    private final int httpStatusCode;

    private final String responseBody;

    /**
     * Constructs a new {@code FailedRequestException} from the specified {@link BuildScanUrl} and {@link ApiException}.
     *
     * @param buildScanUrl the url of the Build Scan that was being fetched when the exception occurred
     * @param e the exception that was thrown while attempting to fetch the Build Scan
     */
    public FailedRequestException(BuildScanUrl buildScanUrl, ApiException e) {
        super(buildMessage(buildScanUrl, e.getCode()));
        this.httpStatusCode = e.getCode();
        this.responseBody = e.getResponseBody();
    }

    /**
     * Returns the HTTP status code returned by the failed API request.
     *
     * @return the HTTP status code
     */
    public int httpStatusCode() {
        return httpStatusCode;
    }

    /**
     * Returns an optional string containing the response body returned by the failed API request.
     *
     * @return an optional string containing the response body, or an empty optional if the response body was null
     */
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
