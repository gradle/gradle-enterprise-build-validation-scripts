package com.gradle.enterprise.network;

import com.gradle.enterprise.loader.Logger;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;

public class NetworkSettingsConfigurator {

    public static void configureNetworkSettings(Path networkSettingsFile, Logger logger) {
        try {
            configureBasedOnProperties(networkSettingsFile, logger);
        } catch (IOException e) {
            throw new RuntimeException(String.format("Failed to load network settings from %s.", networkSettingsFile.toAbsolutePath()), e);
        }
    }

    private static void configureBasedOnProperties(Path networkSettingsFile, Logger logger) throws IOException {
        if (Files.isRegularFile(networkSettingsFile)) {
            logger.debug("Loading network settings from " + networkSettingsFile.toAbsolutePath());
            Properties proxyProps = loadProperties(networkSettingsFile);
            proxyProps.stringPropertyNames().stream()
                .filter(NetworkSettingsConfigurator::isNetworkProperty)
                .forEach(key -> System.setProperty(key, proxyProps.getProperty(key)));
        }
    }

    private static boolean isNetworkProperty(String key) {
        return isSslProperty(key) || isProxyProperty(key) || isConnectionProperty(key);
    }
    private static boolean isSslProperty(String key) {
        return key.startsWith("javax.net.ssl")
            || key.equals("ssl.allowUntrustedServer");
    }

    private static boolean isProxyProperty(String key) {
        return key.startsWith("http.proxy")
            || key.startsWith("https.proxy")
            || key.startsWith("socksProxy")
            || key.endsWith(".nonProxyHosts");
    }

    private static boolean isConnectionProperty(String key) {
        return key.startsWith("connect") || key.startsWith("read");
    }

    private static Properties loadProperties(Path propertiesFile) throws IOException {
        Properties properties = new Properties();
        try (BufferedReader in = Files.newBufferedReader(propertiesFile)) {
            properties.load(in);
            return properties;
        }
    }
}
