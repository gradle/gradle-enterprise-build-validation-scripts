package com.gradle.enterprise.api.client;

import okhttp3.Request;
import okhttp3.Response;

public class FailedRequestException extends ApiClientException {
    private final String responseBody;

    public FailedRequestException(String message, String responseBody) {
        this(message, responseBody, null);
    }

    public FailedRequestException(String message, String responseBody, Throwable cause) {
        super(message, cause);
        this.responseBody = responseBody;
    }

    public String getResponseBody() {
        return responseBody;
    }
}
