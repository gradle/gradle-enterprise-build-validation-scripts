#!/usr/bin/env bash

collect_project_details() {
  if [ -n "${_arg_git_url}" ]; then
     project_url=$_arg_git_url
  else
    echo
    read -r -p "${USER_ACTION_COLOR}What is the project's GitHub URL?${RESTORE} " project_url
  fi

  if [ -n "${_arg_branch}" ]; then
     project_branch=$_arg_branch
  else
     read -r -p "${USER_ACTION_COLOR}What branch should we checkout (press enter to use the project's default branch)?${RESTORE} " project_branch
  fi

  project_name=$(basename -s .git "${project_url}")
}

collect_gradle_task() { 
  if [ -z "$_arg_task" ]; then
    echo
    read -r -p "${USER_ACTION_COLOR}What Gradle task do you want to run?  (assemble)${RESTORE} " task

    if [[ "${task}" == "" ]]; then
      task=assemble
    fi
  else
    task=$_arg_task
  fi
}

collect_maven_goals() { 
  if [ -z "$_arg_task" ]; then
    echo
    read -r -p "${USER_ACTION_COLOR}What Maven goals do you want to run?  (package)${RESTORE} " task

    if [[ "${task}" == "" ]]; then
      task=package
    fi
  else
    task=$_arg_task
  fi
}

