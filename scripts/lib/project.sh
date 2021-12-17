#!/usr/bin/env bash

copy_project_dir() {
   local original_repo copy_dest quietly num_files
   original_repo="$1"
   copy_dest="$2"
   quietly="$3"

   if [ -z "${quietly}" ]; then
     info "Copying ${project_name}"
   fi

   rm -rf "${EXP_DIR:?}/${copy_dest:?}"
   num_files=$(cp -R -v "${EXP_DIR:?}/${original_repo:?}" "${EXP_DIR:?}/${copy_dest:?}" | wc -l)

   if [ -z "${quietly}" ]; then
     printf "Copied %'d files.\n" "${num_files}"
   fi
}

rename_project_dir() {
  local original_name new_name
  original_name="$1"
  new_name="$2"

  mv "${EXP_DIR:?}/${original_name:?}" "${EXP_DIR:?}/${new_name:?}"
}
