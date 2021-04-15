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

