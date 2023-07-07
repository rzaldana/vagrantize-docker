#!/usr/bin/env bash

error_exit() {
  local message
  message="$1"  
  echo "ERROR: function ${FUNCNAME[1]}(): $message" >&2
  exit 1
}

# Outputs the absolute path pointed to 
# by the provided absolute path.
# Only works for files. Will error out if the
# given relative path is a directory
# Inputs:
#     1. relative_path: the relative path to resolve
#     2. base_path (optional): the path to treat as the base
#                              for the relative_path.
#                              Defaults to the current directory
get_abs_path() {
  local relative_path 
  local relative_path_dirname 
  local relative_path_basename 
  local base_path 
  local old_wd abs_dir

  # Validate relative_path
  [[ -n "$1" ]] || error_exit "Need to provide a relative path to resolve"
  [[ -d "$1" ]] && error_exit "relative_path (\$1) cannot be a directory. $1 is a directory. Please provide the path to a file"
  relative_path="$1"

  # Validate base_path
  if [[ -n "$2" ]]; then
    if ! [[ -d "$2" ]]; then
      error_exit "base_path (\$2) has to be a directory. Please provide a path to a directory"
    fi
    base_path="$2"
  else
    base_path="."
  fi

  # Get dirname of relative_path
  relative_path_dirname=$(dirname "$relative_path")

  # Get basename of relative_path
  relative_path_basename=$(basename "$relative_path")

  # Cd into base_path
  old_wd="$(pwd)"
  cd "$base_path" || error_exit "Unable to cd into base_path $base_path"

  # Resolve absolute path relative to base_path
  abs_dir=$(cd "$relative_path_dirname" || exit 1 >&1 >/dev/null; pwd || exit 1)

  # Cd into old_wd to restore previous working directory
  cd "$old_wd" || error_exit "Unable to cd back into $old_wd"

  echo "$abs_dir/$relative_path_basename"
}

# Receives the name of a file and a regular expression
# Prints all lines in the file before the first line
# that matches the regexp
get_all_lines_before_match() {
  local file
  local regex
  [[ -n "$1" ]] || error_exit "arg 1: Need to provide name of file to analyze"
  [[ -n "$2" ]] || error_exit "arg 2: Need to provide regex to match" 
  file="$1"
  regex="$2"
  sed -ne "\#$regex#q;p" "$file"
}

# Receives the name of a file and a regular expression
# Prints all lines in the file after the first line
# that matches the regexp
get_all_lines_after_match() {
  local file
  local regex
  [[ -n "$1" ]] || error_exit "arg 1: Need to provide name of file to analyze"
  [[ -n "$2" ]] || error_exit "arg 2: Need to provide regex to match" 
  file="$1"
  regex="$2"
  sed -e "1,\#$regex#d" "$file" 
}

# Searches for all lines that contain the source
# instruction in a bash script and copies the code
# from the sourced files into the original script
# outputting the entire script with the library code
# to a single file
# Input:
#      1. src_script_path : The bash script to build
#      2. dst_file        : The destination of the built script
build() {
  # Determine absolute path of script
  local src_script_path 
  local src_script_abs_path
  local src_script_abs_dirname
  local dst_file
  local -a libraries

  # Validate args
  [[ -n "$1" ]] || error_exit "arg 1: Need to provide the path of the source script to build"
  src_script_path="$1"
  [[ -n "$2" ]] || error_exit "arg 2: Need to provide the path where the built script will be placed"
  dst_file="$2"

  src_script_abs_path="$(get_abs_path "$src_script_path")"
  echo "Building script at $src_script_abs_path"
  src_script_abs_dirname="$(dirname "$src_script_abs_path")"

  # Find all libraries sourced inside script
  readarray -t libraries < <(grep -E "^source " < "$src_script_abs_path")

  # Create first version of final script 
  cp "$src_script_abs_path" "$dst_file"


  # Echo found libraries
  echo "Found libraries: "
  for library in "${libraries[@]}"; do
    local library_relative_path
    local library_abs_path
    local library_name

    library_relative_path="$( echo "$library" | awk '{print $2}')"
    library_abs_path="$(get_abs_path "$library_relative_path" "$src_script_abs_dirname")"
    library_name="$(basename "$library_abs_path")"
    
    echo "Linking $library_abs_path"

    # Replace source line with library code in dst_file
    local tmp_file
    tmp_file="$(mktemp)"
    { 
    get_all_lines_before_match "$dst_file" "$library"
    echo 
    echo "########## START library ${library_name} ###########"
    cat "$library_abs_path"
    echo "########## END library ${library_name} ###########"
    echo
    get_all_lines_after_match "$dst_file" "$library"
    }  >> "$tmp_file"
    mv -f "$tmp_file" "$dst_file"
  done
}

build "$@"
