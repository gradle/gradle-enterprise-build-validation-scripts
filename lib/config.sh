#!/usr/bin/env bash

save_settings() {
  if [ ! -f "${_arg_config}" ]; then
    cat << EOF > "${_arg_config}"
GIT_URL="${project_url}"
GIT_BRANCH="${project_branch}"
GRADLE_TASK="${task}"
GE_SERVER="${_arg_server}"
EOF
  fi
}

load_settings() {
  if [ -f  "${_arg_config}" ]; then
    # shellcheck source=/dev/null # this file is created by the user so nothing for shellcheck to check
    source "${_arg_config}"

    if [ -z "${_arg_git_url}" ]; then
      _arg_git_url="${GIT_URL}"
    fi
    if [ -z "${_arg_branch}" ]; then
      _arg_branch="${GIT_BRANCH}"
    fi
    if [ -z "${_arg_task}" ]; then
      _arg_task="${GRADLE_TASK}"
    fi
    if [ -z "${_arg_server}" ]; then
      _arg_server="${GE_SERVER}"
    fi

    info
    info "Loaded configuration from ${_arg_config}"
  fi

  project_url=${_arg_git_url}
  project_branch=${_arg_branch}
  project_name=$(basename -s .git "${project_url}")
  task=${_arg_task}
}

validate_required_config() {
  if [ -z "${_arg_git_url}" ]; then
    error "Missing required argument: --git-url"
    echo
    print_help
    exit 1
  fi
  if [ -z "${_arg_task}" ]; then
    error "Missing required argument: --task"
    echo
    print_help
    exit 1
  fi
}

collect_project_details() {
  if [ -n "${_arg_git_url}" ]; then
     project_url=$_arg_git_url
  else
    echo
    read -r -p "${USER_ACTION_COLOR}What is the project's Git URL?${RESTORE} " project_url
  fi

  if [ -n "${_arg_branch}" ]; then
     project_branch=$_arg_branch
  else
     read -r -p "${USER_ACTION_COLOR}What is the project's branch to check out? (the project's default branch)${RESTORE} " project_branch
  fi

  project_name=$(basename -s .git "${project_url}")
}

collect_gradle_task() { 
  if [ -z "$_arg_task" ]; then
    echo
    read -r -p "${USER_ACTION_COLOR}What Gradle task do you want to run? (assemble)${RESTORE} " task

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

