#!/usr/bin/env bash

save_settings() {
  if [ ! -f "${_arg_settings}" ]; then
    cat << EOF > "${_arg_settings}"
GIT_URL="${project_url}"
GIT_BRANCH="${project_branch}"
GRADLE_TASK="${task}"
EOF
  fi
}

load_settings() {
  if [ -f  "${_arg_settings}" ]; then
    # shellcheck source=/dev/null # this file is created by the user so nothing for shellcheck to check
    source "${_arg_settings}"

    if [ -z "${_arg_git_url}" ]; then
      _arg_git_url="${GIT_URL}"
    fi
    if [ -z "${_arg_branch}" ]; then
      _arg_branch="${GIT_BRANCH}"
    fi
    if [ -z "${_arg_task}" ]; then
      _arg_task="${GRADLE_TASK}"
    fi

    info
    info "Loaded settings from ${_arg_settings}"
  fi
}

