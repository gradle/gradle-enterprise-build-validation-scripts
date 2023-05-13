package com.gradle.enterprise.loader.online;

import com.google.common.base.Strings;
import com.gradle.enterprise.api.client.ApiClient;
import com.gradle.enterprise.loader.Logger;

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

    private static final String MALFORMED_ENVIRONMENT_VARIABLE_ERROR = "Environment variable " + EnvVars.ACCESS_KEY
            + " is malformed (expected format: 'server-host=access-key' or 'server-host1=access-key1;server-host2=access-key2')";

    public static void configureAuth(URL url, ApiClient client, Logger logger) {
        String username = System.getenv(EnvVars.USERNAME);
        String password = System.getenv(EnvVars.PASSWORD);

        if (!Strings.isNullOrEmpty(username) && !Strings.isNullOrEmpty(password)) {
            client.setUsername(username);
            client.setPassword(password);
            logger.debug("Using basic authentication.");
        } else {
            Optional<String> accessKey = lookupAccessKey(url, logger);
            accessKey.ifPresent(key -> {
              client.setBearerToken(key);
              logger.debug("Using access key authentication.");
            });

            if (!accessKey.isPresent()) {
                logger.debug("Using anonymous authentication.");
            }
        }
    }

    private static Optional<String> lookupAccessKey(URL url, Logger logger) {
        try {
            Properties accessKeysByHost = new Properties();
            accessKeysByHost.putAll(loadMavenHomeAccessKeys());
            accessKeysByHost.putAll(loadGradleHomeAccessKeys());
            accessKeysByHost.putAll(loadFromEnvVar());

            return Optional.ofNullable(accessKeysByHost.getProperty(url.getHost()));
        } catch (IOException e) {
            logger.debug("Error while trying to read access keys: " + e.getMessage() + ". Will try fetching build scan data without authentication.");
            logger.debug(e);
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
            if(entry == null) throw new RuntimeException(MALFORMED_ENVIRONMENT_VARIABLE_ERROR);

            String[] parts = entry.split("=", 2);
            if (parts.length < 2) throw new RuntimeException(MALFORMED_ENVIRONMENT_VARIABLE_ERROR);

            String joinedServers = parts[0].trim();
            String accessKey = parts[1].trim();

            if(joinedServers.isEmpty() || Strings.isNullOrEmpty(accessKey)) throw new RuntimeException(MALFORMED_ENVIRONMENT_VARIABLE_ERROR);
            for(String server: joinedServers.split(",")) {
                server = server.trim();
                if (server.isEmpty()) throw new RuntimeException(MALFORMED_ENVIRONMENT_VARIABLE_ERROR);
                accessKeys.put(server, accessKey);
            }
        }

        return accessKeys;
    }
}
