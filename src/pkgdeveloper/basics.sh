#!/bin/bash

print_help() {
echo -e "
This script contains basics tools for other bash scripts. With the code in
here, you can use the next functions

- <first_argument> Add a label in every message.
- <second_argument> true or false to activate or deactivate the verbose mode.
- adjust <text>: add the label and print what <text> in an adjusted column of
  80 characters.
- verbose <text>: besides of the label, it adds the keyword VERBOSE in to the
  begining of <text> and print the adjusted text.
- warning <text>: besides of the label, it adds the keyword WARNING in to the
  begining of <text> and print the adjusted text.
- finish <text>: besides of the label, it use verbose to print <text> of the
  word "finish" if <text> is not given. It also stops the script with 'exit 0'
- fail <text>: besides of the label, it adds the keyword VERBOSE in to the
  begining of <text> and print the adjusted text. It also print the message
  in the std_error and stops the script with 'exit 1'
"

exit 0
}

while getopts 'h' flag;
do
  case "${flag}" in
    h) print_help ;;
    *) echo "for usage check: pkgdeveloper <function> -h" >&2 ; exit 1 ;;
  esac
done


# Definition functions and variables that are used along the whole package.

# ------ variables ------------------------------------------------------------
array_bfnames=( "$1" "${array_bfnames[@]}" )
basic_functions_name=${array_bfnames[0]}

if [ "$2" == "-v" ]
then
  eval "BASICVERBOSE_${basic_functions_name[0]}=true"
else
  eval "BASICVERBOSE_${basic_functions_name[0]}=false"
fi

# ------ functions ------------------------------------------------------------
# Function that adjustes the text to 80 characters
adjust () {
  text="++++ ${basic_functions_name[0]}: $*"
  addchar=$(( 80 - ${#text} % 80 ))
  text="$text $( perl -E "say '+' x $addchar" )"
  nlines=$(( ${#text} / 80 ))
  for (( w=0; w<=nlines-1; w++ ))
  do
    echo "${text:$(( w * 79 )):79}"
  done
}

adjust_text () {
  text="$*"
  nlines=$(( ${#text} / 80 ))
  for (( w=0; w<=nlines; w++ ))
  do
    echo "${text:$(( w * 79 )):79}"
  done
}

# prints some text adjusted to 80 characters per line, filling empty spaces
# with +
verbose () {
  if [[ "$(eval "echo \$BASICVERBOSE_${basic_functions_name[0]}")" == "true" ]]
  then
    if [[ "$1" == "-t" ]]
    then
      shift
      # shellcheck disable=SC2068
      adjust_text $@
    else
      # shellcheck disable=SC2068
      adjust "VERBOSE" $@ "$( date )"
    fi
  fi
}

warning () {
  # shellcheck disable=SC2068
  adjust "WARNING" $@ "$( date )" >&2
}

finish () {
  if [ "$#" -ne 0 ]
  then
    # shellcheck disable=SC2068
    verbose $@ "$( date )"
  else
    verbose finish "$( date )"
  fi
  echo
  array_bfnames=( "${array_bfnames[@]:1}" )
  basic_functions_name=${array_bfnames[0]}
  exit 0
}

# Function that returns the error message and stops the run if something fails.
fail () {
  # shellcheck disable=SC2068
  adjust "ERROR" $@ "$( date )"
  # shellcheck disable=SC2068
  finish "ERROR" $@ "$( date )" >&2
  exit 1
}

verbose "STARTS"
