package com.gradle.enterprise.cli;

import com.gradle.enterprise.model.BuildScanData;
import com.gradle.enterprise.model.BuildTimeMetrics;

import java.util.List;
import java.util.stream.Stream;

import static java.util.stream.Collectors.joining;

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
        printRow(BuildScanDataFields.ordered().map(f -> f.label));
    }

    private static void printBuildScanData(List<BuildScanData> buildScanData) {
        buildScanData.forEach(BuildInsightsPrinter::printBuildScanData);
    }

    private static void printBuildScanData(BuildScanData buildScanData) {
        printRow(BuildScanDataFields.ordered().map(f -> f.value.apply(buildScanData)));
    }

    private static void printBuildTimeMetricsHeader() {
        printRow(BuildTimeMetricsFields.ordered().map(f -> f.label));
    }

    private static void printBuildTimeMetrics(List<BuildScanData> buildScanData) {
        final BuildTimeMetrics buildTimeData = BuildTimeMetrics.from(buildScanData.get(0), buildScanData.get(1));
        if (buildTimeData == null) {
            printRow(BuildTimeMetricsFields.ordered().map(f -> ""));
        } else {
            printRow(BuildTimeMetricsFields.ordered().map(f -> f.value.apply(buildTimeData)));
        }
    }

    private static void printRow(Stream<String> values) {
        System.out.println(values.collect(joining(",")));
    }

    private BuildInsightsPrinter() {
    }
}
