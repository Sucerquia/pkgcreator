#!/bin/bash

# ----- definition of functions -----------------------------------------------
print_help() {
echo "
Creates a new python package with the basic structure and files.

  -n  <name_of_newborn_pkg>  name of the new package.
  -w  <workdir=./>           working directory.

  -v  verbose.
  -h  prints this message.
"
exit 0
}

# ----- set up starts ---------------------------------------------------------
# General variables
name_of_newborn_pkg=""
workdir="$PWD"
authorname=""
verbose=''
while getopts 'a:n:w:vh' flag;
do
  case "${flag}" in
    a) authorname=${OPTARG} ;;
    n) name_of_newborn_pkg=${OPTARG} ;;
    w) workdir=${OPTARG} ;;

    v) verbose='-v' ;;
    h) print_help ;;
    *) echo "for usage check: pkgcreator <function> -h" >&2 ; exit 1 ;;
  esac
done

source "$(pkgdeveloper basics -path)" starter $verbose
missing_extensions=( )
for extension in nbsphinx jupyter_sphinx ipython matplotlib sphinxcontrib-mermaid
do
  pip show $extension > /dev/null || missing_extensions+=( $extension )
done

if [ ${#missing_extensions[@]} -gt 0 ]
then
  verbose "The next extensions would improve your documentation:"
  for ext in "${missing_extensions[@]}"
  do
    verbose " - $ext"
  done
  echo "Do you want to stop this process and install them first? (y/n) "
  read answer
  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]
  then
    exit 1
  fi
fi

# --- pre-body checks ---------------------------------------------------------
[ -z "$name_of_newborn_pkg" ] && echo "what is the name of the new package? " \
  && read name_of_newborn_pkg
[ -z "$name_of_newborn_pkg" ] && fail "you must provide a name for the new
   package"

if [ -d "$workdir/$name_of_newborn_pkg" ]
then
  fail "The package $name_of_newborn_pkg already exists in $workdir"
fi

[ -z "$authorname" ] && echo "what is the author name? " && read authorname
[ -z "$authorname" ] && fail "you must provide an author name"

verbose -t "Creating package $name_of_newborn_pkg in $workdir by the author
  $authorname"
# ---- BODY -------------------------------------------------------------------
verbose -t "Create directory and move into it"
cd $workdir
mkdir $name_of_newborn_pkg
cd $name_of_newborn_pkg

verbose -t "Creating README.md and pyproject.toml"
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
    { name = "$authorname", email = "<TODO: add e-mail>" }
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

verbose -t "Creating src directory and package"
# cli directory
mkdir -p src/$name_of_newborn_pkg/cli
touch src/$name_of_newborn_pkg/cli/__init__.py
verbose -t "Create main.py with pkgdeveloper generate_main"
pkgdeveloper generate_main -n "$name_of_newborn_pkg" \
  -w src/"$name_of_newborn_pkg"/ \
  "$verbose" || fail "Issue running 'pkgdeveloper generate_main -n
    $name_of_newborn_pkg  -w src/$name_of_newborn_pkg/"

verbose -t "Create documentation"
# documentation directory
pkgdeveloper start_doc -a "$authorname" \
                       -n "$name_of_newborn_pkg" \
                       "$verbose" || \
  fail "Issue running 'pkgdeveloper start_doc -a $authorname
    -n $name_of_newborn_pkg'" 

# test directory
mkdir -p tests
echo "[pytest]" > pytest.ini
echo 'testpaths = "tests"' >> pytest.ini
touch tests/__init__.py
