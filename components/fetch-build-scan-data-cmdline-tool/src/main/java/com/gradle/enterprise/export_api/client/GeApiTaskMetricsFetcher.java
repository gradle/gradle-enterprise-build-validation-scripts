package com.gradle.enterprise.export_api.client;

import com.google.common.collect.ImmutableMap;
import com.gradle.enterprise.TaskExecutionSummary;
import com.gradle.enterprise.api.GradleEnterpriseApi;
import com.gradle.enterprise.api.client.ApiClient;
import com.gradle.enterprise.api.client.ApiException;
import com.gradle.enterprise.api.model.Build;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.GradleBuildCachePerformanceTaskExecutionEntry;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenBuildCachePerformanceGoalExecutionEntry;

import java.net.URL;
import java.time.Duration;
import java.util.AbstractMap;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class GeApiTaskMetricsFetcher {

    private final URL baseUrl;
    private final GradleEnterpriseApi apiClient;

    public GeApiTaskMetricsFetcher(URL baseUrl) {
        ApiClient client = new ApiClient();
        client.setBasePath(baseUrl.toString());
        client.setBearerToken(Authenticators.lookupAccessKey(baseUrl));

        this.baseUrl = baseUrl;
        this.apiClient = new GradleEnterpriseApi(client);
    }

    public Map<String, TaskExecutionSummary> countTasksByAvoidanceOutcome(String buildScanId) {
        try {
            Build build = apiClient.getBuild(buildScanId, null);
            if (build.getBuildToolType().equalsIgnoreCase("gradle")) {
                GradleBuildCachePerformance buildCachePerformance = apiClient.getGradleBuildCachePerformance(buildScanId, null);

                Map<String, List<GradleBuildCachePerformanceTaskExecutionEntry>> tasksByOutcome = buildCachePerformance.getTaskExecution().stream()
                    .collect(Collectors.groupingBy(
                        t -> t.getAvoidanceOutcome().toString()
                    ));

                Map<String, TaskExecutionSummary> executionSummariesByOutcome = tasksByOutcome.entrySet()
                    .stream()
                    .map(GeApiTaskMetricsFetcher::summarizeForGradle)
                    .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

                Arrays.stream(GradleBuildCachePerformanceTaskExecutionEntry.AvoidanceOutcomeEnum.values())
                    .forEach(outcome -> executionSummariesByOutcome.putIfAbsent(outcome.toString(), TaskExecutionSummary.ZERO));

                return executionSummariesByOutcome;
            }
            if (build.getBuildToolType().equalsIgnoreCase("maven")) {
                MavenBuildCachePerformance buildCachePerformance = apiClient.getMavenBuildCachePerformance(buildScanId, null);

                Map<String, List<MavenBuildCachePerformanceGoalExecutionEntry>> tasksByOutcome = buildCachePerformance.getGoalExecution().stream()
                    .collect(Collectors.groupingBy(
                        t -> t.getAvoidanceOutcome().toString()
                    ));

                Map<String, TaskExecutionSummary> executionSummariesByOutcome = tasksByOutcome.entrySet()
                    .stream()
                    .map(GeApiTaskMetricsFetcher::summarizeForMaven)
                    .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

                Arrays.stream(MavenBuildCachePerformanceGoalExecutionEntry.AvoidanceOutcomeEnum.values())
                    .forEach(outcome -> executionSummariesByOutcome.putIfAbsent(outcome.toString(), TaskExecutionSummary.ZERO));

                return executionSummariesByOutcome;
            }
            return ImmutableMap.of();
        } catch (ApiException e) {
            switch(e.getCode()) {
                case StatusCodes.NOT_FOUND:
                    throw new BuildScanNotFoundException(buildScanId, baseUrl, null, null); // TODO figure out how to include request and response
                case StatusCodes.UNAUTHORIZED:
                    throw new AuthenticationFailedException(buildScanId, baseUrl, null, null); // TODO figure out how to include request and response
                default:
                    throw new UnexpectedResponseException(buildScanId, baseUrl, null, null); // TODO figure out how to include request and response
            }
        }
    }

    private static Map.Entry<String, TaskExecutionSummary> summarizeForGradle(Map.Entry<String, List<GradleBuildCachePerformanceTaskExecutionEntry>> entry) {
        return new AbstractMap.SimpleEntry<>(entry.getKey(), summarizeForGradle(entry.getValue()));
    }

    private static TaskExecutionSummary summarizeForGradle(List<GradleBuildCachePerformanceTaskExecutionEntry> tasks) {
        // TODO Find a better way to do this
        Integer totalTasks = tasks.size();
        Duration totalDuration = Duration.ofMillis(
            tasks.stream()
                .mapToLong(GradleBuildCachePerformanceTaskExecutionEntry::getDuration)
                .sum());

        Duration totalAvoidanceSavings = Duration.ofMillis(
            tasks.stream()
                .filter(t -> t.getAvoidanceSavings() != null)
                .mapToLong(GradleBuildCachePerformanceTaskExecutionEntry::getAvoidanceSavings)
                .sum());

        return new TaskExecutionSummary(totalTasks, totalDuration, totalAvoidanceSavings);
    }

    private static Map.Entry<String, TaskExecutionSummary> summarizeForMaven(Map.Entry<String, List<MavenBuildCachePerformanceGoalExecutionEntry>> entry) {
        return new AbstractMap.SimpleEntry<>(entry.getKey(), summarizeForMaven(entry.getValue()));
    }

    private static TaskExecutionSummary summarizeForMaven(List<MavenBuildCachePerformanceGoalExecutionEntry> tasks) {
        // TODO Find a better way to do this
        Integer totalTasks = tasks.size();
        Duration totalDuration = Duration.ofMillis(
            tasks.stream()
                .mapToLong(MavenBuildCachePerformanceGoalExecutionEntry::getDuration)
                .sum()
        );

        Duration totalAvoidanceSavings = Duration.ofMillis(
            tasks.stream()
                .filter(t -> t.getAvoidanceSavings() != null)
                .mapToLong(MavenBuildCachePerformanceGoalExecutionEntry::getAvoidanceSavings)
                .sum()
        );

        return new TaskExecutionSummary(totalTasks, totalDuration, totalAvoidanceSavings);
    }
}
