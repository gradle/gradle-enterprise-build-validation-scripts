#!/usr/bin/env bash

# shellcheck source=build-validation/scripts/lib/color.sh
source "${LIB_DIR}/color.sh" || { echo "Couldn't find '${LIB_DIR}/color.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/info.sh
source "${LIB_DIR}/info.sh" || { echo "Couldn't find '${LIB_DIR}/info.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/wizard.sh
source "${LIB_DIR}/wizard.sh" || { echo "Couldn't find '${LIB_DIR}/wizard.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/config.sh
source "${LIB_DIR}/config.sh" || { echo "Couldn't find '${LIB_DIR}/config.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/init.sh
source "${LIB_DIR}/init.sh" || { echo "Couldn't find '${LIB_DIR}/init.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/git.sh
source "${LIB_DIR}/git.sh" || { echo "Couldn't find '${LIB_DIR}/git.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/build_scan.sh
source "${LIB_DIR}/build_scan.sh" || { echo "Couldn't find '${LIB_DIR}/build_scan.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/gradle.sh
source "${LIB_DIR}/gradle.sh" || { echo "Couldn't find '${LIB_DIR}/gradle.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/maven.sh
source "${LIB_DIR}/maven.sh" || { echo "Couldn't find '${LIB_DIR}/maven.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/help.sh
source "${LIB_DIR}/help.sh" || { echo "Couldn't find '${LIB_DIR}/help.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/paths.sh
source "${LIB_DIR}/paths.sh" || { echo "Couldn't find '${LIB_DIR}/paths.sh'"; exit 1; }
