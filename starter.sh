#!/bin/bash

# ----- definition of functions -----------------------------------------------
print_help() {
echo "
Usage: pkgcreator -n name_of_newborn_pkg [-w workdir] [-v] [-h]

Creates a new python package with the basic structure and files.

  -v  verbose.
  -h  prints this message.
"
exit 0
}

# ----- set up starts ---------------------------------------------------------
# General variables
name_of_newborn_pkg=""
workdir="$PWD"

verbose='false'
while getopts 'n:w:vh' flag;
do
  case "${flag}" in
    n) name_of_newborn_pkg=${OPTARG} ;;
    w) workdir=${OPTARG} ;;

    v) verbose='true' ;;
    h) print_help ;;
    *) echo "for usage check: pkgcreator <function> -h" >&2 ; exit 1 ;;
  esac
done

# <TODO: change the following pkgdeveloper>
source "$(myutils basics -path)" starter $verbose
# --- pre-body checks ---------------------------------------------------------
# [ -z "$name_of_newborn_pkg" ] && echo "what is the name of the new package? "
#   && read name_of_newborn_pkg
# [ -z "$name_of_newborn_pkg" ] && fail "you must provide a name for the new
#   package"
# 
# if [ -d "$name_of_newborn_pkg/$name_of_newborn_pkg" ]
# then
#   fail "the package $name_of_newborn_pkg already exists in $workdir"
# fi
# ---- BODY -------------------------------------------------------------------

#cd $workdir
#mkdir $name_of_newborn_pkg
#cd $name_of_newborn_pkg
cat << EOF > README.md 
# $name_of_newborn_pkg

<TODO: add description>
EOF

cat << EOF > pyproject.toml
[project]
name = "$name_of_newborn_pkg"
version = "1.0.0-alpha"
description = "<TODO: add a short description>"
readme = "README.md"
license = {text = "MIT"}
authors = [
    { name = "<TODO: add authorname>", email = "<TODO: add e-mail>" }
]
requires-python = ">=3.9"
classifiers = [
    "Programming Language :: Python :: 3",
    "License :: OSI Approved :: GNU General Public License (GPL)",
    "Operating System :: OS Independent"
]
dependencies = [
    "pytest",
    "sphinx"
]

[project.scripts]
$name_of_newborn_pkg = "$name_of_newborn_pkg.cli.main:main"

[tool.setuptools.packages.find]
where = ["src"]

[tool.setuptools.package-data]
"*" = ["*.sh"]

[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

EOF

# cli directory

mkdir -p src/$name_of_newborn_pkg/cli
touch src/$name_of_newborn_pkg/cli/__init__.py
#cp $(myutils )

# test directory
mkdir -p tests  
touch tests/__init__.py