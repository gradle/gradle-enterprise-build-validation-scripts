package com.gradle;

import com.gradle.develocity.agent.maven.adapters.develocity.DevelocityApiAdapter;
import com.gradle.develocity.agent.maven.api.DevelocityApi;
import com.gradle.develocity.agent.maven.api.DevelocityListener;
import org.apache.maven.execution.MavenSession;
import org.codehaus.plexus.logging.Logger;

import javax.inject.Inject;

@SuppressWarnings("unused")
public class ConfigureDevelocity implements DevelocityListener {

    private static final String EXPERIMENT_DIR = System.getProperty("com.gradle.enterprise.build-validation.expDir");

    private final ConfigureDevelocityAdaptor configureDevelocityAdaptor;

    @Inject
    public ConfigureDevelocity(ConfigureDevelocityAdaptor configureDevelocityAdaptor, RootProjectExtractor rootProjectExtractor, Logger logger) {
        this.configureDevelocityAdaptor = configureDevelocityAdaptor;
    }

    @Override
    public void configure(DevelocityApi api, MavenSession session) {
        configureDevelocityAdaptor.configure(new DevelocityApiAdapter(api), session);
    }
}
