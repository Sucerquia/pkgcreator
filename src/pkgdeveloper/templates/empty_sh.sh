#!/bin/bash

#SBATCH --cpus-per-task=1
#SBATCH -t 24:00:00
#SBATCH --output=%x-%j.o
#SBATCH --error=%x-%j.e


# ----- definition of functions -----------------------------------------------
print_help() {
echo "
Create a new script with a standard structure.

  -n  <name_of_newborn_script>  name of the new script.
  -o  <outputdir=./> output directory.
  -p  <pkg_name>  name of the package where the script will be stored.

  -v  verbose.
  -h  prints this message.
"
exit 0
}

# ----- set up starts ---------------------------------------------------------
# General variables
name=''
outputdir="./"
verbose=''
while getopts 'n:o:p:vh' flag;
do
  case "${flag}" in
    n) name=${OPTARG} ;;
    o) outputdir=${OPTARG} ;;
    p) pkg_name=${OPTARG} ;;

    v) verbose='-v' ;;
    h) print_help ;;
    *) echo "for usage check: pkgdeveloper <function> -h" >&2 ; exit 1 ;;
  esac
done

[ -z "$name" ] && echo "what is the name of the new script? " && read name
[ -z "$name" ] && fail "you must provide a name for the new script"

# shellcheck disable=SC1090
source "$(pkgdeveloper basics -path)" CreateBashScript "$verbose"

# starting information
verbose -t "JOB information"
verbose -t "==============="
verbose -t " Command:" "$0" "$@"

# ---- BODY -------------------------------------------------------------------
verbose "Creating $name in $outputdir"
cd "$outputdir" || fail "outputdir ($outputdir) does not exist"

if [[ "${name##*.}" != "sh" ]]
then
  name=$name.sh
fi

cp $(pkgdeveloper bash-template -path) "$name"
sed -i "s/NameOfYourProcess/${name%.sh}/g" "$name"
sed -i "s/<replace_pkgname>/${pkg_name}/g" "$name"
sed -i "s/<function>/${name%.sh}/g" "$name"
chmod +x "$name"

# ---- END --------------------------------------------------------------------
finish "$output"/"$name" " created and ready to be filled, it is empty.
  '${pkg_name} basics' should exist to use it properly."
