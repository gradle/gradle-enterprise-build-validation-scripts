package com.gradle.enterprise.cli;

import java.time.Duration;
import java.util.Locale;

final class Formatting {

    static String formatDuration(Duration duration) {
        long hours = duration.abs().toHours();
        long minutes = duration.abs().toMinutes() % 60;
        double seconds = (duration.abs().toMillis() % 60_000) / 1000d;

        StringBuilder s = new StringBuilder();
        if (duration.isNegative()) {
            s.append('-');
        }
        if (hours != 0) {
            s.append(hours).append("h ");
        }
        if (minutes != 0) {
            s.append(minutes).append("m ");
        }
        s.append(String.format(Locale.ROOT, "%.3fs", seconds));

        return s.toString().trim();
    }

    private Formatting() {
    }
}
