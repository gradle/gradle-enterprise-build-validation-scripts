package com.gradle.enterprise.export_api.client;

import okhttp3.Request;
import okhttp3.Response;

import java.net.URL;

public class UnexpectedResponseException extends FailedRequestException {
    public UnexpectedResponseException(String buildScanId, URL gradleEnterpriseServer, Request request, Response response) {
        super(String.format("Encountered an unexpected response while fetching build scan %s.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)),
            request, response);
    }
}
