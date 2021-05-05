package com.gradle.enterprise;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

public class ExportApiClient {
    private static final String BUILD_EVENT = "BuildEvent";
    private static class EventTypes {
        private static final String BUILD_REQUESTED_TASKS = "BuildRequestedTasks";
        private static final String USER_NAMED_VALUE = "UserNamedValue";
        private static final String BUILD_FINISHED = "BuildFinished";
        private static final String ALL = BUILD_REQUESTED_TASKS + "," + USER_NAMED_VALUE + "," + BUILD_FINISHED;
    }

    private static final ObjectMapper MAPPER = new ObjectMapper()
        .disable(DeserializationFeature.READ_DATE_TIMESTAMPS_AS_NANOSECONDS);

    private final OkHttpClient httpClient;
    private final URL baseUrl;
    private final EventSource.Factory eventSourceFactory;

    public ExportApiClient(URL baseUrl, Authenticator authenticator) {
        this.httpClient = new OkHttpClient.Builder()
            .connectTimeout(Duration.ZERO)
            .readTimeout(Duration.ZERO)
            .retryOnConnectionFailure(true)
            .authenticator(authenticator)
            .build();
        this.eventSourceFactory = EventSources.createFactory(httpClient);
        this.baseUrl = baseUrl;
    }

    public BuildValidationData fetchBuildValidationData(String buildScanId) throws Exception {
        var request = new Request.Builder()
            .url(endpointFor(buildScanId))
            .build();

        var eventListener = new BuildValidationDataEventListener(baseUrl, buildScanId);
        eventSourceFactory.newEventSource(request, eventListener);
        return eventListener.getBuildValidationData();
    }

    private URL endpointFor(String buildScanId) {
        try {
            return new URL(baseUrl, "/build-export/v1/build/" + buildScanId + "/events?eventTypes=" + EventTypes.ALL);
        } catch (MalformedURLException e) {
            // TODO do something better here
            throw new RuntimeException(e.getMessage(), e);
        }
    }

    private static class BuildValidationDataEventListener extends EventSourceListener {
        private final URL gradleEnterpriseServerUrl;
        private final String buildScanId;
        private final CompletableFuture<String> commitId = new CompletableFuture<>();
        private final CompletableFuture<List<String>> requestedTasks = new CompletableFuture<>();
        private final CompletableFuture<Boolean> buildSuccessful = new CompletableFuture<>();

        private BuildValidationDataEventListener(URL gradleEnterpriseServerUrl, String buildScanId) {
            this.gradleEnterpriseServerUrl = gradleEnterpriseServerUrl;
            this.buildScanId = buildScanId;
        }

        public BuildValidationData getBuildValidationData() throws ExecutionException, InterruptedException {
            return new BuildValidationData(buildScanId, gradleEnterpriseServerUrl, commitId.get(), requestedTasks.get(), buildSuccessful.get());
        }

        @Override
        public void onEvent(@NotNull EventSource eventSource, @Nullable String id, @Nullable String type, @NotNull String data) {
            if (BUILD_EVENT.equals(type)) {
                var event = toJsonNode(data);
                var eventType = event.get("type").get("eventType").asText();
                if (EventTypes.BUILD_REQUESTED_TASKS.equals(eventType)) {
                    onBuildRequestedTasks(event.get("data"));
                }
                if (EventTypes.USER_NAMED_VALUE.equals(eventType)) {
                    onUserNamedValue(event.get("data"));
                }
                if (EventTypes.BUILD_FINISHED.equals(eventType)) {
                    onBuildFinished(event.get("data"));
                }
            }
        }

        private void onBuildRequestedTasks(JsonNode eventData) {
            var requestedTasksNode = eventData.get("requested");
            requestedTasks.complete(MAPPER.convertValue(requestedTasksNode, new TypeReference<List<String>>() {
            }));
        }

        private void onUserNamedValue(JsonNode eventData) {
            var key = eventData.get("key").asText();
            var value = eventData.get("value").asText();
            if ("Git commit id".equals(key)) {
                this.commitId.complete(value);
            }
        }

        private void onBuildFinished(JsonNode eventData) {
            buildSuccessful.complete(
                !eventData.hasNonNull("failure")
            );
        }

        @Override
        public void onClosed(@NotNull EventSource eventSource) {
            // If the event stream is closed before we have completed all of the completeable futures, then we can
            // assume that the build scan doesn't have that data

            // TODO Fail with completeExceptionally instead?
            // complete set the value only if the CompletableFuture hasn't already been completed.
            commitId.complete("");
            requestedTasks.complete(Collections.emptyList());
            buildSuccessful.complete(false);
        }

        @Override
        public void onFailure(@NotNull EventSource eventSource, @Nullable Throwable t, @Nullable Response response) {
            if (t != null) throw new RuntimeException(t.getMessage(), t);
            if (response != null && !response.isSuccessful())
                throw new RuntimeException("The response was not successful. Response:" + response.toString());
        }

        private JsonNode toJsonNode(String data) {
            try {
                return MAPPER.readTree(data);
            } catch (JsonProcessingException e) {
                // TODO throw a better exception
                throw new RuntimeException(e);
            }
        }
    }
}
