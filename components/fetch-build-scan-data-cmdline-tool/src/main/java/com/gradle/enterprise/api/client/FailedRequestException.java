package com.gradle.enterprise.api.client;

public class FailedRequestException extends ApiClientException {

    private final int httpStatusCode;

    private final String responseBody;

    public FailedRequestException(String message, int httpStatusCode, String responseBody) {
        this(message, httpStatusCode, responseBody, null);
    }

    public FailedRequestException(String message, int httpStatusCode, String responseBody, Throwable cause) {
        super(message, cause);
        this.httpStatusCode = httpStatusCode;
        this.responseBody = responseBody;
    }

    public int httpStatusCode() {
        return httpStatusCode;
    }

    public String getResponseBody() {
        return responseBody;
    }
}
