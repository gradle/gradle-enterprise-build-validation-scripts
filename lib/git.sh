#!/usr/bin/env bash

clone_project() {
   info
   info "Cloning ${project_name}"

   local clone_dir="${EXPERIMENT_DIR}/${project_name}"

   local branch=""
   if [ -n "${project_branch}" ]; then
      branch="--branch ${project_branch}"
   fi

   rm -rf "${clone_dir}"
   # shellcheck disable=SC2086  # we want $branch to expand into multiple arguments
   git clone --depth=1 ${branch} "${project_url}" "${clone_dir}" || die "Unable to clone from ${project_url} Aborting!" 1
   cd "${clone_dir}" || die "Unable to access ${clone_dir}. Aborting!" 1
   info
}

