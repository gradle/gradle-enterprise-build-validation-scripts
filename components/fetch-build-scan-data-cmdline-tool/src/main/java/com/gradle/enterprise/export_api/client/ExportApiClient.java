package com.gradle.enterprise.export_api.client;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.common.base.Throwables;
import com.google.common.collect.ImmutableList;
import com.gradle.enterprise.*;
import okhttp3.Authenticator;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.sse.EventSource;
import okhttp3.sse.EventSourceListener;
import okhttp3.sse.EventSources;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.net.MalformedURLException;
import java.net.URL;
import java.time.Duration;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

public class ExportApiClient {
    private static final String BUILD_EVENT = "BuildEvent";

    private static class EventTypes {
        private static final String PROJECT_STRUCTURE = "ProjectStructure";
        private static final String BUILD_REQUESTED_TASKS = "BuildRequestedTasks";
        private static final String USER_NAMED_VALUE = "UserNamedValue";
        private static final String BUILD_FINISHED = "BuildFinished";
        private static final String BUILD_CACHE_CONFIGURATION = "BuildCacheConfiguration";
        private static final String MVN_PROJECT_STRUCTURE = "MvnProjectStructure";
        private static final String MVN_REQUESTED_GOALS = "MvnBuildRequestedGoals";
        private static final String MVN_USER_NAMED_VALUE = "MvnUserNamedValue";
        private static final String MVN_BUILD_FINISHED = "MvnBuildFinished";
        private static final String MVN_BUILD_CACHE_CONFIGURATION = "MvnBuildCacheConfiguration";
        private static final String ALL =
            PROJECT_STRUCTURE +
            "," + BUILD_REQUESTED_TASKS +
            "," + USER_NAMED_VALUE +
            "," + BUILD_FINISHED +
            "," + BUILD_CACHE_CONFIGURATION +
            "," + MVN_PROJECT_STRUCTURE +
            "," + MVN_REQUESTED_GOALS +
            "," + MVN_USER_NAMED_VALUE +
            "," + MVN_BUILD_FINISHED +
            "," + MVN_BUILD_CACHE_CONFIGURATION;
    }

    private static final ObjectMapper MAPPER = new ObjectMapper()
        .disable(DeserializationFeature.READ_DATE_TIMESTAMPS_AS_NANOSECONDS);

    private final OkHttpClient httpClient;
    private final URL baseUrl;
    private final EventSource.Factory eventSourceFactory;
    private final CustomValueNames customValueNames;

    public ExportApiClient(URL baseUrl, Authenticator authenticator, CustomValueNames customValueNames) {
        this.httpClient = new OkHttpClient.Builder()
            .connectTimeout(Duration.ZERO)
            .readTimeout(Duration.ZERO)
            .retryOnConnectionFailure(true)
            .authenticator(authenticator)
            .build();
        this.eventSourceFactory = EventSources.createFactory(httpClient);
        this.baseUrl = baseUrl;
        this.customValueNames = customValueNames;
    }

    public BuildValidationData fetchBuildValidationData(String buildScanId) {
        Request request = new Request.Builder()
            .url(endpointFor(buildScanId))
            .build();

        BuildValidationDataEventListener eventListener = new BuildValidationDataEventListener(baseUrl, buildScanId, customValueNames);
        eventSourceFactory.newEventSource(request, eventListener);
        return eventListener.getBuildValidationData();
    }

    private URL endpointFor(String buildScanId) {
        try {
            return new URL(baseUrl, "/build-export/v2/build/" + buildScanId + "/events?eventTypes=" + EventTypes.ALL);
        } catch (MalformedURLException e) {
            // It is highly unlikely this exception will ever be thrown. If it is thrown, then it is likely due to a
            // programming mistake (._.)
            throw new FetchingBuildScanUnexpectedException(buildScanId, baseUrl, e);
        }
    }

    private static class BuildValidationDataEventListener extends EventSourceListener {
        private final URL gradleEnterpriseServerUrl;
        private final String buildScanId;
        private final CustomValueNames customValueNames;
        private final GeApiTaskMetricsFetcher taskMetricsFetcher;

        private final CompletableFuture<String> rootProjectName = new CompletableFuture<>();
        private final CompletableFuture<String> gitUrl = new CompletableFuture<>();
        private final CompletableFuture<String> gitBranch = new CompletableFuture<>();
        private final CompletableFuture<String> gitCommitId = new CompletableFuture<>();
        private final CompletableFuture<List<String>> requestedTasks = new CompletableFuture<>();
        private final CompletableFuture<String> buildOutcome = new CompletableFuture<>();
        private final CompletableFuture<URL> remoteBuildCacheUrl = new CompletableFuture<>();

        private final List<CompletableFuture<?>> completables = ImmutableList.of(
            rootProjectName, gitUrl, gitBranch, gitCommitId, requestedTasks, buildOutcome);

        private BuildValidationDataEventListener(URL gradleEnterpriseServerUrl, String buildScanId, CustomValueNames customValueNames) {
            this.gradleEnterpriseServerUrl = gradleEnterpriseServerUrl;
            this.buildScanId = buildScanId;
            this.customValueNames = customValueNames;
            this.taskMetricsFetcher = new GeApiTaskMetricsFetcher(gradleEnterpriseServerUrl);
        }

        public BuildValidationData getBuildValidationData() {
            try {
                return new BuildValidationData(
                    rootProjectName.get(),
                    buildScanId,
                    gradleEnterpriseServerUrl,
                    gitUrl.get(),
                    gitBranch.get(),
                    gitCommitId.get(),
                    requestedTasks.get(),
                    buildOutcome.get(),
                    remoteBuildCacheUrl.get(),
                    taskMetricsFetcher.countTasksByAvoidanceOutcome(buildScanId)
                    );
            } catch (ExecutionException e) {
                if (e.getCause() == null) {
                    throw new FetchingBuildScanUnexpectedException(buildScanId, gradleEnterpriseServerUrl, e);
                } else {
                    Throwables.throwIfUnchecked(e.getCause());
                    throw new FetchingBuildScanUnexpectedException(buildScanId, gradleEnterpriseServerUrl, e.getCause());
                }
            } catch (InterruptedException e) {
                throw new FetchingBuildScanInterruptedException(buildScanId, gradleEnterpriseServerUrl, e);
            }
        }

        @Override
        public void onEvent(@NotNull EventSource eventSource, @Nullable String id, @Nullable String type, @NotNull String data) {
            if (BUILD_EVENT.equals(type)) {
                JsonNode event = toJsonNode(data);
                String eventType = event.get("type").get("eventType").asText();
                switch(eventType) {
                    case EventTypes.PROJECT_STRUCTURE:
                        onProjectStructure(event.get("data"), "rootProjectName");
                        break;
                    case EventTypes.MVN_PROJECT_STRUCTURE:
                        onProjectStructure(event.get("data"), "topLevelProjectName");
                        break;
                    case EventTypes.BUILD_REQUESTED_TASKS:
                        onBuildRequestedTasks(event.get("data"), "requested");
                        break;
                    case EventTypes.MVN_REQUESTED_GOALS:
                        onBuildRequestedTasks(event.get("data"), "goals");
                        break;
                    case EventTypes.USER_NAMED_VALUE:
                    case EventTypes.MVN_USER_NAMED_VALUE:
                        onUserNamedValue(event.get("data"));
                        break;
                    case EventTypes.BUILD_FINISHED:
                        onBuildFinished(event.get("data"));
                        break;
                    case EventTypes.MVN_BUILD_FINISHED:
                        onMvnBuildFinished(event.get("data"));
                        break;
                    case EventTypes.BUILD_CACHE_CONFIGURATION:
                        onBuildCacheConfiguration(event.get("data"));
                    case EventTypes.MVN_BUILD_CACHE_CONFIGURATION:
                        onMvnBuildCacheConfiguration(event.get("data"));
                }
            }
        }

        private void onProjectStructure(JsonNode eventData, String rootProjectPropertyName) {
            rootProjectName.complete(eventData.get(rootProjectPropertyName).asText());
        }

        private void onBuildRequestedTasks(JsonNode eventData, String requestedTasksProperty) {
            JsonNode requestedTasksNode = eventData.get(requestedTasksProperty);
            requestedTasks.complete(MAPPER.convertValue(requestedTasksNode, new TypeReference<List<String>>() {
            }));
        }

        private void onUserNamedValue(JsonNode eventData) {
            String key = eventData.get("key").asText();
            String value = eventData.get("value").asText();

            if (customValueNames.getGitRepositoryKey().equals(key)) {
                this.gitUrl.complete(value);
            }
            if (customValueNames.getGitBranchKey().equals(key)) {
                this.gitBranch.complete(value);
            }
            if (customValueNames.getGitCommitIdKey().equals(key)) {
                this.gitCommitId.complete(value);
            }
        }

        private void onBuildFinished(JsonNode eventData) {
            buildOutcome.complete(
                eventData.hasNonNull("failureId") || eventData.hasNonNull("failure") ? "FAILED" : "SUCCESS"
            );
        }

        private void onBuildCacheConfiguration(JsonNode eventData) {
            JsonNode remote = eventData.get("remote");
            if (remote.hasNonNull("config")) {
                JsonNode config = remote.get("config");
                if (config.hasNonNull("url")) {
                    String url = config.get("url").asText();
                    try {
                        remoteBuildCacheUrl.complete(new URL(url));
                    } catch (MalformedURLException e) {
                        // TODO maybe log out this failure
                        // Don't do anything on purpose. We'll return an empty URL later on in processing.
                    }
                }
            }
        }

        private void onMvnBuildCacheConfiguration(JsonNode eventData) {
            JsonNode remote = eventData.get("remote");
            if (remote.hasNonNull("url")) {
                String url = remote.get("url").asText();
                try {
                    remoteBuildCacheUrl.complete(new URL(url));
                } catch (MalformedURLException e) {
                    // TODO maybe log out this failure
                    // Don't do anything on purpose. We'll return an empty URL later on in processing.
                }
            }
        }

        private void onMvnBuildFinished(JsonNode eventData) {
            buildOutcome.complete(
                eventData.hasNonNull("failed") && eventData.get("failed").asBoolean() ? "FAILED" : "SUCCESS"
            );
        }

        @Override
        public void onClosed(@NotNull EventSource eventSource) {
            // If the event stream is closed before we have completed all of the completable futures, then we can
            // assume that the build scan doesn't have the data
            // CompletableFuture.complete() sets the value only if the CompletableFuture hasn't already been completed.
            rootProjectName.complete("");
            gitUrl.complete("");
            gitBranch.complete("");
            gitCommitId.complete("");
            requestedTasks.complete(Collections.emptyList());
            buildOutcome.complete("");
            remoteBuildCacheUrl.complete(null);
        }

        @Override
        public void onFailure(@NotNull EventSource eventSource, @Nullable Throwable t, @Nullable Response response) {
            Throwable error = t;
            if (error == null && response != null) {
                switch(response.code()) {
                    case StatusCodes.UNAUTHORIZED:
                        error = new AuthenticationFailedException(
                            buildScanId,
                            gradleEnterpriseServerUrl,
                            eventSource.request(),
                            response);
                        break;
                    case StatusCodes.NOT_FOUND:
                        error = new BuildScanNotFoundException(
                            buildScanId,
                            gradleEnterpriseServerUrl,
                            eventSource.request(),
                            response);
                        break;
                    default:
                        error = new UnexpectedResponseException(
                            buildScanId,
                            gradleEnterpriseServerUrl,
                            eventSource.request(),
                            response);
                }
            }

            for(CompletableFuture<?> completable: completables) completable.completeExceptionally(error);
            eventSource.cancel();
        }

        private JsonNode toJsonNode(String data) {
            try {
                return MAPPER.readTree(data);
            } catch (JsonProcessingException e) {
                throw new UnparsableBuildScanEventException(buildScanId, gradleEnterpriseServerUrl, data, e);
            }
        }
    }
}
