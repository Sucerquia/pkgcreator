#!/bin/bash

#SBATCH -N 1                   # number of nodes
#SBATCH -n 9
#SBATCH --cpus-per-task=1
#SBATCH -t 24:00:00
#SBATCH --output=%x-%j.o
#SBATCH --error=%x-%j.e
#SBATCH --exclusive


# ----- definition of functions -----------------------------------------------
print_help() {
echo "
Use this template to create your scripts with a standard structure

  -d  <variable> add the description of the variable.
  -c  usually used when submitted in a cluster to import modules.

  -v  verbose.
  -h  prints this message.
"
exit 0
}

# ----- set up starts ---------------------------------------------------------
# General variables
def_var="inse here your default"
cascade='false'
verbose=''
while getopts 'cd:vh' flag;
do
  case "${flag}" in
    d) def_var=${OPTARG} ;;
    c) cascade='true' ;;

    v) verbose='-v' ;;
    h) print_help ;;
    *) echo "for usage check: <replace_pkgname> <function> -h" >&2 ; exit 1 ;;
  esac
done

source "$(pkgdeveloper basics -path)" Name_of_your_process $verbose

# starting information
verbose -t "JOB information"
verbose -t " * Date:"
verbose -t "$(date)"
verbose -t " * Command:"
verbose -t "$0" "$@"

# load modules
if $cascade
then
  # Add flags to restart if necessary (and if you added a restart function before)
  load_modules 
fi

# ---- BODY -------------------------------------------------------------------
finish "message to finish"
