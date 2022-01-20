package com.gradle.enterprise.export_api.client;

import com.google.common.collect.ImmutableMap;
import com.gradle.enterprise.api.GradleEnterpriseApi;
import com.gradle.enterprise.api.client.ApiClient;
import com.gradle.enterprise.api.client.ApiException;
import com.gradle.enterprise.api.model.Base;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.GradleBuildCachePerformanceTaskExecutionEntry;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenBuildCachePerformanceGoalExecutionEntry;

import java.net.URL;
import java.util.Arrays;
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

    public Map<String, Long> countTasksByAvoidanceOutcome(String buildScanId) {
        try {
            Base baseData = apiClient.getBuildsBase(buildScanId, null);
            if (baseData.getBuildToolType().equalsIgnoreCase("gradle")) {
                GradleBuildCachePerformance buildCachePerformance = apiClient.getGradleBuildCachePerformance(buildScanId, null);

                Map<String, Long> tasksByOutcome = buildCachePerformance.getTaskExecution().stream()
                    .collect(Collectors.groupingBy(
                        t -> t.getAvoidanceOutcome().toString(),
                        Collectors.counting()
                        ));

                Arrays.stream(GradleBuildCachePerformanceTaskExecutionEntry.AvoidanceOutcomeEnum.values())
                    .forEach(outcome -> tasksByOutcome.putIfAbsent(outcome.toString(), 0L));

                return tasksByOutcome;
            }
            if (baseData.getBuildToolType().equalsIgnoreCase("maven")) {
                MavenBuildCachePerformance buildCachePerformance = apiClient.getMavenBuildCachePerformance(buildScanId, null);

                Map<String, Long> tasksByOutcome = buildCachePerformance.getGoalExecution().stream()
                    .collect(Collectors.groupingBy(
                        t -> t.getAvoidanceOutcome().toString(),
                        Collectors.counting()
                    ));

                Arrays.stream(MavenBuildCachePerformanceGoalExecutionEntry.AvoidanceOutcomeEnum.values())
                    .forEach(outcome -> tasksByOutcome.putIfAbsent(outcome.toString(), 0L));

                return tasksByOutcome;
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
}
