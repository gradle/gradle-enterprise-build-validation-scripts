#!/usr/bin/env bash

git_clone_project() {
   suffix="$1"
   info "Cloning ${project_name}"

   local clone_dir="${EXP_DIR}/${project_name}${suffix}"

   local branch=""
   if [ -n "${git_branch}" ]; then
      branch="--branch ${git_branch}"
   fi

   rm -rf "${clone_dir}"
   # shellcheck disable=SC2086  # we want $branch to expand into multiple arguments
   git clone --depth=1 ${branch} "${git_repo}" "${clone_dir}" || die "ERROR: Unable to clone from ${git_repo}." 1
   cd "${clone_dir}" || die "Unable to access ${clone_dir}. Aborting!" 1
}

git_copy_project() {
   original_repo="$1"
   copy_repo="$2"
   info "Cloning ${project_name} into different location"

   cd "${EXP_DIR}"
   rm -rf "${copy_repo}"
   # shellcheck disable=SC2086  # we want $branch to expand into multiple arguments
   git clone "${original_repo}" "${copy_repo}" || die "ERROR: Unable to copy ${copy_repo}." 1
   cd "${copy_repo}" || die "Unable to access ${clone_dir}. Aborting!" 1
}

git_get_branch() {
  git symbolic-ref -q --short HEAD || git rev-parse --short HEAD
}

git_get_commit_id() {
  git rev-parse --short=8 --verify HEAD
}

git_checkout_commit() {
  local commit="$1"
  info "Checking out commit ${commit}"
  git checkout -q "${commit}" || die "ERROR: Unable to checkout commit ${commit}" 1
}
