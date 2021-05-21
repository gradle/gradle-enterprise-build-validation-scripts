#!/usr/bin/env bash

# shellcheck source=lib/color.sh
source "${LIB_DIR}/color.sh" || { echo "Couldn't find '${LIB_DIR}/color.sh'"; exit 1; }

# shellcheck source=lib/info.sh
source "${LIB_DIR}/info.sh" || { echo "Couldn't find '${LIB_DIR}/info.sh'"; exit 1; }

# shellcheck source=lib/wizard.sh
source "${LIB_DIR}/wizard.sh" || { echo "Couldn't find '${LIB_DIR}/wizard.sh'"; exit 1; }

# shellcheck source=lib/config.sh
source "${LIB_DIR}/config.sh" || { echo "Couldn't find '${LIB_DIR}/config.sh'"; exit 1; }

# shellcheck source=lib/init.sh
source "${LIB_DIR}/init.sh" || { echo "Couldn't find '${LIB_DIR}/init.sh'"; exit 1; }

# shellcheck source=lib/git.sh
source "${LIB_DIR}/git.sh" || { echo "Couldn't find '${LIB_DIR}/git.sh'"; exit 1; }

# shellcheck source=lib/build_scan.sh
source "${LIB_DIR}/build_scan.sh" || { echo "Couldn't find '${LIB_DIR}/build_scan.sh'"; exit 1; }

# shellcheck source=lib/gradle.sh
source "${LIB_DIR}/gradle.sh" || { echo "Couldn't find '${LIB_DIR}/gradle.sh'"; exit 1; }

# shellcheck source=lib/maven.sh
source "${LIB_DIR}/maven.sh" || { echo "Couldn't find '${LIB_DIR}/maven.sh'"; exit 1; }

# shellcheck source=lib/help.sh
source "${LIB_DIR}/help.sh" || { echo "Couldn't find '${LIB_DIR}/help.sh'"; exit 1; }

# shellcheck source=lib/paths.sh
source "${LIB_DIR}/paths.sh" || { echo "Couldn't find '${LIB_DIR}/paths.sh'"; exit 1; }
