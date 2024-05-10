#!/usr/bin/env bash

failed_to_load_lib() {
  local lib_name _RED _BOLD _RESTORE _UNEXPECTED_ERROR
  _RED=$(echo -en '\033[00;31m')
  _BOLD=$(echo -en '\033[1m')
  _RESTORE=$(echo -en '\033[0m')
  _UNEXPECTED_ERROR=100

  lib_name="${LIB_DIR}/$1"
  echo "${_RED}${_BOLD}ERROR: Couldn't find '${lib_name}'${_RESTORE}"
  exit "${_UNEXPECTED_ERROR}"
}

# shellcheck source=lib/scripts/logging.sh
source "${LIB_DIR}/logging.sh" || failed_to_load_lib logging.sh

# shellcheck source=lib/scripts/build-scan-offline.sh
source "${LIB_DIR}/build-scan-offline.sh" || failed_to_load_lib build-scan-offline.sh

# shellcheck source=lib/scripts/build-scan-parse.sh
source "${LIB_DIR}/build-scan-parse.sh" || failed_to_load_lib build-scan-parse.sh

# shellcheck source=lib/scripts/build-scan-online.sh
source "${LIB_DIR}/build-scan-online.sh" || failed_to_load_lib build-scan-online.sh

# shellcheck source=lib/scripts/color.sh
source "${LIB_DIR}/color.sh" || failed_to_load_lib color.sh

# shellcheck source=lib/scripts/config.sh
source "${LIB_DIR}/config.sh" || failed_to_load_lib config.sh

# shellcheck source=lib/scripts/exit-code.sh
source "${LIB_DIR}/exit-code.sh" || failed_to_load_lib exit-code.sh

# shellcheck source=lib/scripts/git.sh
source "${LIB_DIR}/git.sh" || failed_to_load_lib git.sh

# shellcheck source=lib/scripts/gradle.sh
source "${LIB_DIR}/gradle.sh" || failed_to_load_lib gradle.sh

# shellcheck source=lib/scripts/help.sh
source "${LIB_DIR}/help.sh" || failed_to_load_lib help.sh

# shellcheck source=lib/scripts/summary.sh
source "${LIB_DIR}/summary.sh" || failed_to_load_lib summary.sh

# shellcheck source=lib/scripts/init.sh
source "${LIB_DIR}/init.sh" || failed_to_load_lib init.sh

# shellcheck source=lib/scripts/java.sh
source "${LIB_DIR}/java.sh" || failed_to_load_lib java.sh

# shellcheck source=lib/scripts/maven.sh
source "${LIB_DIR}/maven.sh" || failed_to_load_lib maven.sh

# shellcheck source=lib/scripts/paths.sh
source "${LIB_DIR}/paths.sh" || failed_to_load_lib paths.sh

# shellcheck source=lib/scripts/project.sh
source "${LIB_DIR}/project.sh" || failed_to_load_lib project.sh

# shellcheck source=lib/scripts/interactive-mode.sh
source "${LIB_DIR}/interactive-mode.sh" || failed_to_load_lib interactive-mode.sh
