
print_script_usage() {
  echo "USAGE: ${SCRIPT_NAME} [option...]"
  echo
}

print_option_usage() {
  local key="$1"

  case "$key" in
    -h)
       _print_option_usage "-h, --help" "Shows this help message."
       ;;
    -a)
       _print_option_usage "-a, --args" "Sets additional arguments to pass to Gradle."
       ;;
    -b)
       _print_option_usage "-b, --git-branch" "Specifies the branch to checkout when cloning the Git repository."
       ;;
    -c)
       _print_option_usage "-c, --config" "Specifies a configuration file to load the configuration from."
       ;;
    -e)
       _print_option_usage "-e, --enable-gradle-enterprise" "Enables Gradle Enterprise on a project that it is not already enabled on. If used, --server is required."
       ;;
    -i)
       _print_option_usage "-i, --interactive" "Enables interactive mode."
       ;;
    -s)
       _print_option_usage "-s, --server" "Specifies the URL for the Gradle Enterprise server to connect to during the experiment."
       ;;
    -t)
       _print_option_usage "-t, --tasks" "Declares the Gradle tasks to invoke when running builds as part of the experiment."
       ;;
    -u)
       _print_option_usage "-u, --git-url" "Specifies the URL for the Git repository to run the experiment against."
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

