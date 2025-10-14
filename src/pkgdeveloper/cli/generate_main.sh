#!/bin/bash

# ----- definition of functions starts ----------------------------------------

print_help() {
echo "
Creates the code that would be executed when your package is called from the
terminal (<pkg_name>.cli.main). This code adds all the relevant keywords, which
include the python modules that contain the comment '# add2executable' one line
before to be defined and all the sh files. It also adds keywords like path or
documentation.

  -n  <name_of_pkg=pkgdeveloper>  name of the package.
  -w  <src_dir=\$(<name_of_pkg> path)> source directory of the package where
      'cli' directory must exist.

  -v  verbose.
  -h  prints this message.
"
exit 0
}
# ----- definition of functions finishes --------------------------------------

# ----- set up starts ---------------------------------------------------------
# General variables
output="main.py"
workdir=""
pkg_name="pkgdeveloper"
verbose=''

while getopts 'n:w:vh' flag; do
  case "${flag}" in
    n) pkg_name=${OPTARG} ;;
    w) workdir=${OPTARG} ;;

    v) verbose='-v' ;;
    h) print_help ;;
    *) echo "for usage check: pkgdev <function> -h" >&2 ; exit 1 ;;
  esac
done

source $(pkgdeveloper basics -path) GenerateMain $verbose

gm_original_dir=$(pwd)

[ -z "$workdir" ] && workdir="$($pkg_name path)" || fail "'package path' does
  not exist"
cd "$workdir/cli" || fail "moving to \"cli\" in working directory ($workdir)"

# Create the main.py file
cp "$(pkgdeveloper path)cli/main_template.py" "$output" || fail "copying template"
sed -i "s/pkgdeveloper/$pkg_name/g" $output
cd ../ || fail "moving to package directory"

# python modules
line2add=$(grep -n "pymodules = {" "cli/$output" | cut -d ":" -f 1)
mapfile -t py_files < <(find . -name "*.py" | sort)
[[ "${#py_files[@]}" -eq 0 ]] || verbose "python modules"
for file in "${py_files[@]}"
do
  file="${file#*/}"
  importer=$( echo "${file%.*}" | sed "s/\//\./g" )
  mapfile -t names < <(grep -A 1 "# add2executable" "$file" | \
    grep def | awk '{print $2}' | awk -F '(' '{print $1}')
  for name in "${names[@]}"
  do
    verbose -t " - $pkg_name.$importer.$name as $name"
    sed -i "${line2add}a \ \ \ \ \'$name\': \'$pkg_name.$importer\'," \
      "cli/$output"
  done
done

# bash scripts
line2add=$(grep -n "sh_executers = {" "cli/$output" | cut -d ":" -f 1)
mapfile -t sh_files < <(find . -name "*.sh" | sort)
[[ ${#sh_files[@]} -eq 0 ]] || verbose "bash scripts"
for file in "${sh_files[@]}"
do
  reverted=$( echo "$file" | rev )
  name=$( echo "${reverted#*.}" | cut -d "/" -f 1 | rev )
  if [ "$( echo "$file" | grep -c '/tests/')" -ne 1 ]
  then
    verbose -t " - $file as $name"
    sed -i "${line2add}a \ \ \ \ \'$name\': \'$file\'," "cli/$output"
  fi
done

# Other files
# <TODO: make this more general to include other file types speficied by the user>
line2add=$(grep -n "other_files = {" "cli/$output" | cut -d ":" -f 1)
mapfile -t mdp_files < <(find . \( -name '*.mdp' -o -name '*.tcl' -o -name '*.m' \)  | sort )
[[ "${#mdp_files[@]}" -eq 0 ]] || verbose "Other files"
for file in "${mdp_files[@]}"
do
  reverted=$( echo "$file" | rev )
  name=$( echo "${reverted#*.}" | cut -d "/" -f 1 | rev )
  if [ "$( echo "$file" | grep -c '/tests/')" -ne 1 ]
  then
    verbose -t " - $file as $name"
    sed -i "${line2add}a \ \ \ \ \'$name\': \'$file\'," "cli/$output"
  fi
done

cd "$gm_original_dir" || fail "original directory lost"

finish "$workdir/cli/$output" " updated and ready to be used with
  '$pkg_name <function> ...' including your last changes."