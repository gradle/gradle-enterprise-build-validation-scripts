#!/usr/bin/env bash

# shellcheck source=build-validation/scripts/lib/color.sh
source "${SCRIPT_DIR}/../lib/color.sh" || { echo "Couldn't find '../lib/color.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/info.sh
source "${SCRIPT_DIR}/../lib/info.sh" || { echo "Couldn't find '../lib/info.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/wizard.sh
source "${SCRIPT_DIR}/../lib/wizard.sh" || { echo "Couldn't find '../lib/wizard.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/config.sh
source "${SCRIPT_DIR}/../lib/config.sh" || { echo "Couldn't find '../lib/config.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/init.sh
source "${SCRIPT_DIR}/../lib/init.sh" || { echo "Couldn't find '../lib/init.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/git.sh
source "${SCRIPT_DIR}/../lib/git.sh" || { echo "Couldn't find '../lib/git.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/build_scan.sh
source "${SCRIPT_DIR}/../lib/build_scan.sh" || { echo "Couldn't find '../lib/build_scan.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/gradle.sh
source "${SCRIPT_DIR}/../lib/gradle.sh" || { echo "Couldn't find '../lib/gradle.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/maven.sh
source "${SCRIPT_DIR}/../lib/maven.sh" || { echo "Couldn't find '../lib/maven.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/help.sh
source "${SCRIPT_DIR}/../lib/help.sh" || { echo "Couldn't find '../lib/help.sh'"; exit 1; }

# shellcheck source=build-validation/scripts/lib/paths.sh
source "${SCRIPT_DIR}/../lib/paths.sh" || { echo "Couldn't find '../lib/paths.sh'"; exit 1; }
