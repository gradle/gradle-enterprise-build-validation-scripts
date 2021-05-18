#!/usr/bin/env bash

git_clone_project() {
   local target_subdir="$1"
   if [ -z "${target_subdir}" ]; then
       target_subdir="${project_name}"
   fi

   info "Cloning ${project_name}"

   local clone_dir="${EXP_DIR:?}/${target_subdir:?}"

   local branch=""
   if [ -n "${git_branch}" ]; then
      branch="--branch ${git_branch}"
   fi

   rm -rf "${clone_dir:?}"
   # shellcheck disable=SC2086  # we want $branch to expand into multiple arguments
   git clone --depth=1 ${branch} "${git_repo}" "${clone_dir}" || die "ERROR: Unable to clone from ${git_repo}." 2
   cd "${clone_dir}" || die "Unable to access git repository directory ${clone_dir}." 2
}

git_copy_project() {
   local original_repo copy_dest num_files
   original_repo="$1"
   copy_dest="$2"
   info "Copying ${project_name}"

   rm -rf "${EXP_DIR:?}/${copy_dest:?}"
   mkdir -p "${EXP_DIR:?}/${copy_dest:?}"
   num_files=$(cp -R -v "${EXP_DIR:?}/${original_repo:?}" "${EXP_DIR:?}/${copy_dest:?}" | wc -l)
   printf "Copied %'d files.\n" "${num_files}"
}

git_get_branch() {
  git symbolic-ref -q --short HEAD || git rev-parse --short HEAD
}

git_get_commit_id() {
  git rev-parse --short=8 --verify HEAD
}

git_checkout_commit() {
  local commit clone_dir
  commit="$1"

  info "Cloning ${project_name} and checking out commit ${commit}"

  clone_dir="${EXP_DIR:?}/${project_name:?}${suffix}"

  rm -rf "${clone_dir:?}"
  mkdir -p "${clone_dir}"
  cd "${clone_dir}" || die "ERROR: Unable access git repository directory ${clone_dir}" 2
  git init > /dev/null || die "ERROR: Unable initialize git" 2
  git remote add origin "${git_repo}" || die "ERROR: Unable to fetch from ${git_repo}" 2

  if ! git fetch --depth 1 origin "${commit}"; then
    # Older versions of git don't support using --depth 1 with fetch, so try again without the shallow checkout
    git fetch origin "${commit}" || die "ERROR: Unable to fetch commit ${commit}" 2
  fi

  git -c advice.detachedHead=false checkout FETCH_HEAD || die "ERROR: Unable to checkout commit ${commit}" 2
}
