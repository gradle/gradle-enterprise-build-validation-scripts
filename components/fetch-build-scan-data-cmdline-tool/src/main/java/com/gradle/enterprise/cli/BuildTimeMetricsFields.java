package com.gradle.enterprise.cli;

import com.gradle.enterprise.model.BuildTimeMetrics;

import java.time.Duration;
import java.util.Arrays;
import java.util.Locale;
import java.util.function.Function;
import java.util.stream.Stream;

public enum BuildTimeMetricsFields {
    // The order the enums are defined controls the order the fields are printed in the CSV
    INITIAL_BUILD_TIME("Initial Build Time", d -> formatDuration(d.initialBuildTime)),
    INSTANT_SAVINGS("Instant Savings", d -> formatDuration(d.instantSavings)),
    INSTANT_SAVINGS_BUILD_TIME("Instant Savings Build Time", d -> formatDuration(d.instantSavingsBuildTime)),
    PENDING_SAVINGS("Pending Savings", d -> formatDuration(d.pendingSavings)),
    PENDING_SAVINGS_BUILD_TIME("Pending Savings Build Time", d -> formatDuration(d.pendingSavingsBuildTime)),
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

    private static String formatDuration(Duration duration) {
        long hours = duration.toHours();
        long minutes = duration.minusHours(hours).toMinutes();
        double seconds = duration.minusHours(hours).minusMinutes(minutes).toMillis() / 1000d;

        StringBuilder s = new StringBuilder();
        if (hours != 0) {
            s.append(hours).append("h ");
        }
        if (minutes != 0) {
            s.append(minutes).append("m ");
        }
        s.append(String.format(Locale.ROOT, "%.3fs", seconds));

        return s.toString().trim();
    }
}
