package com.gradle.enterprise.api.client;

import com.google.common.base.Strings;

import java.io.BufferedReader;
import java.io.IOException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Optional;
import java.util.Properties;

public class AuthenticationConfigurator {
    public static final class EnvVars {
        public static final String ACCESS_KEY = "GRADLE_ENTERPRISE_ACCESS_KEY";
        public static final String USERNAME = "GRADLE_ENTERPRISE_USERNAME";
        public static final String PASSWORD = "GRADLE_ENTERPRISE_PASSWORD";
        public static final String GRADLE_USER_HOME = "GRADLE_USER_HOME";
    }

    public static void configureAuth(URL url, ApiClient client, boolean debug) {
        String username = System.getenv(EnvVars.USERNAME);
        String password = System.getenv(EnvVars.PASSWORD);

        if (!Strings.isNullOrEmpty(username) && !Strings.isNullOrEmpty(password)) {
            client.setUsername(username);
            client.setPassword(password);
            if (debug) {
                System.err.println("Using basic authentication.");
            }
        } else {
            Optional<String> accessKey = lookupAccessKey(url, debug);
            accessKey.ifPresent(key -> {
              client.setBearerToken(key);
              if (debug) {
                  System.err.println("Using access key authentication.");
              }
            });

            if (!accessKey.isPresent() && debug) {
                System.err.println("Using anonymous authentication.");
            }
        }
    }

    private static Optional<String> lookupAccessKey(URL url, boolean debug) {
        try {
            Properties accessKeysByHost = new Properties();
            accessKeysByHost.putAll(loadMavenHomeAccessKeys());
            accessKeysByHost.putAll(loadGradleHomeAccessKeys());
            accessKeysByHost.putAll(loadFromEnvVar());

            return Optional.ofNullable(accessKeysByHost.getProperty(url.getHost()));
        } catch (IOException e) {
            if (debug) {
                System.err.println("Error whole trying to read access keys: " + e.getMessage() + ". Will try fetching build scan data without authentication.");
                e.printStackTrace(System.err);
            }
            return Optional.empty();
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
