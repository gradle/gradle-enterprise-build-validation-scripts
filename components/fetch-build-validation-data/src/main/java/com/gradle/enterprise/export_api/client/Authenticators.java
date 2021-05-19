package com.gradle.enterprise.export_api.client;

import com.google.common.base.Strings;
import com.google.common.net.HttpHeaders;
import okhttp3.Authenticator;
import okhttp3.Credentials;

import java.io.IOException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.Properties;

public class Authenticators {
    public static final class EnvVars {
        public static final String ACCESS_KEY = "GRADLE_ENTERPRISE_ACCESS_KEY";
        public static final String USERNAME = "GRADLE_ENTERPRISE_USERNAME";
        public static final String PASSWORD = "GRADLE_ENTERPRISE_PASSWORD";
        public static final String GRADLE_USER_HOME = "GRADLE_USER_HOME";
    }

    public static Authenticator createForUrl(URL url) {
        var accessKey = System.getenv(EnvVars.ACCESS_KEY);
        if(!Strings.isNullOrEmpty(accessKey)) {
            return accessKey(accessKey);
        }

        var username = System.getenv(EnvVars.USERNAME);
        var password = System.getenv(EnvVars.PASSWORD);
        if(!Strings.isNullOrEmpty(username) && !Strings.isNullOrEmpty(password)) {
            return basic(username, password);
        }

        return accessKey(lookupAccessKey(url));
    }

    public static Authenticator basic(String username, String password) {
        return (route, response) -> {
            if (response.request().header(HttpHeaders.AUTHORIZATION) != null) {
                return null; // Give up, we've already attempted to authenticate.
            }

            return response.request().newBuilder()
                .header(HttpHeaders.AUTHORIZATION, Credentials.basic(username, password))
                .build();
        };
    }

    public static Authenticator accessKey(String accessKey) {
        return (route, response) -> {
            if (response.request().header(HttpHeaders.AUTHORIZATION) != null) {
                return null; // Give up, we've already attempted to authenticate.
            }

            var encoded = Base64.getEncoder().encodeToString(accessKey.getBytes(StandardCharsets.UTF_8));

            return response.request().newBuilder()
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + encoded)
                .build();
        };
    }

    public static String lookupAccessKey(URL url) {
        var accessKeysFile = getGradleUserHomeDirectory().resolve("enterprise/keys.properties");

        if (Files.isRegularFile(accessKeysFile)) {
            try (var in = Files.newBufferedReader(accessKeysFile)) {
                var accessKeys = new Properties();
                accessKeys.load(in);

                if (!accessKeys.containsKey(url.getHost())) {
                    throw new AccessKeyNotFoundException(url);
                }
                return accessKeys.getProperty(url.getHost());
            } catch (IOException e) {
                throw new AccessKeyNotFoundException(url, e);
            }
        }
        throw new AccessKeyNotFoundException(url);
    }

    private static Path getGradleUserHomeDirectory() {
        if (Strings.isNullOrEmpty(System.getenv(EnvVars.GRADLE_USER_HOME))) {
            return Paths.get(System.getProperty("user.home"), ".gradle");
        }
        return Paths.get(System.getenv(EnvVars.GRADLE_USER_HOME));
    }
}
