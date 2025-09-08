#!/bin/bash

print_help() {
echo "
Code takes the documentation of a function and checks the documentation adding
TODOs in the missing parts. The output is stored in a file called
final_<method>_doc.txt

  -f  <method> Function to be checked
  -m  <module> Module that contains the Function
  -s  <n_spaces> number of leading spaces.

  -v  verbose.
  -h  prints this message.
"
exit 0
}
# ----- definition of functions finishes --------------------------------------

# ==== Costumer set up ========================================================
spaces=0
class=""
function=""
verbose='false'
while getopts 'c:f:m:s:vh' flag;
do
  case "${flag}" in
    c) class=${OPTARG} ;;
    f) function=${OPTARG} ;;
    m) module=${OPTARG} ;;
    s) num_spaces=${OPTARG} ;;

    v) verbose='true' ;;
    h) print_help ;;
    *) echo "for usage check: pkgdeveloper <function> -h" >&2 ; exit 1 ;;
  esac
done

source "$(pkgdeveloper basics -path)" PythonDocFixer $verbose
# ==== Body ===================================================================

# ==== Initial Blocks =========================================================
if [[ "$class" == "" ]] || [[ "$function" == "" ]]
then
  leading_spaces=$(printf "%4s")
else
  leading_spaces=$(printf "%8s")
fi

pkgdeveloper function_doc $module $class $function | sed 's/^/#new_line/' > \
  $function.txt || fail "extracting old documentation"

sed -i 's/[[:space:]]*$//g' $function.txt

# In case the documentation was written without leaving the first line empty
first_line=$(head -n 1 $function.txt)
if [ "$first_line" != "#new_line" ]
then
  sed -i "1s/^/#new_line\n/" $function.txt
fi

# in Case the closing """ are not located in a new line
last_line=$(tail -n 1 $function.txt)
if [ "$last_line" != "#new_line" ]
then
  echo "#new_line" >> $function.txt
fi

# in case documentation was started from the first line.
second_line=$(head -n 2 $function.txt | tail -n 1)
if [[ "${second_line:9:1}" != " " ]]
then
  sed -i "2s/#new_line/#new_line$leading_spaces/g" $function.txt
fi

mapfile -t ns_empty < <(cat $function.txt | grep -n "#new_line$" | \
                        cut -d ":" -f1)

# ==== Existing blocks in old documentation
for (( i=0 ; i < $(( ${#ns_empty[@]} - 1 )) ; i++ ))
do
  pkgdeveloper find_blocks -f $function.txt \
                      -s ${ns_empty[$i]} \
                      -e ${ns_empty[$(( i + 1 ))]} \
                      -i -o documentation-blocks_$i || \
                      fail "finding blocks"

  # Note for developers: I had to add the next while because the creation of
  # the files was a bit delayed and that created errors trying to find those
  # files later.
  wait_until_next_file_exist documentation-blocks_${i}_001.out
done

# ==== Block of Parameters in old documentation
# In case it does not exist, a new block is created
par_block=$(grep -Exl "#new_line+[[:space:]]+Parameters" documentation-blocks_*)
if [ ${#par_block} -eq 0 ]
then
  cat << EOF > documentation-blocks_parameters.out
#new_lineParameters
#new_line==========
EOF
  sed -i "s/#new_line/#new_line$leading_spaces/g" \
    documentation-blocks_parameters.out
  par_block="documentation-blocks_parameters.out"
fi

# ==== Block of Return in old documentation
# In case it does not exist, a new block is created
return_block=$(grep -Exl "#new_line+[[:space:]]+Return" documentation-blocks_*)
if [ ${#return_block} -eq 0 ]
then
  cat << EOF > documentation-blocks_return.out
#new_lineReturn
#new_line======
#new_line# TODO: add return information
EOF
  sed -i "s/#new_line/#new_line$leading_spaces/g" \
    documentation-blocks_return.out
  return_block="documentation-blocks_return.out"
fi

# In case of documentation of a class
if [ "$function" == "" ]
then
  echo "" > $return_block
fi

# ==== Block of Definition in old documentation
# In case it does not exist, a new block is created
if [[ "$par_block" == "documentation-blocks_0_001.out" ]] || \
   [[ "$return_block" == "documentation-blocks_0_001.out" ]] || \
   [ ! -f "documentation-blocks_0_001.out" ]
then
  echo "#new_line$leading_spaces# TODO: Add definition" > \
    documentation-blocks_def.out
  definition_block="documentation-blocks_def.out"
else
  definition_block="documentation-blocks_0.out"
fi

# === Check parameters ========================================================
# parameters
mapfile -t parameters < <(pkgdeveloper args_and_defaults $module $class \
                          $function | grep -v "###" | grep -vx '' )

# insert missed parameters
if [ ${#parameters[@]} -eq 1 ] && [[ "${parameters[0]}" == "self:" ]] || \
   [ ${#parameters} -eq 0 ]
then
  # if the function does not have parameters, it creates an empty file
  rm $par_block
  touch $par_block
else
  for par in "${parameters[@]}"
  do
    if [[ "$par" == "self:" ]]
    then
      continue
    fi
    par_name=$(echo $par | cut -d ":" -f 1) # name of the parameter
    par_defa=$(echo $par | cut -d ":" -f 2) # default of the parameter
    n_par=$(grep -n $par_name $par_block | \
            cut -d ":" -f 1) # line number of the parameter
    if [ ${#n_par} -eq 0 ]
    then
      # if the variable is not defined
      if [ ${#par_defa} -ne 0 ]
      then
        automatic_def_val="# TODO: check default value"
      else
        automatic_def_val=""
      fi
      echo "#new_line$leading_spaces$par $automatic_def_val" >> \
        $par_block
      echo "#new_line$leading_spaces    # TODO: add documentation of this parameter" >> \
        $par_block
    else
      # if the variable is defined. check if the default exists
      if [ ${#par_defa} -ne 0 ]
      then
        awk -v line=$n_par 'NR==line' $par_block | grep -q Default || \
          sed -i "${n_par}s/$/\.$par_defa # TODO: check default value/" $par_block
      fi

      # check if the definition of the parameter exist
      if awk -v line=$(( n_par + 1 )) 'NR==line' $par_block | grep -q ":"
      then
        sed -i "${n_par}a\#new_line$leading_spaces    # TODO: add documentation of this parameter" $par_block
      fi
    fi
  done
fi

# === Create the final doc block ==============================================
echo "#new_line$leading_spaces\"\"\"" > final_$class-$function.txt
cat $definition_block >> final_$class-$function.txt
rm $definition_block

n_lines_in_par_block=$(wc -l < $par_block)
if  [ $n_lines_in_par_block -ne 0 ]
then
  echo "#new_line" >> final_$class-$function.txt
  cat $par_block >> final_$class-$function.txt
  rm $par_block
fi

echo "#new_line" >> final_$class-$function.txt
cat $return_block >> final_$class-$function.txt
rm $return_block

# rest of blocks
for other_doc_block in documentation-blocks*.out
do
  echo "#new_line" >> final_$class-$function.txt
  cat $other_doc_block >> final_$class-$function.txt
  rm $other_doc_block
done
echo "#new_line$leading_spaces\"\"\"" >> final_$class-$function.txt

# ==== cleaning
# Remove newline comments
sed -i 's/#new_line//g' final_$class-$function.txt
# Remove tailing spaces
sed -i 's/[[:space:]]*$//g' $function.txt

# Remove unnecessary empty space
while [[ "$(tail -n 2 final_$class-$function.txt | head -n 1)" == "" ]]
do
  total_lines=$(wc -l < final_$class-$function.txt)
  sed -i "$(( total_lines - 1 ))d" final_$class-$function.txt
done
rm $function.txt

finish
