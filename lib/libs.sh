#!/usr/bin/env bash

# shellcheck source=experiments/lib/color.sh=
source "${SCRIPT_DIR}/../lib/color.sh" || { echo "Couldn't find '../lib/color.sh'"; exit 1; }

# shellcheck source=experiments/lib/info.sh=
source "${SCRIPT_DIR}/../lib/info.sh" || { echo "Couldn't find '../lib/info.sh'"; exit 1; }

# shellcheck source=experiments/lib/wizard.sh
source "${SCRIPT_DIR}/../lib/wizard.sh" || { echo "Couldn't find '../lib/wizard.sh'"; exit 1; }

# shellcheck source=experiments/lib/config.sh
source "${SCRIPT_DIR}/../lib/config.sh" || { echo "Couldn't find '../lib/config.sh'"; exit 1; }

# shellcheck source=experiments/lib/init.sh
source "${SCRIPT_DIR}/../lib/init.sh" || { echo "Couldn't find '../lib/init.sh'"; exit 1; }

# shellcheck source=experiments/lib/git.sh
source "${SCRIPT_DIR}/../lib/git.sh" || { echo "Couldn't find '../lib/git.sh'"; exit 1; }

# shellcheck source=experiments/lib/scan_info.sh
source "${SCRIPT_DIR}/../lib/scan_info.sh" || { echo "Couldn't find '../lib/scan_info.sh'"; exit 1; }

# shellcheck source=experiments/lib/gradle.sh
source "${SCRIPT_DIR}/../lib/gradle.sh" || { echo "Couldn't find '../lib/gradle.sh'"; exit 1; }

# shellcheck source=experiments/lib/maven.sh
source "${SCRIPT_DIR}/../lib/maven.sh" || { echo "Couldn't find '../lib/maven.sh'"; exit 1; }

