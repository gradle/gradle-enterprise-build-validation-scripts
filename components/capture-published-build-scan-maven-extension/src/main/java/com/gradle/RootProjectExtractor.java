package com.gradle;

import org.apache.maven.execution.ExecutionEvent;
import org.apache.maven.execution.MavenExecutionRequest;
import org.apache.maven.execution.MavenSession;
import org.apache.maven.model.building.ModelProcessor;
import org.apache.maven.project.MavenProject;
import org.apache.maven.project.ProjectBuilder;
import org.apache.maven.project.ProjectBuildingException;
import org.codehaus.plexus.logging.Logger;

import javax.inject.Inject;
import java.io.File;
import java.util.*;

import static java.util.Collections.emptyList;

public class RootProjectExtractor {
    private final ProjectBuilder projectBuilder;
    private final ModelProcessor modelProcessor;
    private final Logger logger;

    @Inject
    public RootProjectExtractor(ProjectBuilder projectBuilder, ModelProcessor modelProcessor, Logger logger) {
        this.projectBuilder = projectBuilder;
        this.modelProcessor = modelProcessor;
        this.logger = logger;
    }

    public MavenProject extractRootProject(ExecutionEvent event) {
        List<MavenProject> allProjects = discoverAllProjects(event.getSession().getAllProjects());
        File workspaceDirectory = getWorkspaceDirectory(event.getSession());

        if (workspaceDirectory.equals(allProjects.get(0).getBasedir())) {
            return allProjects.get(0);
        }

        File workspaceDirectoryPom = modelProcessor.locatePom(workspaceDirectory);
        if (workspaceDirectoryPom.exists()) {
            try {
                return projectBuilder.build(workspaceDirectoryPom, event.getSession().getProjectBuildingRequest()).getProject();
            } catch (ProjectBuildingException e) {
                logger.error("Exception locating the top level project", e);
            }
        }

        // We didn't successfully identify the root project, so just return the first project.
        return allProjects.get(0);
    }

    private File getWorkspaceDirectory(MavenSession session) {
        MavenExecutionRequest request = session.getRequest();
        try {
            return request.getMultiModuleProjectDirectory();
        } catch (NoSuchMethodError ignored) {
            return new File(session.getExecutionRootDirectory());
        }
    }

    /**
     * Older Maven versions under-reported the list of discovered projects.
     * This method discovers all their submodules. For newer Maven versions it is a no-op.
     */
    private List<MavenProject> discoverAllProjects(Collection<MavenProject> sessionProjects) {
        Set<MavenProject> allProjects = new LinkedHashSet<>(sessionProjects);
        sessionProjects.stream().flatMap(p -> Optional.ofNullable(p.getCollectedProjects()).orElse(emptyList()).stream()).forEach(allProjects::add);
        return new ArrayList(allProjects);
    }
}
