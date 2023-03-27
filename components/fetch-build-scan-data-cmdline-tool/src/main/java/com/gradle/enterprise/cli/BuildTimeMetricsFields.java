package com.gradle.enterprise.cli;

import com.gradle.enterprise.model.BuildValidationData;

import java.util.Arrays;
import java.util.function.Function;
import java.util.stream.Stream;

public enum BuildTimeMetricsFields {
    // The order the enums are defined controls the order the fields are printed in the CSV
    INITIAL_BUILD_TIME("Initial Build Time", d -> ""),
    INSTANT_SAVINGS("Instant Savings", d -> ""),
    INSTANT_SAVINGS_BUILD_TIME("Instant Savings Build Time", d -> ""),
    PENDING_SAVINGS("Pending Savings", d -> ""),
    PENDING_SAVINGS_BUILD_TIME("Pending Savings Build Time", d -> ""),
    ;

    public final String label;
    public final Function<BuildValidationData, String> value;

    BuildTimeMetricsFields(String label, Function<BuildValidationData, String> value) {
        this.label = label;
        this.value = value;
    }

    public static Stream<BuildTimeMetricsFields> ordered() {
        return Arrays.stream(BuildTimeMetricsFields.values());
    }
}
