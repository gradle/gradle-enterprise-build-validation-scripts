package com.gradle.enterprise;

import java.net.URL;

public class BadBuildScanUrlException extends RuntimeException {
    public BadBuildScanUrlException(URL buildScanUrl) {
        this(buildScanUrl, null);
    }

    public BadBuildScanUrlException(URL buildScanUrl, Throwable cause) {
        super(String.format("The URL %s is not a valid build scan URL.",
            buildScanUrl), cause);
    }
}
