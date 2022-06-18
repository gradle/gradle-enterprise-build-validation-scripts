package com.gradle.enterprise.proxy;

import com.gradle.enterprise.cli.ConsoleLogger;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;
import java.util.Properties;

public class NetworkingConfigurator {

    public static void configureNetworking(Optional<Path> networkSettingsFile, ConsoleLogger logger) {
        networkSettingsFile.ifPresent(path -> {
            try {
                configureBasedOnProperties(path, logger);
            } catch (IOException e) {
                logger.debug("Unable to load settings from %s: %s", path, e.getMessage());
                logger.debug(e);
            }
        });
    }

    private static void configureBasedOnProperties(Path networkSettingsFile, ConsoleLogger logger) throws IOException {
        if (Files.isRegularFile(networkSettingsFile)) {
            logger.debug("Loading network settings from " + networkSettingsFile.toAbsolutePath());
            Properties proxyProps = loadProperties(networkSettingsFile);
            proxyProps.stringPropertyNames().stream()
                .filter(NetworkingConfigurator::isNetworkingProperty)
                .forEach(key -> System.setProperty(key, proxyProps.getProperty(key)));
        }
    }

    private static boolean isNetworkingProperty(String key) {
        return isSslProperty(key) || isProxyProperty(key);
    }
    private static boolean isSslProperty(String key) {
        return key.startsWith("javax.net.ssl")
            || key.equals("allowUntrustedServer");
    }

    private static boolean isProxyProperty(String key) {
        return key.startsWith("http.proxy")
            || key.startsWith("https.proxy")
            || key.startsWith("socksProxy")
            || key.endsWith(".nonProxyHosts");
    }

    private static Properties loadProperties(Path propertiesFile) throws IOException {
        Properties properties = new Properties();
        try (BufferedReader in = Files.newBufferedReader(propertiesFile)) {
            properties.load(in);
            return properties;
        }
    }
}
