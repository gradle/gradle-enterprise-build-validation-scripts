#!/usr/bin/env bash

# Arrays used by callers to access the fetched build scan data
project_names=()
base_urls=()
build_scan_urls=()
build_scan_ids=()
git_repos=()
git_branches=()
git_commit_ids=()
requested_tasks=()
build_outcomes=()
# shellcheck disable=SC2034 # not all scripts use this data
remote_build_cache_urls=()
# shellcheck disable=SC2034 # not all scripts use this data
remote_build_cache_shards=()

read_build_scan_metadata() {
  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases
  if [ -f "${BUILD_SCAN_FILE}" ]; then
    while IFS=, read -r field_1 field_2 field_3 field_4; do
       project_names+=("$field_1")
       base_urls+=("$field_2")
       build_scan_urls+=("$field_3")
       build_scan_ids+=("$field_4")
    done < "${BUILD_SCAN_FILE}"
  fi
}

read_build_data_from_current_dir() {
  git_repos+=("$(git_get_remote_url)")
  git_branches+=("${git_branch:-$(git_get_branch)}")
  git_commit_ids+=("$(git_get_commit_id)")
  requested_tasks+=("${tasks}")
}

fetch_build_validation_data() {
  # OS specific support (must be 'true' or 'false').
  cygwin=false
  msys=false
  case "$(uname)" in
    CYGWIN* )
      cygwin=true
      ;;
    MINGW* )
      msys=true
      ;;
  esac

  # Determine the Java command to use to start the JVM.
  if [ -n "$JAVA_HOME" ] ; then
      if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
          # IBM's JDK on AIX uses strange locations for the executables
          JAVACMD="$JAVA_HOME/jre/sh/java"
      else
          JAVACMD="$JAVA_HOME/bin/java"
      fi
      if [ ! -x "$JAVACMD" ] ; then
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
if [ "$cygwin" = "true" ] || [ "$msys" = "true" ] ; then
    APP_HOME=$(cygpath --path --mixed "$APP_HOME")
    CLASSPATH=$(cygpath --path --mixed "$CLASSPATH")
    JAVACMD=$(cygpath --unix "$JAVACMD")

    # We build the pattern for arguments to be converted via cygpath
    ROOTDIRSRAW=$(find -L / -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
    SEP=""
    for dir in $ROOTDIRSRAW ; do
        ROOTDIRS="$ROOTDIRS$SEP$dir"
        SEP="|"
    done
    OURCYGPATTERN="(^($ROOTDIRS))"
    # Add a user-defined pattern to the cygpath arguments
    if [ "$GRADLE_CYGPATTERN" != "" ] ; then
        OURCYGPATTERN="$OURCYGPATTERN|($GRADLE_CYGPATTERN)"
    fi
    # Now convert the arguments - kludge to limit ourselves to /bin/sh
    i=0
    for arg in "$@" ; do
        CHECK=$(echo "$arg"|grep -E -c "$OURCYGPATTERN" -)
        CHECK2=$(echo "$arg"|grep -E -c "^-")                                 ### Determine if an option

        # shellcheck disable=SC2046  # we actually want word splitting
        # shellcheck disable=SC2116  # using echo to expand globs
        if [ "$CHECK" -ne 0 ] && [ "$CHECK2" -eq 0 ] ; then                    ### Added a condition
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
  save () {
      for i do printf %s\\n "$i" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/" ; done
      echo " "
  }
  APP_ARGS=$(save "$@")

  CLASSPATH="${LIB_DIR}/fetch-build-validation-data-1.0.0-SNAPSHOT-all.jar"
  # Collect all arguments for the java command, following the shell quoting and substitution rules
  eval set -- -Dpicocli.ansi=true -jar "\"$CLASSPATH\"" "$APP_ARGS"

  # shellcheck disable=SC2154
  if [[ "$_arg_debug" == "on" ]]; then
    debug "$JAVACMD $*" 1>&2
    print_bl 1>&2
  fi

  exec "$JAVACMD" "$@"
}

fetch_and_read_build_validation_data() {
  info "Fetching build scan data"

  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases
  local args fetched_data header_row_read
  args=()

  if [[ "$_arg_debug" == "on" ]]; then
    args+=("--debug")
  fi

  #shellcheck disable=SC2154 #not all scripts set this value...which is fine, we're checking for it before using it
  if [ -n "${mapping_file}" ]; then
    args+=(-m "${mapping_file}")
  fi

  args+=( "$@" )
  fetched_data="$(fetch_build_validation_data "${args[@]}")"

  debug "Raw fetched data"
  debug "----------------"
  debug "${fetched_data}"
  debug ""

  header_row_read=false
  while IFS=, read -r field_1 field_2 field_3 field_4 field_5 field_6 field_7 field_8 field_9 field_10 field_11; do
     if [[ "$header_row_read" == "false" ]]; then
         header_row_read=true
         continue;
     fi
     project_names+=("$field_1")
     base_urls+=("$field_2")
     build_scan_urls+=("$field_3")
     build_scan_ids+=("$field_4")
     git_repos+=("$field_5")
     git_branches+=("$field_6")
     git_commit_ids+=("$field_7")
     requested_tasks+=("$field_8")
     build_outcomes+=("$field_9")
     # shellcheck disable=SC2034 # not all scripts use this data
     remote_build_cache_urls=("${field_10}")
     # shellcheck disable=SC2034 # not all scripts use this data
     remote_build_cache_shards=("${field_11}")
  done <<< "${fetched_data}"
}

detect_warnings_from_build_scans() {
  local unknown_values=false
  for (( i=0; i<2; i++ )); do
    if [ -z "${project_names[i]}" ] ||
       [ -z "${git_repos[i]}" ] ||
       [ -z "${git_branches[i]}" ] ||
       [ -z "${git_commit_ids[i]}" ] ||
       [ -z "${requested_tasks[i]}" ]; then
      unknown_values=true
    fi
    if [ -z "${build_outcomes[i]}" ]; then
      warnings+=("Failed to fetch build scan data for the ${ORDINALS[i]} build.")
    fi
  done

  local value_mismatch=false
  if [[ "${project_names[0]}" != "${project_names[1]}" ]] ||
     [[ "${git_repos[0]}" != "${git_repos[1]}" ]] ||
     [[ "${git_branches[0]}" != "${git_branches[1]}" ]] ||
     [[ "${git_commit_ids[0]}" != "${git_commit_ids[1]}" ]] ||
     [[ "${requested_tasks[0]}" != "${requested_tasks[1]}" ]]; then
    value_mismatch=true
  fi

  if [[ "${value_mismatch}" == "true" ]]; then
    warnings+=("Differences were detected between the two builds. This may skew the outcome of the experiment.")
  fi
  if [[ "${unknown_values}" == "true" ]]; then
    warnings+=("Some of the build properties could not be determined. This makes it uncertain if the experiment has run correctly.")
  fi
}
