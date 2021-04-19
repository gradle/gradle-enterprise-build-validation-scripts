#!/usr/bin/env bash

save_config() {
  if [ ! -f "${_arg_config}" ]; then
    cat << EOF > "${_arg_config}"
GIT_URL="${project_url}"
GIT_BRANCH="${project_branch}"
BUILD_TASKS="${tasks}"
GE_SERVER="${_arg_server}"
ENABLE_GRADLE_ENTERPRISE="${_arg_enable_gradle_enterprise}"
EXTRA_ARGS=($(print_extra_args))
EOF
  fi
}

load_config() {
  if [ -f  "${_arg_config}" ]; then
    # shellcheck source=/dev/null # this file is created by the user so nothing for shellcheck to check
    source "${_arg_config}"

    if [ -z "${_arg_git_url}" ]; then
      _arg_git_url="${GIT_URL}"
    fi
    if [ -z "${_arg_branch}" ]; then
      _arg_branch="${GIT_BRANCH}"
    fi
    if [ -z "${_arg_tasks}" ]; then
      _arg_tasks="${BUILD_TASKS}"
    fi
    if [ -z "${_arg_server}" ]; then
      _arg_server="${GE_SERVER}"
    fi
    if [ "$_arg_enable_gradle_enterprise" == "off" ]; then
      _arg_enable_gradle_enterprise="${ENABLE_GRADLE_ENTERPRISE}"
    fi
    if [ ${#_arg_extra[@]} -eq 0 ]; then
      _arg_extra=("${EXTRA_ARGS[@]}")
    fi

    info
    info "Loaded configuration from ${_arg_config}"
  fi

  project_url=${_arg_git_url}
  project_branch=${_arg_branch}
  project_name=$(basename -s .git "${project_url}")
  tasks=${_arg_tasks}
}

validate_required_config() {
  if [ -z "${_arg_git_url}" ]; then
    error "Missing required argument: --git-url"
    echo
    print_help
    exit 1
  fi
  if [ -z "${_arg_tasks}" ]; then
    error "Missing required argument: --tasks"
    echo
    print_help
    exit 1
  fi

  if [ "$_arg_enable_gradle_enterprise" == "on" ]; then
    if [ -z "${_arg_server}" ]; then
      error "--server is requred when using --enable-gradle-enterprise."
      echo
      print_help
      exit 1
    fi
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
  if [ -z "$_arg_tasks" ]; then
    echo
    read -r -p "${USER_ACTION_COLOR}What build tasks should be run? (assemble)${RESTORE} " tasks

    if [[ "${task}" == "" ]]; then
      tasks=assemble
    fi
  else
    tasks=$_arg_tasks
  fi
}

collect_maven_goals() { 
  if [ -z "$_arg_tasks" ]; then
    echo
    read -r -p "${USER_ACTION_COLOR}What Maven goals should be run?  (package)${RESTORE} " tasks

    if [[ "${tasks}" == "" ]]; then
      task=package
    fi
  else
    tasks=$_arg_tasks
  fi
}

print_extra_args() {
  printf " %q" "${_arg_extra[@]}"
}
