#!/bin/bash


# ----- definition of functions -----------------------------------------------
print_help() {
echo "
Check the structure of a package. All checkers run by default.

  -d  src directory of the package. Defatul: \"\$pkgdeveloper -path\"
  -p  pep8 convention in all python scripts.
  -s  ShellCheck in all bash scripts.
  -t  check tests.

  -h  prints this message.
"
exit 0
}

# ---- set up -----------------------------------------------------------------
all="true"
pep8="false"
shellcheck="false"
tests="false"
check_dir="$(pkgdeveloper path)"
while getopts 'd:psth' flag; do
  case "${flag}" in
    d) check_dir=${OPTARG};;
    p) pep8='true' ; all="false" ;;
    s) shellcheck='true' ; all="false" ;;
    t) tests='true' ; all="false" ;;

    h) print_help ;;
    *) echo "for usage check: pkgdeveloper <function> -h" >&2 ; exit 1 ;;
  esac
done

if $all
then
  pep8="true"
  shellcheck="true"
  tests="true"
fi

if $tests
then
  echo ; echo
  # Ignore directories and files for tests checker
  ign_dirs='pycache,cli,examples,doc_scripts,pre-deprected,tutorials,tests'
  ign_fils='__init__.'
  pkgdeveloper check_tests -n pkgdeveloper -d $ign_dirs -f $ign_fils -v
fi

if $pep8
then
  source "$(pkgdeveloper basics -path)" PEP8 'true'
  original_cs=$(pwd)
  cd $check_dir || fail "package path does not exist"
  # take a look in finish to understand next two lines
  array_bfnames=( "${array_bfnames[@]:1}" )
  basic_functions_name=${array_bfnames[0]}

  for file in $(find . -name "*.py")
  do
    sed -i 's/[[:space:]]*$//g' $file
    sed -i 's/^[[:space:]]*$//g' $file
  done
  echo ; echo
  pycodestyle -h > /dev/null || fail "You need to install pycodestyle"
  pycodestyle . --exclude='pre-deprected,tests,.ipynb_checkpoints' --ignore=W605,W503
  cd "$original_cs" || fail "returning to former directory"
fi

if $shellcheck
then
  echo ; echo
  pkgdeveloper bash_style -d $check_dir -v
fi
