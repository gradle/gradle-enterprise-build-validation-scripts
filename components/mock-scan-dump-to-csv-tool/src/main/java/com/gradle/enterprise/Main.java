package com.gradle.enterprise;

public class Main {
    public static void main(String[] args) {
        final String headers = "Root Project Name,Gradle Enterprise Server,Build Scan,Build Scan ID,Git URL,Git Branch,Git Commit ID,Requested Tasks,Build Outcome,Remote Build Cache URL,Remote Build Cache Shard,Avoided Up To Date,Avoided up-to-date avoidance savings,Avoided from cache,Avoided from cache avoidance savings,Executed cacheable,Executed cacheable duration,Executed not cacheable,Executed not cacheable duration";
        final String scan1 = "java-ordered-properties,https://ge.solutions-team.gradle.com,https://ge.solutions-team.gradle.com/s/mbkuvmcoabzmw,mbkuvmcoabzmw,https://github.com/etiennestuder/java-ordered-properties,ge,b471d917952df7fcc2fab937d404365c4e3e4b4f,clean build,SUCCESS,,,1,0.000s,0,0.000s,3,1.806s,1,0.005s";
        final String scan2 = "java-ordered-properties,https://ge.solutions-team.gradle.com,https://ge.solutions-team.gradle.com/s/fugxcgswu2nqq,fugxcgswu2nqq,https://github.com/etiennestuder/java-ordered-properties,ge,b471d917952df7fcc2fab937d404365c4e3e4b4f,clean build,SUCCESS,,,1,0.000s,2,1.211s,9,0.565s,1,0.004s";
        System.out.println(String.join("\n", headers, scan1, scan2));
    }
}
