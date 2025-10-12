#!/bin/bash

# ----- definition of functions -----------------------------------------------
print_help() {
echo "

  -n  <name_of_pkg>  name of the new package.
  -w  <workdir=./>           working directory.

  -v  verbose.
  -h  prints this message.
"
exit 0
}

# ----- set up starts ---------------------------------------------------------
# General variables
name_of_pkg=""
workdir="$PWD"
authorname=""
def_var="inse here your default"
cascade='false'
verbose=''
while getopts 'a:n:w:vh' flag;
do
  case "${flag}" in
    a) authorname=${OPTARG} ;;
    n) name_of_pkg=${OPTARG} ;;
    w) workdir=${OPTARG} ;;

    v) verbose='-v' ;;
    h) print_help ;;
    *) echo "for usage check: pkgdeveloper <function> -h" >&2 ; exit 1 ;;
  esac
done

source "$(pkgdeveloper basics -path)" StartDocumentation $verbose

# ---- BODY -------------------------------------------------------------------

cd $workdir || fail "moving to working directory"

[ -z "$name_of_pkg" ] && read -p "what is the name of the package? " \
                                 name_of_pkg
[ -z "$name_of_pkg" ] && fail "you must provide a name for the package"

[ -z "$authorname" ] && read -p "what is the author name? " authorname
[ -z "$authorname" ] && fail "you must provide an author name"

mkdir -p doc
cd doc
[ -f Makefile ] && fail "documentation already exists"

sphinx-quickstart --quiet --project="$name_of_pkg" \
                          --author="$authorname"

pkgdeveloper add_python_doc -n "$name_of_pkg" -p "$(pwd)../src/$name_of_pkg" \
  || fail "adding python doc to conf.py"

pkgdeveloper doc_modules -n "$name_of_pkg" \
                         -p "../../src/$name_of_pkg" \
                         -m "$(pwd)/modules" || fail "documenting modules"
sed -i "/:caption: Contents:/ a \ \ \ modules\/$name_of_pkg" index.rst


pkgdeveloper files_tree ../src/$name_of_pkg $name_of_pkg >> index.rst


