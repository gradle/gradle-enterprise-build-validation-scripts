#!/usr/bin/env bash

process_arguments() {
  parse_commandline "$@"

  git_repo="${_arg_git_repo}"
  git_branch="${_arg_git_branch}"
  project_name="$(basename -s .git "${git_repo}")"
  tasks="${_arg_tasks}"
  extra_args="${_arg_args}"
  enable_ge="${_arg_enable_gradle_enterprise}"
  ge_server="${_arg_gradle_enterprise_server}"
  interactive_mode="${_arg_interactive}"
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
     git_branch=$_arg_git_branch
  else
     read -r -p "${USER_ACTION_COLOR}What is the project's branch to check out? ${DIM}(the project's default branch)${RESTORE} " git_branch
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

print_command_to_repeat_experiment() {
  local cmd
  cmd=("./${SCRIPT_NAME}" "-r" "${git_repo}")

  if [ -n "${git_branch}" ]; then
    cmd+=("-b" "${git_branch}")
  fi

  cmd+=("-t" "${tasks}")

  if [ -n "${extra_args}" ]; then
    cmd+=("-a" "${extra_args}")
  fi

  if [ -n "${ge_server}" ]; then
    cmd+=("-s" "${ge_server}")
  fi

  if [ -n "${enable_ge}" ]; then
    cmd+=("-e")
  fi

  info "$(printf '%q ' "${cmd[@]}")"
}
