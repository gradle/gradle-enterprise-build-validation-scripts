package com.gradle.enterprise.api.client;

import com.gradle.enterprise.model.BuildValidationData;
import com.gradle.enterprise.model.CustomValueNames;
import com.gradle.enterprise.model.TaskExecutionSummary;
import com.gradle.enterprise.api.GradleEnterpriseApi;
import com.gradle.enterprise.api.model.Build;
import com.gradle.enterprise.api.model.BuildAttributesValue;
import com.gradle.enterprise.api.model.GradleAttributes;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.GradleBuildCachePerformanceTaskExecutionEntry;
import com.gradle.enterprise.api.model.MavenAttributes;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenBuildCachePerformanceGoalExecutionEntry;
import org.jetbrains.annotations.NotNull;

import java.net.MalformedURLException;
import java.net.URL;
import java.time.Duration;
import java.util.AbstractMap;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class GradleEnterpriseApiClient {

    private final URL baseUrl;
    private final GradleEnterpriseApi apiClient;

    private final CustomValueNames customValueNames;

    public GradleEnterpriseApiClient(URL baseUrl, CustomValueNames customValueNames) {
        this.customValueNames = customValueNames;
        ApiClient client = new ApiClient();
        client.setBasePath(baseUrl.toString());
        AuthenticationConfigurator.configureAuth(baseUrl, client);

        this.baseUrl = baseUrl;
        this.apiClient = new GradleEnterpriseApi(client);
    }

    public BuildValidationData fetchBuildValidationData(String buildScanId) {
        try {
            Build build = apiClient.getBuild(buildScanId, null);
            if (build.getBuildToolType().equalsIgnoreCase("gradle")) {
                GradleAttributes attributes = apiClient.getGradleAttributes(buildScanId, null);
                GradleBuildCachePerformance buildCachePerformance = apiClient.getGradleBuildCachePerformance(buildScanId, null);

                return new BuildValidationData(
                    attributes.getRootProjectName(),
                    buildScanId,
                    baseUrl,
                    findCustomValue(customValueNames.getGitRepositoryKey(), attributes.getValues()),
                    findCustomValue(customValueNames.getGitBranchKey(), attributes.getValues()),
                    findCustomValue(customValueNames.getGitCommitIdKey(), attributes.getValues()),
                    attributes.getRequestedTasks(),
                    buildOutcomeFrom(attributes),
                    remoteBuildCacheUrlFrom(buildCachePerformance),
                    summarizeTaskExecutions(buildCachePerformance)
                );
            }
            if (build.getBuildToolType().equalsIgnoreCase("maven")) {
                MavenAttributes attributes = apiClient.getMavenAttributes(buildScanId, null);
                MavenBuildCachePerformance buildCachePerformance = apiClient.getMavenBuildCachePerformance(buildScanId, null);

                return new BuildValidationData(
                    attributes.getTopLevelProjectName(),
                    buildScanId,
                    baseUrl,
                    findCustomValue(customValueNames.getGitRepositoryKey(), attributes.getValues()),
                    findCustomValue(customValueNames.getGitBranchKey(), attributes.getValues()),
                    findCustomValue(customValueNames.getGitCommitIdKey(), attributes.getValues()),
                    attributes.getRequestedGoals(),
                    buildOutcomeFrom(attributes),
                    remoteBuildCacheUrlFrom(buildCachePerformance),
                    summarizeTaskExecutions(buildCachePerformance)
                );
            }
            throw new UnknownBuildAgentException(build.getBuildToolType(), buildScanId, baseUrl);
        } catch (ApiException e) {
            switch(e.getCode()) {
                case StatusCodes.NOT_FOUND:
                    throw new BuildScanNotFoundException(buildScanId, baseUrl, e.getResponseBody());
                case StatusCodes.UNAUTHORIZED:
                    throw new AuthenticationFailedException(buildScanId, baseUrl, e.getResponseBody());
                default:
                    throw new UnexpectedResponseException(buildScanId, baseUrl, e.getResponseBody());
            }
        }
    }

    private String findCustomValue(String key, List<BuildAttributesValue> values) {
        return values.stream()
            .filter(v -> v.getName().equals(key))
            .map(v -> {
                if (v.getValue() == null) {
                    return "";
                }
                return v.getValue();
            })
            .findFirst()
            .orElse("");
    }

    private String buildOutcomeFrom(GradleAttributes attributes) {
        if(!attributes.getHasFailed()) {
            return "SUCCESS";
        }
        return "FAILED";
    }

    private String buildOutcomeFrom(MavenAttributes attributes) {
        if(!attributes.getHasFailed()) {
            return "SUCCESS";
        }
        return "FAILED";
    }

    private URL remoteBuildCacheUrlFrom(GradleBuildCachePerformance buildCachePerformance) {
        if (buildCachePerformance.getBuildCaches() == null ||
            buildCachePerformance.getBuildCaches().getRemote() == null ||
            buildCachePerformance.getBuildCaches().getRemote().getUrl() == null) {
            return null;
        }

        try {
            return new URL(buildCachePerformance.getBuildCaches().getRemote().getUrl());
        } catch (MalformedURLException e) {
            // TODO maybe log out this failure
            // Don't do anything on purpose.
            return null;
        }
    }

    private URL remoteBuildCacheUrlFrom(MavenBuildCachePerformance buildCachePerformance) {
        if (buildCachePerformance.getBuildCaches() == null ||
            buildCachePerformance.getBuildCaches().getRemote() == null ||
            buildCachePerformance.getBuildCaches().getRemote().getUrl() == null) {
            return null;
        }

        try {
            return new URL(buildCachePerformance.getBuildCaches().getRemote().getUrl());
        } catch (MalformedURLException e) {
            // TODO maybe log out this failure
            // Don't do anything on purpose.
            return null;
        }
    }

    @NotNull
    private Map<String, TaskExecutionSummary> summarizeTaskExecutions(GradleBuildCachePerformance buildCachePerformance) {
        Map<String, List<GradleBuildCachePerformanceTaskExecutionEntry>> tasksByOutcome = buildCachePerformance.getTaskExecution().stream()
            .collect(Collectors.groupingBy(
                t -> t.getAvoidanceOutcome().toString()
            ));

        Map<String, TaskExecutionSummary> summariesByOutcome = tasksByOutcome.entrySet()
            .stream()
            .map(GradleEnterpriseApiClient::summarizeForGradle)
            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

        Arrays.stream(GradleBuildCachePerformanceTaskExecutionEntry.AvoidanceOutcomeEnum.values())
            .forEach(outcome -> summariesByOutcome.putIfAbsent(outcome.toString(), TaskExecutionSummary.ZERO));

        return putTotalAvoidedFromCache(summariesByOutcome);
    }

    @NotNull
    private Map<String, TaskExecutionSummary> summarizeTaskExecutions(MavenBuildCachePerformance buildCachePerformance) {
        Map<String, List<MavenBuildCachePerformanceGoalExecutionEntry>> tasksByOutcome = buildCachePerformance.getGoalExecution().stream()
            .collect(Collectors.groupingBy(
                t -> t.getAvoidanceOutcome().toString()
            ));

        Map<String, TaskExecutionSummary> summariesByOutcome = tasksByOutcome.entrySet()
            .stream()
            .map(GradleEnterpriseApiClient::summarizeForMaven)
            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

        Arrays.stream(MavenBuildCachePerformanceGoalExecutionEntry.AvoidanceOutcomeEnum.values())
            .forEach(outcome -> summariesByOutcome.putIfAbsent(outcome.toString(), TaskExecutionSummary.ZERO));

        return putTotalAvoidedFromCache(summariesByOutcome);
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

    private static Map<String, TaskExecutionSummary> putTotalAvoidedFromCache(Map<String, TaskExecutionSummary> summariesByOutcome) {
        TaskExecutionSummary fromLocalCache = summariesByOutcome.getOrDefault("avoided_from_local_cache", TaskExecutionSummary.ZERO);
        TaskExecutionSummary fromRemoteCache = summariesByOutcome.getOrDefault("avoided_from_remote_cache", TaskExecutionSummary.ZERO);

        summariesByOutcome.put("avoided_from_cache", fromLocalCache.plus(fromRemoteCache));
        return summariesByOutcome;
    }
}
