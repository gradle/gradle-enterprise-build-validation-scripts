package com.gradle.enterprise.cli;

import com.gradle.enterprise.model.BuildScanData;
import com.gradle.enterprise.model.BuildTimeMetrics;

import java.util.List;
import java.util.stream.Collectors;

final class BuildInsightsPrinter {

    static void printInsights(List<BuildScanData> buildScanData) {
        printBuildScanDataHeader();
        printBuildScanData(buildScanData);

        if (buildScanData.size() == 2) {
            printBuildTimeMetricsHeader();
            printBuildTimeMetrics(buildScanData);
        }
    }

    private static void printBuildScanDataHeader() {
        List<String> labels = BuildScanDataFields.ordered().map(f -> f.label).collect(Collectors.toList());
        System.out.println(String.join(",", labels));
    }

    private static void printBuildScanData(List<BuildScanData> buildScanData) {
        buildScanData.forEach(BuildInsightsPrinter::printBuildScanData);
    }

    private static void printBuildScanData(BuildScanData buildScanData) {
        List<String> values = BuildScanDataFields.ordered().map(f -> f.value.apply(buildScanData)).collect(Collectors.toList());
        System.out.println(String.join(",", values));
    }

    private static void printBuildTimeMetricsHeader() {
        List<String> labels = BuildTimeMetricsFields.ordered().map(f -> f.label).collect(Collectors.toList());
        System.out.println(String.join(",", labels));
    }

    private static void printBuildTimeMetrics(List<BuildScanData> buildScanData) {
        final BuildTimeMetrics buildTimeData = BuildTimeMetrics.from(buildScanData.get(0), buildScanData.get(1));
        List<String> values;
        if (buildTimeData == null) {
            values = BuildTimeMetricsFields.ordered().map(f -> "").collect(Collectors.toList());
        } else {
            values = BuildTimeMetricsFields.ordered().map(f -> f.value.apply(buildTimeData)).collect(Collectors.toList());
        }
        System.out.println(String.join(",", values));
    }

    private BuildInsightsPrinter() {
    }
}
