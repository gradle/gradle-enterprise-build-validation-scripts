package com.gradle;

import com.gradle.develocity.agent.maven.adapters.develocity.DevelocityApiAdapter;
import com.gradle.develocity.agent.maven.api.DevelocityApi;
import com.gradle.develocity.agent.maven.api.DevelocityListener;
import org.apache.maven.execution.MavenSession;

import javax.inject.Inject;

public class ConfigureDevelocity implements DevelocityListener {

    private final ConfigureDevelocityAdaptor configureDevelocityAdaptor;

    @Inject
    public ConfigureDevelocity(ConfigureDevelocityAdaptor configureDevelocityAdaptor, RootProjectExtractor rootProjectExtractor) {
        this.configureDevelocityAdaptor = configureDevelocityAdaptor;
    }

    @Override
    public void configure(DevelocityApi api, MavenSession session) {
        configureDevelocityAdaptor.configure(new DevelocityApiAdapter(api), session);
    }
}
