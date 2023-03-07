#!/usr/bin/env bash

# The code within this method is based off of the Gradle application plugin's
# generated start up script. The template for the start up script can be found
# here:

# https://github.com/gradle/gradle/blob/3200a204ba96f503f1171b3584258a53ecd91bd2/subprojects/plugins/src/main/resources/org/gradle/api/internal/plugins/unixStartScript.txt
#
# shellcheck disable=SC2128,SC2178
invoke_java() {
  local classpath="$1"
  shift

  # OS specific support (must be 'true' or 'false').
  cygwin=false
  msys=false
  darwin=false
  nonstop=false
  case "$(uname)" in
    CYGWIN*) cygwin=true ;;
    Darwin*) darwin=true ;;
    MSYS* | MINGW*) msys=true ;;
    NONSTOP*) nonstop=true ;;
  esac

  # Determine the Java command to use to start the JVM.
  if [ -n "$JAVA_HOME" ]; then
    if [ -x "$JAVA_HOME/jre/sh/java" ]; then
      # IBM's JDK on AIX uses strange locations for the executables
      JAVACMD=$JAVA_HOME/jre/sh/java
    else
      JAVACMD=$JAVA_HOME/bin/java
    fi
    if [ ! -x "$JAVACMD" ]; then
      die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
  else
    JAVACMD=java
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
  fi

  # Increase the maximum file descriptors if we can.
  if ! "$cygwin" && ! "$darwin" && ! "$nonstop"; then
    case $MAX_FD in
    max*)
      # In POSIX sh, ulimit -H is undefined. That's why the result is checked to see if it worked.
      MAX_FD=$(ulimit -H -n) ||
        warn "Could not query maximum file descriptor limit"
      ;;
    esac
    case $MAX_FD in
    '' | soft) : ;;
    *)
      # In POSIX sh, ulimit -n is undefined. That's why the result is checked to see if it worked.
      ulimit -n "$MAX_FD" ||
        warn "Could not set maximum file descriptor limit to $MAX_FD"
      ;;
    esac
  fi

  # Collect all arguments for the java command, stacking in reverse order:
  #   * args from the command line
  #   * the main class name
  #   * -classpath
  #   * -D...appname settings
  #   * --module-path (only if needed)
  #   * DEFAULT_JVM_OPTS, JAVA_OPTS, and APP_OPTS environment variables.

  # For Cygwin or MSYS, switch paths to Windows format before running java
  if "$cygwin" || "$msys"; then
    APP_HOME=$(cygpath --path --mixed "$APP_HOME")
    classpath=$(cygpath --path --mixed "$classpath")

    JAVACMD=$(cygpath --unix "$JAVACMD")

    # Now convert the arguments - kludge to limit ourselves to /bin/sh
    for arg; do
      if
        case $arg in
        -*) false ;; # don't mess with options
        /?*)
          t=${arg#/} t=/${t%%/*} # looks like a POSIX filepath
          [ -e "$t" ]
          ;;
        *) false ;;
        esac
      then
        arg=$(cygpath --path --ignore --mixed "$arg")
      fi
      # Roll the args list around exactly as many times as the number of
      # args, so each arg winds up back in the position where it started, but
      # possibly modified.
      #
      # NB: a `for` loop captures its iteration list before it begins, so
      # changing the positional parameters here affects neither the number of
      # iterations, nor the values presented in `arg`.
      shift              # remove old arg
      set -- "$@" "$arg" # push replacement arg
    done
  fi

  # Collect all arguments for the java command;
  #   * $DEFAULT_JVM_OPTS, $JAVA_OPTS, and $APP_OPTS can contain fragments of
  #     shell script including quotes and variable substitutions, so put them in
  #     double quotes to make sure that they get re-expanded; and
  #   * put everything else in single quotes, so that it's not re-expanded.

  set -- -Dpicocli.ansi=true -jar "$classpath" "$@"

  # Stop when "xargs" is not available.
  if ! command -v xargs >/dev/null 2>&1; then
    die "xargs is not available"
  fi

  # Use "xargs" to parse quoted args.
  #
  # With -n1 it outputs one arg per line, with the quotes and backslashes removed.
  #
  # In Bash we could simply go:
  #
  #   readarray ARGS < <( xargs -n1 <<<"$var" ) &&
  #   set -- "${ARGS[@]}" "$@"
  #
  # but POSIX shell has neither arrays nor command substitution, so instead we
  # post-process each arg (as a line of input to sed) to backslash-escape any
  # character that might be a shell metacharacter, then use eval to reverse
  # that process (while maintaining the separation between arguments), and wrap
  # the whole thing up as a single "set" statement.
  #
  # This will of course break if any of these variables contains a newline or
  # an unmatched quote.
  #

  eval "set -- $(
    printf '%s\n' "$DEFAULT_JVM_OPTS $JAVA_OPTS $APP_OPTS" |
      xargs -n1 |
      sed ' s~[^-[:alnum:]+,./:=@_]~\\&~g; ' |
      tr '\n' ' '
  )" '"$@"'

  # shellcheck disable=SC2154
  if [[ "${debug_mode}" == "on" ]]; then
    debug "$JAVACMD $*" 1>&2
    print_bl 1>&2
  fi

  exec "$JAVACMD" "$@"
}
