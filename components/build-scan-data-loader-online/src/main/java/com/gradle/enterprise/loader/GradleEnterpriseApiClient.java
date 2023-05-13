package com.gradle.enterprise.loader;

import com.gradle.enterprise.api.GradleEnterpriseApi;
import com.gradle.enterprise.api.client.ApiClient;
import com.gradle.enterprise.api.client.ApiException;
import com.gradle.enterprise.api.model.*;
import com.gradle.enterprise.loader.BuildScanDataLoader.BuildScanData;
import okhttp3.Credentials;
import okhttp3.OkHttpClient;
import okhttp3.tls.HandshakeCertificates;

import java.net.URISyntaxException;
import java.net.URL;
import java.time.Duration;
import java.time.format.DateTimeParseException;
import java.util.Locale;
import java.util.Optional;

public class GradleEnterpriseApiClient {

    private final URL baseUrl;
    private final GradleEnterpriseApi apiClient;

    public GradleEnterpriseApiClient(URL baseUrl, Logger logger) {
        this.baseUrl = baseUrl;

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
        configureTimeouts(httpClientBuilder);

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

    private void configureTimeouts(OkHttpClient.Builder httpClientBuilder) {
        Duration connectTimeout = parseTimeout("connect.timeout");
        if (connectTimeout != null) {
            httpClientBuilder.connectTimeout(connectTimeout);
        }
        Duration readTimeout = parseTimeout("read.timeout");
        if (readTimeout != null) {
            httpClientBuilder.readTimeout(readTimeout);
        }
    }

    private Duration parseTimeout(String key) {
        String value = System.getProperty(key);
        try {
            return value == null ? null : Duration.parse(value);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("The value of " + key + " (\"" + value + "\") is not a valid duration.", e);
        }
    }

    public String fetchBuildToolType(String buildScanId) throws ApiException {
        Build build = apiClient.getBuild(buildScanId, null);
        return build.getBuildToolType();
    }

    public BuildScanData<GradleAttributes, GradleBuildCachePerformance> loadDataForGradle(String buildScanId) throws ApiException {
        GradleAttributes attributes = apiClient.getGradleAttributes(buildScanId, null);
        GradleBuildCachePerformance buildCachePerformance = apiClient.getGradleBuildCachePerformance(buildScanId, null);

        try {
            return new BuildScanData<>(Optional.of(baseUrl.toURI()), attributes, buildCachePerformance);
        } catch (URISyntaxException e) {
            // Should never get here
            throw new RuntimeException(e);
        }
    }

    public BuildScanData<MavenAttributes, MavenBuildCachePerformance> loadDataForMaven(String buildScanId) throws ApiException {
        MavenAttributes attributes = apiClient.getMavenAttributes(buildScanId, null);
        MavenBuildCachePerformance buildCachePerformance = apiClient.getMavenBuildCachePerformance(buildScanId, null);

        try {
            return new BuildScanData<>(Optional.of(baseUrl.toURI()), attributes, buildCachePerformance);
        } catch (URISyntaxException e) {
            // Should never get here
            throw new RuntimeException(e);
        }
    }
}
