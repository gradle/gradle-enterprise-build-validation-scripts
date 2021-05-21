package com.gradle.enterprise.export_api.client;

import okhttp3.Request;
import okhttp3.Response;

import java.io.IOException;

public class FailedRequestException extends ExportApiClientException {
    private final Request request;
    private final Response response;
    private final String responseBody;

    public FailedRequestException(String message, Request request, Response response) {
        this(message, request, response, null);
    }

    public FailedRequestException(String message, Request request, Response response, Throwable cause) {
        super(message, cause);
        this.request = request;
        this.response = response;
        this.responseBody = extractResponseBody(response);
    }

    private static String extractResponseBody(Response response) {
        try {
            return response.body().string();
        } catch (Exception e) {
            return null;
        }
    }

    public Request getRequest() {
        return request;
    }

    public Response getResponse() {
        return response;
    }

    public String getResponseBody() {
        return responseBody;
    }
}
