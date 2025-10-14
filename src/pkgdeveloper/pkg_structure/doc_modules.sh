#!/bin/bash

source "$(pkgdeveloper basics -path)" BasicModDoc

bash_help_block() {
  file=$2
  tmp_name=${file##*/}
  plain_name=${tmp_name%.sh}

  script_title="$plain_name"

  { echo ; printf '%0.s=' $(seq 1 ${#script_title}) ; echo "" ; }
  echo $script_title
  { printf '%0.s=' $(seq 1 ${#script_title}) ; echo "" ; }
  echo
  echo ".. container:: bash-script-title"
  echo
  echo '   :ref:`[script] <'$plain_name'>` **'$1'**'
  echo
  echo ".. container:: bash-script-doc"
  echo
  echo "   .. line-block::"

  $2 -h | sed "s/^/      /g"
}

create_bashscript_rst() {
  local doc_path=$1
  local rel_path=$2
  local file=$3

  local tmp_name=${file##*/}
  local plain_name=${tmp_name%.sh}
  local rst_name="$doc_path/bash_rsts_scripts/$plain_name.rst"

  echo ".. _$plain_name:" > $rst_name
  echo "" >> $rst_name
  script_title="Script of $pkg_name $plain_name"
  { echo ; printf '%0.s=' $(seq 1 ${#script_title}) ; echo "" ; } >> $rst_name
  echo $script_title >> $rst_name
  { printf '%0.s=' $(seq 1 ${#script_title}); echo ; echo ; } >> $rst_name
  echo ".. literalinclude:: ../$rel_path/$file" >> $rst_name
  echo "   :language: bash" >> $rst_name
}

print_help() {
echo "
Code that explores the files in the package and automatically create the
documentation of all classes and functions that finds in it.

   -d   <dir1,dir2...> directories to be ignored. Default: 'tests,cli'
   -f   <fil1,fil2...> files to be ignored. Default: '__init__'
   -p   <relative_path="../../src/'name'/", where name is defined with '-n'>
        relative path directory to be checked. Relative in respect to the
        directory that stores the modules documentation (see the flag -m).
   -m   <absolute_path=\$('name' path)/../../doc/modules, where name is defined
        with '-n'> absolute path to the directory that stores the modules
        documentation.
   -n   <name> pakage name.

   -h   prints this message.
"
exit 0
}
# ----- definition of functions finishes --------------------------------------

# ==== General variables ======================================================
# directories to be ignored during documentation.
raw_ign_dirs='tests'
# files to be ignored during the documentation.
raw_ign_fils=''
pkg_name="pkgdeveloper"
# relative path to the dir with the files to be documented
relative_path=""

# ==== Costumer set up ========================================================
verbose=''
mod_doc=''
while getopts 'd:f:m:n:p:vh' flag;
do
  case "${flag}" in
    d) raw_ign_dirs=${OPTARG} ;;
    f) raw_ign_fils=${OPTARG} ;;
    m) mod_doc=${OPTARG};;
    n) pkg_name=${OPTARG};;
    p) relative_path=${OPTARG};;
    
    v) verbose='-v' ;;
    h) print_help ;;
    *) echo "for usage check: pkgdeveloper <function> -h" >&2 ; exit 1 ;;
  esac
done

# relative path to the dir with the files to be documented
if [ -z $relative_path ]
then
  relative_path="../../src/$pkg_name/"
fi

if [ -z $mod_doc ]
then
  mod_doc=$($pkg_name path)
fi

source "$(pkgdeveloper basics -path)" BasicModDoc "$verbose"
verbose -t "Package name: $pkg_name, doc path: $mod_doc, relative path:
            $relative_path"

# absolute to the dir with the files to be documented
mod_path="$mod_doc/$relative_path"

# checks existence of paths
[ -d $mod_doc ] || fail "path to the documentation directory does not exist
  ($mod_doc). Check the flag -m for more details"

[ -d $mod_path ] || fail "path to the directory to be documented does not
  exist ($mod_path). Check the flag -p for more details"
                    

# Checks and corrects the documentation on the scripts.
warning "It is recommended to use 'pkgdeveloper add_python_doc ...' first in" \
        " order to have a complete documentation."

# directories to be ignore during the check.
mapfile -t ignore_dirs < <(echo "$raw_ign_dirs" | tr ',' '\n')
# files to be ignore during the check.
mapfile -t ignore_files < <(echo "$raw_ign_fils,$raw_ign_dirs" | tr ',' '\n')


# Directories
toignore=""
for ign_dir in "${ignore_dirs[@]}"
do
  toignore="$toignore $mod_path/$ign_dir"
  bool_ign="$bool_ign -path '*$ign_dir*' -o"
done
# ==== BODY ===================================================================
# python autodoc
sphinx-apidoc -ET -o $mod_doc $mod_path ${toignore[@]}


# Bash scripts: for each bash script it creates two files: one for the
# file documentation (in bash_rsts_doc) and the other for the raw code (in
# bash_rsts_scripts).
verbose "bash scripts"

cd $mod_path
mapfile -t scripts < <(eval "find . -type f -not \(" \
                       "${bool_ign::-2}" "-prune \) -name '*.sh'" )

# create directory for the raw scripts if it doesn't exist
if [ ! -d "$mod_doc/bash_rsts_scripts" ] && [ ${#scripts[@]} -ne 0 ]
then
  mkdir $mod_doc/bash_rsts_scripts
fi

# create directory for the raw documentations if it doesn't exist
if [ ! -d "$mod_doc/bash_rsts_doc" ] && [ ${#scripts[@]} -ne 0 ]
then
  mkdir $mod_doc/bash_rsts_doc
fi

# fill up the two directories
for file in ${scripts[@]}
do
  verbose -t $file

  path_bash=${file%/*}
  if [[ "$path_bash" == "." ]]
  then
    path_bash=""
  fi

  title_in_rst=${file//\.\//}
  title_in_rst=$pkg_name/$title_in_rst

  rst_name=${path_bash//\.\//.}
  rst_name=${rst_name//\//.}
  rst_name=$pkg_name${rst_name}.rst

  tmp_name=${file##*/}
  plain_name=${tmp_name%.sh}

  # Create documentation and script
  bash_help_block $title_in_rst $file > $mod_doc/bash_rsts_doc/$plain_name.rst
  create_bashscript_rst $mod_doc $relative_path $file

  # creates the rst of the stem
  if [ ! -f $mod_doc/$rst_name ]
  then
    touch $mod_doc/$rst_name
    echo
    title=${rst_name%.rst}
    { printf '%0.s=' $(seq 1 ${#title}); echo ; } >> $mod_doc/$rst_name
    echo $title >> $mod_doc/$rst_name
    { printf '%0.s=' $(seq 1 ${#title}); echo ; echo ; } >> $mod_doc/$rst_name
  fi

  # Adds stem to doc of package
  if ! grep -q "${rst_name%.rst}" $mod_doc/$pkg_name.rst
  then
    # Next line assumes that the first toctree is the main one
    mapfile -t lines < <( grep -n ".. toctree::" $mod_doc/$pkg_name.rst | \
                          cut -d ":" -f 1 )
    sed -i "$(( ${lines[0]} + 2 ))a \ \ \ ${rst_name%.rst}" $mod_doc/$pkg_name.rst
  fi

  # add hidden toc
  if ! grep -q ":hidden:" $mod_doc/$rst_name
  then
     echo >> $mod_doc/$rst_name
     echo ".. toctree::" >> $mod_doc/$rst_name
     echo "   :hidden:" >> $mod_doc/$rst_name
     echo >> $mod_doc/$rst_name
     echo >> $mod_doc/$rst_name
  fi
  # guarantee doc and script in the hidden toc
  if ! grep -q "bash_rsts_scripts/$plain_name" $mod_doc/$rst_name
  then
     mapfile -t lines < <( grep -n ":hidden:" $mod_doc/$rst_name | \
                           cut -d ":" -f 1 )
     sed -i "$(( ${lines[0]} + 1 ))a \ \ \ bash_rsts_scripts/$plain_name" $mod_doc/$rst_name
  fi
  
  # Insert block
  if ! grep -q ".. include:: bash_rsts_doc/$plain_name.rst" $mod_doc/$rst_name
  then
    ref_name=${rst_name%.rst}-$plain_name
    ref_name=${ref_name//_/-}
    ref_name=${ref_name//\./-}
    { echo ; echo ".. _$ref_name:" ; echo ;
      echo ".. include:: bash_rsts_doc/$plain_name.rst" ;
    } >> $mod_doc/$rst_name 
  fi
done


for rstbash_file in $(ls $mod_doc/bash_rsts_scripts)
do
  mod=${rstbash_file%.rst}
  if ! find . -name "$mod.sh"
  then
    warning "$mod.sh exists in your documentation but not in your package. The
      next warnings tell you what you should do."
    
    warning "remove $rstbash_file from $mod_doc/bash_rsts_scripts and verify
      that it does not exist in $mod_doc/bash_rsts_doc"

    containers=$(grep -r bash_rsts_doc/"$mod.sh"})
    if [ ! -z "$containers" ]
    then
      warning "remove bash_rsts_doc/"$mod.sh" and the corresponding
        reference line just before from: ${containers[@]}"  
    fi

    containers=$(grep -r bash_rsts_scripts/"$mod.sh"})
    if [ ! -z "$containers" ]
    then
      warning "remove bash_rsts_scripts/"$mod.sh" and the corresponding
        reference line just before from: ${containers[@]}"  
    fi
  fi 

done

verbose "TIP: you can use 'pkgdeveloper files_tree' to build a map of your
        package structure and insert it in the index.rst file."

cd $original_bash_blocks

finish
