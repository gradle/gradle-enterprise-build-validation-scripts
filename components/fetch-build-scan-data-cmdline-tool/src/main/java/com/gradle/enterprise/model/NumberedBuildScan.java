package com.gradle.enterprise.model;

import java.net.MalformedURLException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.List;
import java.util.stream.Collectors;

import static java.lang.Integer.parseInt;

public class NumberedBuildScan {
    public final int runNum;
    public final URI resource;

    private NumberedBuildScan(int runNum, URI resource) {
        this.runNum = runNum;
        this.resource = resource;
    }

    public static List<NumberedBuildScan> parse(List<String> runNumsAndBuildScanUrls) {
        return runNumsAndBuildScanUrls.stream().map(NumberedBuildScan::parse).collect(Collectors.toList());
    }

    public static NumberedBuildScan parse(String runNumAndBuildScanUrl) {
        String[] parts = runNumAndBuildScanUrl.split(",");
        if (parts.length != 2) {
            throw new IllegalArgumentException("Invalid numbered Build Scan: " + runNumAndBuildScanUrl);
        }

        String runNum = parts[0];
        URI buildScanResource = toURI(parts[1]);

        return new NumberedBuildScan(parseInt(runNum), buildScanResource);
    }

    private static URI toURI(String resource) {
        try {
            return new URI(resource);
        } catch (URISyntaxException e) {
            throw new IllegalArgumentException("Invalid Build Scan resource: " + resource, e);
        }
    }
}
