#!/usr/bin/env bash

invoke_java() {
  local classpath="$1"
  shift
  local args=( "$@" )

  # OS specific support (must be 'true' or 'false').
  cygwin=false
  msys=false
  case "$(uname)" in
    CYGWIN*)
      cygwin=true
      ;;
    MINGW*)
      msys=true
      ;;
  esac

  # Determine the Java command to use to start the JVM.
  if [ -n "$JAVA_HOME" ]; then
    if [ -x "$JAVA_HOME/jre/sh/java" ]; then
      # IBM's JDK on AIX uses strange locations for the executables
      JAVACMD="$JAVA_HOME/jre/sh/java"
    else
      JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ]; then
      die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

  Please set the JAVA_HOME variable in your environment to match the
  location of your Java installation."
    fi
  else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

  Please set the JAVA_HOME variable in your environment to match the
  location of your Java installation."
  fi

  # For Cygwin or MSYS, switch paths to Windows format before running java
  if [ "$cygwin" = "true" ] || [ "$msys" = "true" ]; then
    APP_HOME=$(cygpath --path --mixed "$APP_HOME")
    CLASSPATH=$(cygpath --path --mixed "$CLASSPATH")
    JAVACMD=$(cygpath --unix "$JAVACMD")

    # We build the pattern for arguments to be converted via cygpath
    ROOTDIRSRAW=$(find -L / -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
    SEP=""
    for dir in $ROOTDIRSRAW; do
      ROOTDIRS="$ROOTDIRS$SEP$dir"
      SEP="|"
    done
    OURCYGPATTERN="(^($ROOTDIRS))"
    # Add a user-defined pattern to the cygpath arguments
    if [ "$GRADLE_CYGPATTERN" != "" ]; then
      OURCYGPATTERN="$OURCYGPATTERN|($GRADLE_CYGPATTERN)"
    fi
    # Now convert the arguments - kludge to limit ourselves to /bin/sh
    i=0
    for arg in "${args[@]}"; do
      CHECK=$(echo "$arg" | grep -E -c "$OURCYGPATTERN" -)
      CHECK2=$(echo "$arg" | grep -E -c "^-") ### Determine if an option

      # shellcheck disable=SC2046  # we actually want word splitting
      # shellcheck disable=SC2116  # using echo to expand globs
      if [ "$CHECK" -ne 0 ] && [ "$CHECK2" -eq 0 ]; then ### Added a condition
        eval $(echo args$i)=$(cygpath --path --ignore --mixed "$arg")
      else
        eval $(echo args$i)="\"$arg\""
      fi
      # shellcheck disable=SC2003
      i=$(expr $i + 1)
    done
    # shellcheck disable=SC2154
    case $i in
      0) set -- ;;
      1) set -- "$args0" ;;
      2) set -- "$args0" "$args1" ;;
      3) set -- "$args0" "$args1" "$args2" ;;
      4) set -- "$args0" "$args1" "$args2" "$args3" ;;
      5) set -- "$args0" "$args1" "$args2" "$args3" "$args4" ;;
      6) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" ;;
      7) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" ;;
      8) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" "$args7" ;;
      9) set -- "$args0" "$args1" "$args2" "$args3" "$args4" "$args5" "$args6" "$args7" "$args8" ;;
    esac
  fi

  # Escape application args
  save() {
    for i; do printf %s\\n "$i" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/"; done
    echo " "
  }

  # Collect all arguments for the java command, following the shell quoting and substitution rules
  eval set -- -Dpicocli.ansi=true -jar "\"$classpath\"" "$(save "${args[@]}")"

  # shellcheck disable=SC2154
  if [[ "$_arg_debug" == "on" ]]; then
    debug "$JAVACMD $*" 1>&2
    print_bl 1>&2
  fi

  exec "$JAVACMD" "$@"
}
