#!/usr/bin/env bash

clone_project() {
   suffix="$1"
   info
   info "Cloning ${project_name}"

   local clone_dir="${EXPERIMENT_DIR}/${project_name}${suffix}"

   local branch=""
   if [ -n "${git_branch}" ]; then
      branch="--branch ${git_branch}"
   fi

   rm -rf "${clone_dir}"
   # shellcheck disable=SC2086  # we want $branch to expand into multiple arguments
   git clone --depth=1 ${branch} "${git_repo}" "${clone_dir}" || die "Unable to clone from ${project_url} Aborting!" 1
   cd "${clone_dir}" || die "Unable to access ${clone_dir}. Aborting!" 1
   info
}

