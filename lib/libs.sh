#!/usr/bin/env bash

# shellcheck source=experiments/lib/color.sh=
source "${SCRIPT_DIR}/lib/color.sh" || { echo "Couldn't find '${SCRIPT_DIR}/lib/color.sh'"; exit 1; }

# shellcheck source=experiments/lib/info.sh=
source "${SCRIPT_DIR}/lib/info.sh" || { echo "Couldn't find '${SCRIPT_DIR}/lib/info.sh'"; exit 1; }

# shellcheck source=experiments/lib/wizard.sh
source "${SCRIPT_DIR}/lib/wizard.sh" || { echo "Couldn't find '${SCRIPT_DIR}/lib/wizard.sh'"; exit 1; }

# shellcheck source=experiments/lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh" || { echo "Couldn't find '${SCRIPT_DIR}/lib/config.sh'"; exit 1; }

# shellcheck source=experiments/lib/input.sh
source "${SCRIPT_DIR}/lib/input.sh" || { echo "Couldn't find '${SCRIPT_DIR}/lib/input.sh'"; exit 1; }

# shellcheck source=experiments/lib/init.sh
source "${SCRIPT_DIR}/lib/init.sh" || { echo "Couldn't find '${SCRIPT_DIR}/lib/init.sh'"; exit 1; }

# shellcheck source=experiments/lib/git.sh
source "${SCRIPT_DIR}/lib/git.sh" || { echo "Couldn't find '${SCRIPT_DIR}/lib/git.sh'"; exit 1; }

# shellcheck source=experiments/lib/scan_info.sh
source "${SCRIPT_DIR}/lib/scan_info.sh" || { echo "Couldn't find '${SCRIPT_DIR}/lib/scan_info.sh'"; exit 1; }

# shellcheck source=experiments/lib/gradle.sh
source "${SCRIPT_DIR}/lib/gradle.sh" || { echo "Couldn't find '${SCRIPT_DIR}/lib/gradle.sh'"; exit 1; }

