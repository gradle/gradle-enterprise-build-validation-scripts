#!/usr/bin/env bash

print_script_usage() {
  echo "USAGE: ${SCRIPT_NAME} [option...]"
  echo
}

print_option_usage() {
  local key="$1"

  case "$key" in
    -a)
       _print_option_usage "-a, --args" "Specifies additional arguments to pass to ${BUILD_TOOL}."
       ;;
    -A)
       _print_option_usage "-A, --access-key" "Specifies the access key to use when authenticating with Gradle Enterprise to fetch build scan data."
       ;;
    -b)
       _print_option_usage "-b, --git-branch" "Specifies the branch for the Git repository to validate."
       ;;
    -e)
       _print_option_usage "-e, --enable-gradle-enterprise" "Enables Gradle Enterprise on a project not already connected."
       ;;
    -g)
       _print_option_usage "-g, --goals" "Specifies the Maven goals to invoke."
       ;;
    -h)
       _print_option_usage "-h, --help" "Shows this help message."
       ;;
    -i)
       _print_option_usage "-i, --interactive" "Enables interactive mode."
       ;;
    -m)
       _print_option_usage "-m, --mapping-file" "Specifies the mapping file for the custom value names used in the build scans."
       ;;
    -p)
       _print_option_usage "-p, --project-dir" "Specifies the build invocation directory within the Git repository."
       ;;
    -P)
       _print_option_usage "-P, --password" "Specifies the password to use when authenticating with Gradle Enterprise to fetch build scan data."
       ;;
    -r)
       _print_option_usage "-r, --git-repo" "Specifies the URL for the Git repository to validate."
       ;;
    -s)
       _print_option_usage "-s, --gradle-enterprise-server" "Specifies the URL for the Gradle Enterprise server to connect to."
       ;;
    -t)
       _print_option_usage "-t, --tasks" "Specifies the Gradle tasks to invoke."
       ;;
    -U)
       _print_option_usage "-U, --username" "Specifies the username to use when authenticating with Gradle Enterprise to fetch build scan data."
       ;;
    -v)
       _print_option_usage "-v, --version" "Prints version info."
       ;;
    *)
       _print_option_usage "$1" "$2"
  esac
}

_print_option_usage() {
  local flags="$1"
  local description="$2"

  local fmt="%-35s%s\n"
  #shellcheck disable=SC2059
  printf "$fmt" "$flags" "$description"
}

print_version() {
  echo "${SCRIPT_VERSION}"
}

