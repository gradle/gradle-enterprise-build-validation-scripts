package com.gradle.enterprise.cli;

import com.gradle.enterprise.model.BuildTimeMetrics;

import java.util.Arrays;
import java.util.function.Function;
import java.util.stream.Stream;

import static com.gradle.enterprise.cli.DurationFormat.format;

public enum BuildTimeMetricsFields {
    // The order the enums are defined controls the order the fields are printed in the CSV
    INITIAL_BUILD_TIME("Initial Build Time", d -> format(d.initialBuildTime)),
    INSTANT_SAVINGS("Instant Savings", d -> format(d.instantSavings)),
    INSTANT_SAVINGS_BUILD_TIME("Instant Savings Build Time", d -> format(d.instantSavingsBuildTime)),
    PENDING_SAVINGS("Pending Savings", d -> format(d.pendingSavings)),
    PENDING_SAVINGS_BUILD_TIME("Pending Savings Build Time", d -> format(d.pendingSavingsBuildTime)),
    ;

    public final String label;
    public final Function<BuildTimeMetrics, String> value;

    BuildTimeMetricsFields(String label, Function<BuildTimeMetrics, String> value) {
        this.label = label;
        this.value = value;
    }

    public static Stream<BuildTimeMetricsFields> ordered() {
        return Arrays.stream(BuildTimeMetricsFields.values());
    }
}
