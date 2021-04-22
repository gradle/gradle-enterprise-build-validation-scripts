#!/usr/bin/env bash

invoke_gradle() {
  local ge_server_arg
  ge_server_arg=""
  if [ -n "${ge_server}" ]; then
    ge_server_arg="-Pcom.gradle.enterprise.init.script.server=${ge_server}"
  fi


  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local lib_dir_rel
  lib_dir_rel=$(relpath "$( pwd )" "${LIB_DIR}")

  local enable_ge_init_script
  enable_ge_init_script=()

  if [ "$enable_ge" == "on" ]; then
    # FIXME This doesn't handle paths with spaces in it very well. Figure out how to do the shell qouting properly!
    enable_ge_init_script="--init-script ${lib_dir_rel}/gradle/enable-gradle-enterprise.gradle"
  fi

  ./gradlew \
      ${enable_ge_init_script} \
      --init-script "${lib_dir_rel}/gradle/verify-ge-configured.gradle" \
      --init-script "${lib_dir_rel}/gradle/capture-build-scan-info.gradle" \
      ${ge_server_arg} \
      -Dscan.tag.${EXP_SCAN_TAG} \
      -Dscan.tag."${RUN_ID}" \
      -Dscan.capture-task-input-files \
      ${extra_args} \
      "$@" \
      || fail "The experiment cannot continue because the build failed."
}

make_local_cache_dir() {
  rm -rf "${build_cache_dir}"
  mkdir -p "${build_cache_dir}"
}

# From this Stack Exchange Community Wiki Answer: 
# https://unix.stackexchange.com/a/85068/88179
relpath() {
    # both $1 and $2 are absolute paths beginning with /
    # $1 must be a canonical path; that is none of its directory
    # components may be ".", ".." or a symbolic link
    #
    # returns relative path to $2/$target from $1/$source
    source=$1
    target=$2

    common_part=$source
    result=

    while [ "${target#"$common_part"}" = "$target" ]; do
        # no match, means that candidate common part is not correct
        # go up one level (reduce common part)
        common_part=$(dirname "$common_part")
        # and record that we went back, with correct / handling
        if [ -z "$result" ]; then
            result=..
        else
            result=../$result
        fi
    done

    if [ "$common_part" = / ]; then
        # special case for root (no common path)
        result=$result/
    fi

    # since we now have identified the common part,
    # compute the non-common part
    forward_part=${target#"$common_part"}

    # and now stick all parts together
    if [ -n "$result" ] && [ -n "$forward_part" ]; then
        result=$result$forward_part
    elif [ -n "$forward_part" ]; then
        # extra slash removal
        result=${forward_part#?}
    fi

    printf '%s\n' "$result"
}
