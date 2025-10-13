#!/bin/bash

# ----- definition of functions -----------------------------------------------
print_help() {
echo "
Check the basic structure of all the given files as arguments.

It checks that all the bash scripts have flags support, verbose and help.

  -v  verbose.
  -c  run in a cluster.
"
exit 0
}

# ----- set up starts ---------------------------------------------------------
verbose=''
while getopts 'h' flag;
do
  case "${flag}" in
    h) print_help ;;
    *) echo "for usage check: pkgdeveloper <function> -h" >&2 ; exit 1 ;;
  esac
done


# checks that it has the basic structure
source $(pkgdeveloper basics -path) just_check 'true'

for file in $@
do
  inhelp='false'
  incase='false'
  inflags='false'
  defa='false'
  whencalling='false'

  if grep -q "while getopts" $file
  then
    grep -E -B 1 "h+[[:space:]]+prints this message" $file | head -n 1 | grep -qE "v+[[:space:]]+verbose" || inhelp='true'
    grep -q "vh' flag" $file || incase='true'
    grep -q "verbose='-v'" $file || inflags='true'
    grep -q "^verbose=" $file || defa='true'
    # <TODO: the next line should not be pkgdeveloper basics, but any script that sources it>
    grep "source" $file | grep "pkgdeveloper basics" | grep -q "\$verbose" || whencalling='true'

    if [[ "$inhelp" == 'true' ]]
    then
      echo $file inhelp
      
      n=$(grep -n -E -B 1 "h+[[:space:]]+prints this message" $file | head -n 1 | cut -d "-" -f 1)
      if [ ${#n} -eq 0 ]
      then
        echo "ATTENTION inhelp in $file"
      else
        n=$(( n + 1 ))
        sed -i "${n}s/^/  -v  verbose.\n/" $file
      fi
    fi

    if [[ "$incase" == 'true' ]]
    then
      echo $file incase
      sed -i "s/h' flag/vh' flag/g" $file
    fi

    if [[ "$inflags" == 'true' ]]
    then
      echo $file inflags
      n=$(grep -n "h) print_help" $file | cut -d ":" -f 1)
      if [ ${#n} -eq 0 ]
      then
        echo "ATTENTION h) in $file"
      else
        sed -i "${n}s/^/  v)  verbose='-v' ;;\n/" $file
      fi
    fi

    if [[ "$defa" == 'true' ]]
    then
      echo $file defa
      n=$(grep -n "while getopts" $file | cut -d ":" -f 1)
      if [ ${#n} -eq 0 ]
      then
        echo "ATTENTION defa $file"
      else
        sed -i "${n}s/^/verbose=''\n/" $file
      fi
    fi

    if [[ "$whencalling" == 'true' ]]
    then
      echo $file whencalling
      if [ ${#n} -eq 0 ]
      then
        echo "ATTENTION whenca $file"
      else
        n=$(grep -n "pkgdeveloper basics" $file | cut -d ":" -f 1)
      fi
      sed -i "${n}s/$/ \$verbose/" $file
    fi
  fi
done

# TODO: Add checking Job information in files like command and so: checl
# TODO: compute_forces for an example

# TODO: change headings in bash scripts (functions, settings, body)

# TODO: add finish all codes that sources pkgdeveloper basics
