package com.gradle.enterprise.api.client;

import com.gradle.enterprise.api.GradleEnterpriseApi;
import com.gradle.enterprise.api.model.Build;
import com.gradle.enterprise.api.model.BuildAttributesValue;
import com.gradle.enterprise.api.model.GradleAttributes;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.GradleBuildCachePerformanceTaskExecutionEntry;
import com.gradle.enterprise.api.model.MavenAttributes;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenBuildCachePerformanceGoalExecutionEntry;
import com.gradle.enterprise.cli.ConsoleLogger;
import com.gradle.enterprise.model.BuildValidationData;
import com.gradle.enterprise.model.CustomValueNames;
import com.gradle.enterprise.model.TaskExecutionSummary;
import okhttp3.Credentials;
import okhttp3.OkHttpClient;
import okhttp3.tls.HandshakeCertificates;
import org.jetbrains.annotations.NotNull;

import java.math.BigDecimal;
import java.net.MalformedURLException;
import java.net.URL;
import java.time.Duration;
import java.util.AbstractMap;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

import static com.gradle.enterprise.api.model.GradleBuildCachePerformanceTaskExecutionEntry.AvoidanceOutcomeEnum.EXECUTED_CACHEABLE;
import static com.gradle.enterprise.api.model.GradleBuildCachePerformanceTaskExecutionEntry.AvoidanceOutcomeEnum.EXECUTED_NOT_CACHEABLE;
import static com.gradle.enterprise.api.model.GradleBuildCachePerformanceTaskExecutionEntry.NonCacheabilityCategoryEnum.DISABLED_TO_ENSURE_CORRECTNESS;
import static com.gradle.enterprise.api.model.GradleBuildCachePerformanceTaskExecutionEntry.NonCacheabilityCategoryEnum.OVERLAPPING_OUTPUTS;

public class GradleEnterpriseApiClient {

    private final URL baseUrl;
    private final GradleEnterpriseApi apiClient;

    private final CustomValueNames customValueNames;

    private final ConsoleLogger logger;

    public GradleEnterpriseApiClient(URL baseUrl, CustomValueNames customValueNames, ConsoleLogger logger) {
        this.baseUrl = baseUrl;
        this.customValueNames = customValueNames;
        this.logger = logger;

        ApiClient client = new ApiClient();
        client.setHttpClient(configureHttpClient(client.getHttpClient()));
        client.setBasePath(baseUrl.toString());
        AuthenticationConfigurator.configureAuth(baseUrl, client, logger);

        this.apiClient = new GradleEnterpriseApi(client);
    }

    private OkHttpClient configureHttpClient(OkHttpClient httpClient) {
        OkHttpClient.Builder httpClientBuilder = httpClient.newBuilder();

        configureSsl(httpClientBuilder);
        configureProxyAuthentication(httpClientBuilder);

        return httpClientBuilder.build();
    }

    private void configureSsl(OkHttpClient.Builder httpClientBuilder) {
        HandshakeCertificates.Builder trustedCertsBuilder = new HandshakeCertificates.Builder()
            .addPlatformTrustedCertificates();

        if (allowUntrustedServer()) {
            trustedCertsBuilder.addInsecureHost(baseUrl.getHost());
            httpClientBuilder.hostnameVerifier((hostname, session) -> baseUrl.getHost().equals(hostname));
        }

        HandshakeCertificates trustedCerts = trustedCertsBuilder.build();
        httpClientBuilder.sslSocketFactory(trustedCerts.sslSocketFactory(), trustedCerts.trustManager());
    }

    private void configureProxyAuthentication(OkHttpClient.Builder httpClientBuilder) {
        httpClientBuilder
            .proxyAuthenticator((route, response) -> {
                if (response.code() == 407) {
                    String scheme = response.request().url().scheme().toLowerCase(Locale.ROOT);
                    String proxyUser = System.getProperty(scheme + ".proxyUser");
                    String proxyPassword = System.getProperty(scheme + ".proxyPassword");
                    if (proxyUser != null && proxyPassword != null) {
                        return response.request().newBuilder()
                            .header("Proxy-Authorization", Credentials.basic(proxyUser, proxyPassword))
                            .build();
                    }
                }
                return null;
            });
    }

    private boolean allowUntrustedServer() {
        return Boolean.parseBoolean(System.getProperty("ssl.allowUntrustedServer"));
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
                    summarizeTaskExecutions(buildCachePerformance),
                    toDuration(buildCachePerformance.getEffectiveTaskExecutionTime()),
                    BigDecimal.valueOf(buildCachePerformance.getSerializationFactor()));
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
                    summarizeTaskExecutions(buildCachePerformance),
                    toDuration(buildCachePerformance.getEffectiveProjectExecutionTime()),
                    BigDecimal.valueOf(buildCachePerformance.getSerializationFactor()));
            }
            throw new UnknownBuildAgentException(baseUrl, buildScanId, build.getBuildToolType());
        } catch (ApiException e) {
            switch(e.getCode()) {
                case StatusCodes.NOT_FOUND:
                    throw new BuildScanNotFoundException(baseUrl, buildScanId, e.getCode(), e.getResponseBody(), e);
                case StatusCodes.UNAUTHORIZED:
                    throw new AuthenticationFailedException(baseUrl, buildScanId, e.getCode(), e.getResponseBody(), e);
                case 0:
                    throw new ConnectionFailedException(baseUrl, buildScanId, e);
                default:
                    throw new UnexpectedResponseException(baseUrl, buildScanId, e.getCode(), e.getResponseBody(), e);
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
            buildCachePerformance.getBuildCaches().getRemote().getUrl() == null) {
            return null;
        }

        try {
            return new URL(buildCachePerformance.getBuildCaches().getRemote().getUrl());
        } catch (MalformedURLException e) {
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
            // Don't do anything on purpose.
            return null;
        }
    }

    @NotNull
    private Map<String, TaskExecutionSummary> summarizeTaskExecutions(GradleBuildCachePerformance buildCachePerformance) {
        Map<String, List<GradleBuildCachePerformanceTaskExecutionEntry>> tasksByOutcome = buildCachePerformance.getTaskExecution().stream()
            .collect(Collectors.groupingBy(this::avoidanceOutcome));

        Map<String, TaskExecutionSummary> summariesByOutcome = tasksByOutcome.entrySet()
            .stream()
            .map(GradleEnterpriseApiClient::summarizeForGradle)
            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

        Arrays.stream(GradleBuildCachePerformanceTaskExecutionEntry.AvoidanceOutcomeEnum.values())
            .forEach(outcome -> summariesByOutcome.putIfAbsent(outcome.toString(), TaskExecutionSummary.ZERO));

        return putTotalAvoidedFromCache(summariesByOutcome);
    }

    private String avoidanceOutcome(GradleBuildCachePerformanceTaskExecutionEntry task) {
        GradleBuildCachePerformanceTaskExecutionEntry.AvoidanceOutcomeEnum avoidanceOutcome = task.getAvoidanceOutcome();
        GradleBuildCachePerformanceTaskExecutionEntry.NonCacheabilityCategoryEnum nonCacheabilityCategory = task.getNonCacheabilityCategory();
        if (avoidanceOutcome == EXECUTED_NOT_CACHEABLE && (nonCacheabilityCategory == OVERLAPPING_OUTPUTS || nonCacheabilityCategory == DISABLED_TO_ENSURE_CORRECTNESS)) {
            return EXECUTED_CACHEABLE.toString();
        }
        return avoidanceOutcome.toString();
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
        return tasks.stream()
            .reduce(TaskExecutionSummary.ZERO, (summary, task) ->
               new TaskExecutionSummary(
                   summary.totalTasks() + 1,
                   summary.totalDuration().plus(toDuration(task.getDuration())),
                   summary.totalAvoidanceSavings().plus(toDuration(task.getAvoidanceSavings()))),
                TaskExecutionSummary::plus
            );
    }

    private static Map.Entry<String, TaskExecutionSummary> summarizeForMaven(Map.Entry<String, List<MavenBuildCachePerformanceGoalExecutionEntry>> entry) {
        return new AbstractMap.SimpleEntry<>(entry.getKey(), summarizeForMaven(entry.getValue()));
    }

    private static TaskExecutionSummary summarizeForMaven(List<MavenBuildCachePerformanceGoalExecutionEntry> tasks) {
        return tasks.stream()
            .reduce(TaskExecutionSummary.ZERO, (summary, task) ->
                    new TaskExecutionSummary(
                        summary.totalTasks() + 1,
                        summary.totalDuration().plus(toDuration(task.getDuration())),
                        summary.totalAvoidanceSavings().plus(toDuration(task.getAvoidanceSavings()))),
                TaskExecutionSummary::plus
            );
    }

    private static Duration toDuration(Long millis) {
        if (millis == null) {
            return Duration.ZERO;
        }
        return Duration.ofMillis(millis);
    }

    private static Map<String, TaskExecutionSummary> putTotalAvoidedFromCache(Map<String, TaskExecutionSummary> summariesByOutcome) {
        TaskExecutionSummary fromLocalCache = summariesByOutcome.getOrDefault("avoided_from_local_cache", TaskExecutionSummary.ZERO);
        TaskExecutionSummary fromRemoteCache = summariesByOutcome.getOrDefault("avoided_from_remote_cache", TaskExecutionSummary.ZERO);

        summariesByOutcome.put("avoided_from_cache", fromLocalCache.plus(fromRemoteCache));
        return summariesByOutcome;
    }
}
