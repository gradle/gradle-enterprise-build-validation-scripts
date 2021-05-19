package com.gradle.enterprise;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;

public class CustomValueNames {
    public static final CustomValueNames DEFAULT = new CustomValueNames(
        "Git repository", "Git branch", "Git commit id"
    );

    public static CustomValueNames loadFromFile(Path customValueMappingFile) throws IOException {
        try (var in = Files.newBufferedReader(customValueMappingFile)) {
            var mappingProps = new Properties();
            mappingProps.load(in);
            return new CustomValueNames(
                mappingProps.getProperty("git.repository", DEFAULT.getGitRepositoryKey()),
                mappingProps.getProperty("git.branch", DEFAULT.getGitBranchKey()),
                mappingProps.getProperty("git.commitId", DEFAULT.getGitCommitIdKey())
            );
        }
    }

    private final String gitRepositoryKey;
    private final String gitBranchKey;
    private final String gitCommitIdKey;

    public CustomValueNames(String gitRepositoryKey, String gitBranchKey, String gitCommitIdKey) {
        this.gitRepositoryKey = gitRepositoryKey;
        this.gitBranchKey = gitBranchKey;
        this.gitCommitIdKey = gitCommitIdKey;
    }

    public String getGitRepositoryKey() {
        return gitRepositoryKey;
    }

    public String getGitBranchKey() {
        return gitBranchKey;
    }

    public String getGitCommitIdKey() {
        return gitCommitIdKey;
    }
}
