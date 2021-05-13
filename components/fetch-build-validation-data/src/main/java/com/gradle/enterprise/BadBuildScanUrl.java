package com.gradle.enterprise;

import java.net.URL;

public class BadBuildScanUrl extends FetchBuildValidationDataException {
    public BadBuildScanUrl(URL buildScanUrl) {
        this(buildScanUrl, null);
    }

    public BadBuildScanUrl(URL buildScanUrl, Throwable cause) {
        super(String.format("The URL %s is not a valid build scan URL.",
            buildScanUrl), cause);
    }
}
