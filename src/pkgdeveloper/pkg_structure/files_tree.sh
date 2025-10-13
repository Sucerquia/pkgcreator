#!/bin/bash


print_help() {
echo "
Function that creates a mermaid map of a directory structure.

Usage: pkgdeveloper files_tree <path to dir to be mapped> <pattern> [ <ignoring patters> ... ]

The output is the string that you have to locate in an rst file in order to
render your map. In principle, the output can be used in markdown files
changing the corresponding keywords.

Example of output in the case that the directory to be mapped contains the subdirectories
cli and pkg_structure and the pattern is 'pkgdeveloper':

.. mermaid::
   :align: center

   graph TD
   node1["pkgdeveloper"]
   click node1 "modules/pkgdeveloper.html" _self
     node1 --> node2["cli"]
     click node2 "modules/pkgdeveloper.cli.html" _self
     node1 --> node3["pkg_structure"]
     click node3 "modules/pkgdeveloper.pkg_structure.html" _self
"
exit 0
}
# ----- definition of functions finishes --------------------------------------

# ==== Costumer set up ========================================================
# Function to recursively generate Mermaid nodes
generate_tree() {
    local path="$1"
    local parent="$2"
    local indent="$3"
    local node_id="node$((++NODE_COUNTER))"

    # Add the current directory to the Mermaid graph
    if [[ "$parent" == "root" ]]
    then
      echo "${indent}${node_id}[\"$pkg_name\"]"
    else
      echo "${indent}${parent} --> ${node_id}[\"$(basename "$path")\"]"
    fi
    # Add a click action for the node to link to the directory path
    if [[ "$path" == "." ]]
    then
       file=$pkg_name.html
    else
      file=${path//\.\//}
      file=$pkg_name/$file
      file=${file//\//\.}.html
    fi

    link=modules/$file
    echo "${indent}click $node_id \"$link\" _self"

    # Iterate through subdirectories only
    for child in "$path"/*;
    do
      [ -d "$child" ] || continue # Skip files
      # Skip directories matching ignore patterns
      for pattern in "${IGNORE_PATTERNS[@]}"; do
        if [[ "$(basename "$child")" == $pattern ]]; then
            continue 2
        fi
      done
      generate_tree "$child" "$node_id" "$indent  "
    done
}

DIR_PATH=''
pkg_name=''
verbose=''
while getopts 'd:i:n:vh' flag;
do
  case "${flag}" in
    d) DIR_PATH=${OPTARG} ;;
    i) ignore_patterns=${OPTARG};;
    n) pkg_name=${OPTARG};;

    v) verbose='-v' ;;
    h) print_help ;;
    *) echo "for usage check: pkgdeveloper <function> -h" >&2 ; exit 1 ;;
  esac
done

source "$(pkgdeveloper basics -path)" FilesThree "$verbose"

if [ -z $DIR_PATH ]
then
  DIR_PATH="$($pkg_name path)" || fail "could not determine the path to the
                                        package. Use -d to set it up."
fi

IGNORE_PATTERNS=( $( echo ${ignore_patterns//,/ } ) bash_rsts_doc
                  bash_rsts_scripts )
NODE_COUNTER=0

cd $DIR_PATH
DIR_PATH='.'


# Start the RST file content
echo ".. mermaid::"
echo "   :align: center"
echo ""
echo "   graph TD"

# Generate the tree
generate_tree "$DIR_PATH" "root" "   "
