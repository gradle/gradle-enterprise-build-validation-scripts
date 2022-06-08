package com.gradle.enterprise.proxy;

import com.gradle.enterprise.cli.ConsoleLogger;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;
import java.util.Properties;

public class ProxyServerConfigurator {

    public static void configureProxyServers(Optional<Path> proxySettingsFile, ConsoleLogger logger) {
        try {
            if(proxySettingsFile.isPresent()) {
                configureBasedOnProxyProperties(proxySettingsFile.get(), logger);
            }
        } catch (IOException e) {
            logger.debug("Unable to load proxy settings from gradle.properties: " + e.getMessage());
            logger.debug(e);
        }
    }

    private static void configureBasedOnProxyProperties(Path proxySettingsFile, ConsoleLogger logger) throws IOException {
        if (Files.isRegularFile(proxySettingsFile)) {
            logger.debug("Loading proxy settings from " + proxySettingsFile.toAbsolutePath());
            Properties proxyProps = loadProperties(proxySettingsFile);
            proxyProps.stringPropertyNames().stream()
                .filter(ProxyServerConfigurator::isProxyProperty)
                .forEach(key -> System.setProperty(key, proxyProps.getProperty(key)));
        }
    }

    private static boolean isProxyProperty(String key) {
        return key.startsWith("http.proxy")
            || key.startsWith("https.proxy")
            || key.startsWith("socksProxy")
            || key.endsWith(".nonProxyHosts");
    }

    private static Properties loadProperties(Path propertiesFIle) throws IOException {
        Properties properties = new Properties();
        try (BufferedReader in = Files.newBufferedReader(propertiesFIle)) {
            properties.load(in);
            return properties;
        }
    }
}
