package com.gradle.enterprise.export_api.client;

import com.google.common.base.Strings;
import com.google.common.net.HttpHeaders;
import com.gradle.enterprise.api.client.ApiClient;
import okhttp3.Authenticator;
import okhttp3.Credentials;

import java.io.BufferedReader;
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
        String username = System.getenv(EnvVars.USERNAME);
        String password = System.getenv(EnvVars.PASSWORD);
        if(!Strings.isNullOrEmpty(username) && !Strings.isNullOrEmpty(password)) {
            return basic(username, password);
        }

        return accessKey(lookupAccessKey(url));
    }

    public static void configureAuth(URL url, ApiClient client) {
        String username = System.getenv(EnvVars.USERNAME);
        String password = System.getenv(EnvVars.PASSWORD);

        if (!Strings.isNullOrEmpty(username) && !Strings.isNullOrEmpty(password)) {
            client.setUsername(username);
            client.setPassword(password);
        } else {
            client.setBearerToken(lookupAccessKey(url));
        }
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

            String encoded = Base64.getEncoder().encodeToString(accessKey.getBytes(StandardCharsets.UTF_8));

            return response.request().newBuilder()
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + encoded)
                .build();
        };
    }

    public static String lookupAccessKey(URL url) {
        try {
            Properties accessKeysByHost = new Properties();
            accessKeysByHost.putAll(loadMavenHomeAccessKeys());
            accessKeysByHost.putAll(loadGradleHomeAccessKeys());
            accessKeysByHost.putAll(loadFromEnvVar());

            if (!accessKeysByHost.containsKey(url.getHost())) {
                throw new AccessKeyNotFoundException(url);
            }
            return accessKeysByHost.getProperty(url.getHost());
        } catch (IOException e) {
            throw new AccessKeyNotFoundException(url, e);
        }
    }

    private static Properties loadGradleHomeAccessKeys() throws IOException {
        Path accessKeysFile = getGradleUserHomeDirectory().resolve("enterprise/keys.properties");
        return loadAccessKeysFromFile(accessKeysFile);
    }

    private static Path getGradleUserHomeDirectory() {
        if (Strings.isNullOrEmpty(System.getenv(EnvVars.GRADLE_USER_HOME))) {
            return Paths.get(System.getProperty("user.home"), ".gradle");
        }
        return Paths.get(System.getenv(EnvVars.GRADLE_USER_HOME));
    }

    private static Properties loadMavenHomeAccessKeys() throws IOException {
        Path accessKeysFile = getMavenStorageDirectory().resolve("keys.properties");
        return loadAccessKeysFromFile(accessKeysFile);
    }

    private static Path getMavenStorageDirectory() {
        String defaultLocation = System.getProperty("user.home") + "/.m2/.gradle-enterprise";
        return Paths.get(System.getProperty("gradle.enterprise.storage.directory", defaultLocation));
    }

    private static Properties loadAccessKeysFromFile(Path accessKeysFile) throws IOException {
        Properties accessKeysByHost = new Properties();
        if (Files.isRegularFile(accessKeysFile)) {
            try (BufferedReader in = Files.newBufferedReader(accessKeysFile)) {
                accessKeysByHost.load(in);
            }
        }
        return accessKeysByHost;
    }

    private static Properties loadFromEnvVar() {
        Properties accessKeys = new Properties();
        String value = System.getenv(EnvVars.ACCESS_KEY);

        if(Strings.isNullOrEmpty(value)) {
            return accessKeys;
        }

        String[] entries = value.split(";");
        for(String entry: entries) {
            if(entry == null) throw new MalformedEnvironmentVariableException();

            String[] parts = entry.split("=", 2);
            if (parts.length < 2) throw new MalformedEnvironmentVariableException();

            String joinedServers = parts[0].trim();
            String accessKey = parts[1].trim();

            if(joinedServers.isEmpty() || Strings.isNullOrEmpty(accessKey)) throw new MalformedEnvironmentVariableException();
            for(String server: joinedServers.split(",")) {
                server = server.trim();
                if (server.isEmpty()) throw new MalformedEnvironmentVariableException();
                accessKeys.put(server, accessKey);
            }
        }

        return accessKeys;
    }

    public static class MalformedEnvironmentVariableException extends ApiClientException {
        public MalformedEnvironmentVariableException() {
            super("Environment variable " + EnvVars.ACCESS_KEY + " is malformed (expected format: 'server-host=access-key' or 'server-host1=access-key1;server-host2=access-key2')");
        }
    }
}
