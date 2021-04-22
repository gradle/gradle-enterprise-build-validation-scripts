
print_script_usage() {
  echo "USAGE: ${SCRIPT_NAME} [option...]"
  echo
}

print_option_usage() {
  local key="$1"

  case "$key" in
    -a)
       _print_option_usage "-a, --args" "Declares additional arguments to pass to Gradle."
       ;;
    -b)
       _print_option_usage "-b, --git-branch" "Specifies the branch for the Git repository to validate."
       ;;
    -e)
       _print_option_usage "-e, --enable-gradle-enterprise" "Enables Gradle Enterprise on a project that it is not already enabled on."
       ;;
    -h)
       _print_option_usage "-h, --help" "Shows this help message."
       ;;
    -i)
       _print_option_usage "-i, --interactive" "Enables interactive mode."
       ;;
    -r)
       _print_option_usage "-r, --git-repo" "Specifies the URL for the Git repository to validate."
       ;;
    -s)
       _print_option_usage "-s, --gradle-enterprise-server" "Enables Gradle Enterprise on a project not already connected."
       ;;
    -t)
       _print_option_usage "-t, --tasks" "Declares the Gradle tasks to invoke."
       ;;
    *)
       _print_option_usage "$1" "$2"
  esac
}

_print_option_usage() {
  local flags="$1"
  local description="$2"

  local fmt="%-35s%s\n"
  printf "$fmt" "$flags" "$description"
}

