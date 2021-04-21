#!/usr/bin/env bash

save_config() {
    cat << EOF > "${SCRIPT_DIR}/${SCRIPT_NAME%.*}.config"
GIT_URL="${git_repo}"
GIT_BRANCH="${project_branch}"
BUILD_TASKS="${tasks}"
GE_SERVER="${ge_server}"
ENABLE_GRADLE_ENTERPRISE="${enable_ge}"
EXTRA_ARGS=$(printf "%q" "${extra_args}")
EOF
}

load_config() {
  if [ -f  "${_arg_config}" ]; then
    # shellcheck source=/dev/null # this file is created by the user so nothing for shellcheck to check
    source "${_arg_config}"

    if [ -z "${_arg_git_repo}" ]; then
      _arg_git_repo="${GIT_URL}"
    fi
    if [ -z "${_arg_git_branch}" ]; then
      _arg_git_branch="${GIT_BRANCH}"
    fi
    if [ -z "${_arg_tasks}" ]; then
      _arg_tasks="${BUILD_TASKS}"
    fi
    if [ -z "${_arg_gradle_enterprise_server}" ]; then
      _arg_gradle_enterprise_server="${GE_SERVER}"
    fi
    if [ "$_arg_enable_gradle_enterprise" == "off" ]; then
      _arg_enable_gradle_enterprise="${ENABLE_GRADLE_ENTERPRISE}"
    fi
    if [ -z "${_arg_args}" ]; then
      _arg_args="${EXTRA_ARGS}"
    fi

    info
    info "Loaded configuration from ${_arg_config}"
  fi

  git_repo="${_arg_git_repo}"
  project_branch="${_arg_git_branch}"
  project_name="$(basename -s .git "${git_repo}")"
  tasks="${_arg_tasks}"
  extra_args="${_arg_args}"
  enable_ge="${_arg_enable_gradle_enterprise}"
  ge_server="${_arg_gradle_enterprise_server}"
}

validate_required_config() {
  if [ -z "${git_repo}" ]; then
    error "Missing required argument: --git-repo"
    echo
    print_help
    exit 1
  fi
  if [ -z "${tasks}" ]; then
    error "Missing required argument: --tasks"
    echo
    print_help
    exit 1
  fi

  if [ "${enable_ge}" == "on" ]; then
    if [ -z "${ge_server}" ]; then
      error "--gradle-enterprise-server is requred when using --enable-gradle-enterprise."
      echo
      print_help
      exit 1
    fi
  fi
}

collect_project_details() {
  if [ -n "${_arg_git_repo}" ]; then
     git_repo=$_arg_git_repo
  else
    echo
    read -r -p "${USER_ACTION_COLOR}What is the project's Git URL?${RESTORE} " git_repo
  fi

  if [ -n "${_arg_git_branch}" ]; then
     project_branch=$_arg_git_branch
  else
     read -r -p "${USER_ACTION_COLOR}What is the project's branch to check out? ${DIM}(the project's default branch)${RESTORE} " project_branch
  fi

  project_name=$(basename -s .git "${git_repo}")
}

collect_gradle_task() { 
  if [ -z "$_arg_tasks" ]; then
    echo
    read -r -p "${USER_ACTION_COLOR}What build tasks should be run? ${DIM}(assemble)${RESTORE} " tasks

    if [[ "${tasks}" == "" ]]; then
      tasks=assemble
    fi
  else
    tasks=$_arg_tasks
  fi
}

collect_maven_goals() { 
  if [ -z "$_arg_tasks" ]; then
    echo
    read -r -p "${USER_ACTION_COLOR}What Maven goals should be run? ${DIM}(package)${RESTORE} " tasks

    if [[ "${tasks}" == "" ]]; then
      task=package
    fi
  else
    tasks=$_arg_tasks
  fi
}

print_extra_args() {
  if [ -n "${extra_args}" ]; then
    echo " ${extra_args}"
  fi
}
