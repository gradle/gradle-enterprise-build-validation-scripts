package com.gradle.enterprise.model;

import java.time.Duration;

public class TaskExecutionSummary {

    public static final TaskExecutionSummary ZERO = new TaskExecutionSummary(0, Duration.ZERO, Duration.ZERO);

    private final Integer totalTasks;
    private final Duration totalDuration;
    private final Duration totalAvoidanceSavings;

    public TaskExecutionSummary(Integer totalTasks, Duration totalDuration, Duration totalAvoidanceSavings) {
        this.totalTasks = totalTasks;
        this.totalDuration = totalDuration;
        this.totalAvoidanceSavings = totalAvoidanceSavings;
    }

    public Integer totalTasks() {
        return totalTasks;
    }

    public Duration totalDuration() {
        return totalDuration;
    }

    public Duration totalAvoidanceSavings() {
        return totalAvoidanceSavings;
    }

    public TaskExecutionSummary plus(TaskExecutionSummary other) {
        return new TaskExecutionSummary(
            totalTasks + other.totalTasks,
            totalDuration.plus(other.totalDuration),
            totalAvoidanceSavings.plus(other.totalAvoidanceSavings)
        );
    }
}
