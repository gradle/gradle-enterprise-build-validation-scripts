#!/usr/bin/env bash

# shellcheck source=experiments/lib/color.sh=
source "${script_dir}/lib/color.sh" || { echo "Couldn't find '${script_dir}/lib/color.sh'"; exit 1; }

# shellcheck source=experiments/lib/info.sh=
source "${script_dir}/lib/info.sh" || { echo "Couldn't find '${script_dir}/lib/info.sh'"; exit 1; }

# shellcheck source=experiments/lib/wizard.sh
source "${script_dir}/lib/wizard.sh" || { echo "Couldn't find '${script_dir}/lib/wizard.sh'"; exit 1; }

# shellcheck source=experiments/lib/config.sh
source "${script_dir}/lib/config.sh" || { echo "Couldn't find '${script_dir}/lib/config.sh'"; exit 1; }

# shellcheck source=experiments/lib/input.sh
source "${script_dir}/lib/input.sh" || { echo "Couldn't find '${script_dir}/lib/input.sh'"; exit 1; }

# shellcheck source=experiments/lib/init.sh
source "${script_dir}/lib/init.sh" || { echo "Couldn't find '${script_dir}/lib/init.sh'"; exit 1; }

# shellcheck source=experiments/lib/git.sh
source "${script_dir}/lib/git.sh" || { echo "Couldn't find '${script_dir}/lib/git.sh'"; exit 1; }

# shellcheck source=experiments/lib/scan_info.sh
source "${script_dir}/lib/scan_info.sh" || { echo "Couldn't find '${script_dir}/lib/scan_info.sh'"; exit 1; }

# shellcheck source=experiments/lib/gradle.sh
source "${script_dir}/lib/gradle.sh" || { echo "Couldn't find '${script_dir}/lib/gradle.sh'"; exit 1; }

