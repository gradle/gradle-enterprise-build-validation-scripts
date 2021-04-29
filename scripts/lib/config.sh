#!/usr/bin/env bash

process_arguments() {
  parse_commandline "$@"

  git_repo="${_arg_git_repo}"
  git_branch="${_arg_git_branch}"
  project_name="$(basename -s .git "${git_repo}")"
  project_dir="${_arg_project_dir}"
  tasks="${_arg_tasks}"
  extra_args="${_arg_args}"
  #shellcheck disable=SC2154 # The maven scripts don't yet support _arg_gradle_enterprise_server
  enable_ge="${_arg_enable_gradle_enterprise}"
  ge_server="${_arg_gradle_enterprise_server}"
  interactive_mode="${_arg_interactive}"
}

validate_required_config() {
  if [ -z "${git_repo}" ]; then
    _PRINT_HELP=yes die "ERROR: Missing required argument: --git-repo" 1
  fi
  if [ -z "${tasks}" ]; then
    _PRINT_HELP=yes die "ERROR: Missing required argument: --tasks" 1
  fi

  if [[ "${enable_ge}" == "on" ]]; then
    if [ -z "${ge_server}" ]; then
      _PRINT_HELP=yes die "ERROR: --gradle-enterprise-server is requred when using --enable-gradle-enterprise."
    fi
  fi
}

prompt_for_setting() {
  local prompt primary_default secondary_default default variable defaultDisplay
  prompt="$1"
  primary_default="$2"
  secondary_default="$3"
  variable="$4"

  if [ -n "$primary_default" ]; then
    default="${primary_default}"
  else
    default="${secondary_default}"
  fi

  if [ -n "$default" ]; then
    defaultDisplay="(${default}) "
  fi

  while :; do
    read -r -p "${USER_ACTION_COLOR}${prompt} ${DIM}${defaultDisplay}${RESTORE}" "${variable?}"

    UP_ONE_LINE="\033[1A"
    ERASE_LINE="\033[2K"
    echo -en "${UP_ONE_LINE}${ERASE_LINE}"

    if [ -z "${!variable}" ]; then
      if [ -n "${default}" ]; then
        eval "${variable}=\${default}"
        break
      fi
    else
      break
    fi
  done

  echo "${USER_ACTION_COLOR}${prompt} ${CYAN}${!variable}${RESTORE}"
}

collect_git_details() {
  prompt_for_setting "What is the URL for the Git repository to validate?" "${git_repo}" '' git_repo

  local default_branch="*the repo's default branch*"
  prompt_for_setting "What is the branch for the Git repository to validate?" "${git_branch}" "${default_branch}" git_branch

  if [[ "${git_branch}" == "${default_branch}" ]]; then
    git_branch=''
  fi
  project_name=$(basename -s .git "${git_repo}")
}

collect_gradle_details() {
  prompt_for_setting "What is the folder containing the root project?" "${project_dir}" "*the repo's root dir*" project_dir
  prompt_for_setting "What are the Gradle tasks to invoke?" "${tasks}" "assemble" tasks
  prompt_for_setting "Enter any additional arguments to pass to Gradle." "${extra_args}" "*none*" extra_args
  if [[ "${project_dir}" == "*the repo's root dir*" ]]; then
    project_dir=''
  fi
  if [[ "${extra_args}" == "*none*" ]]; then
    extra_args=''
  fi
}

collect_maven_details() {
  prompt_for_setting "What are the Maven goals to invoke?" "${tasks}" "package" tasks
  prompt_for_setting "Enter any additional arguments to pass to Maven." "${extra_args}" "*none*" extra_args
  if [[ "${extra_args}" == "*none*" ]]; then
    extra_args=''
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

  if [ -n "${project_dir}" ]; then
    cmd+=("-p" "${project_dir}")
  fi

  cmd+=("-t" "${tasks}")

  if [ -n "${extra_args}" ]; then
    cmd+=("-a" "${extra_args}")
  fi

  if [ -n "${ge_server}" ]; then
    cmd+=("-s" "${ge_server}")
  fi

  if [[ "${enable_ge}" == "on" ]]; then
    cmd+=("-e")
  fi

  info "$(printf '%q ' "${cmd[@]}")"
}

