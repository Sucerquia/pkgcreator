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

which sphinx-quickstart > /dev/null || fail "sphinx-quickstart not found.
  Please install Sphinx (e.g. pip install sphinx)"

ext=( "sphinx.ext.viewcode" \
      "sphinx.ext.napoleon" \
      "sphinx.ext.intersphinx" \
      "sphinx.ext.mathjax"
      "sphinx.ext.githubpages" )
missing_extensions=( )
for extension in nbsphinx jupyter_sphinx ipython matplotlib sphinxcontrib-mermaid
do
  pip show $extension > /dev/null && ext+=( $extension ) \
    || missing_extensions+=( $extension )
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

mkdir -p doc
cd doc
[ -f Makefile ] && fail "documentation already exists"

sphinx-quickstart --quiet --project="$name_of_pkg" \
                          --author="$authorname"

sed -i "/extensions =/c extensions = [" conf.py
n=$(grep -n "extensions = \[" conf.py | cut -d: -f1 | head -n 1 )
sed -i "${n}a \ \ ]" conf.py
verbose "Adding the following extensions to conf.py:"
for e in ${ext[@]}
do
  verbose -t " - $e"
  sed -i "${n}a \ \ '$e'," conf.py
done

cat << EOF >> conf.py

# Add custom CSS file
html_css_files = [
    'custom.css',  # Ensure the file path is correct
]

from docutils import nodes
from docutils.parsers.rst import roles

def bashscript_role(name, rawtext, text, lineno, inliner, options={}, content=[]):
    """
    Custom role :bashscript:\`display <target-label>\` to render a boxed ref link.
    """
    env = inliner.document.settings.env

    parts = text.split('.')
    target = 'modules/' + '.'.join(parts[:-1])
    ref = '#' + text.replace('.', '-')
    ref = ref.replace('_', '-')
    display_text = text.replace('.', '/') + '.sh'


    # Generate relative URI correctly using positional args
    refuri = env.app.builder.get_relative_uri(env.docname, target) + ref

    # Create reference node
    refnode = nodes.reference(rawtext, display_text, refuri=refuri)
    refnode['classes'].append('bashscript')

    return [refnode], []

# Register the role
roles.register_local_role('bashscript', bashscript_role)
EOF

mkdir -p modules

if [ which "$name_of_pkg" > /dev/null ]
then
  pkgdeveloper add_python_doc -n "$name_of_pkg" \
                              -p "$(pwd)/../src/$name_of_pkg/" \
    || fail "Issue running 'pkgdeveloper add_python_doc -n $name_of_pkg
         -p $(pwd)/../src/$name_of_pkg/'"
  pkgdeveloper doc_modules -n "$name_of_pkg" -p "../../src/$name_of_pkg/" \
    -m "$(pwd)/modules" || \
    fail "Issue running 'pkgdeveloper doc_modules -n $name_of_pkg 
      -p ../../src/$name_of_pkg/"
else
  warning "After installing the package and adding your scripts, consider to
    use 'pkgdeveloper add_python_doc' and 'pkgdeveloper doc_modules'"
fi

sed -i "/:caption: Contents:/ a \ \ \ modules\/$name_of_pkg" index.rst

pip show sphinxcontrib-mermaid > /dev/null  && pkgdeveloper files_tree \
  -d ../src/$name_of_pkg -n $name_of_pkg >> index.rst

mkdir -p _static

cp $(pkgdeveloper path)/../../doc/_static/custom.css _static/
