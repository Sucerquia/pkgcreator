#!/bin/bash


# ----- definition of functions -----------------------------------------------
print_help() {
echo "
Code that explores the files in the package and automatically creates the
documentation of all classes and functions that finds in it.

  -d  <dir1,dir2...> directories to be ignored.
      Default: 'pycache,tests,tutorials,pre-deprected'
  -f  <fil1,fil2...> files to be ignored. Default: '__init__'
  -n  <name> pkg name. Default: pkgdeveloper
  -p  <absolute_path> path directory to be checked (no relative path).
      Default: \"\$pkgdeveloper path\"

  -v  verbose.
  -h  prints this message.
"
exit 0
}

insert_doc() {
  local doc_num_start=$1
  local file_doc=$2
  local func=$3
  local class=$4

  # Remove prev documentation first
  if awk -v numline=$doc_num_start 'NR==numline' \
       $file_doc | grep -q "\"\"\""
  then
    fst_l_doc=$(sed -n "${doc_num_start}{p;q}" $file_doc)
    wo_starting=${fst_l_doc#*\"\"\"}
    wo_clossing=${wo_starting%\"\"\"}
    if [ ${#wo_starting} -eq ${#wo_clossing} ]
    then
      doc_num_end=$(tail -n +$(( doc_num_start + 1 )) $file_doc | \
                    grep -n "\"\"\"" | head -n 1 | cut -d ":" -f 1)
      doc_num_end=$(( doc_num_end + doc_num_start ))
      sed -i "${doc_num_start},${doc_num_end}d" $file_doc
    else
      sed -i "${doc_num_start}d" $file_doc
    fi
  fi

  # insert new documentation
  sed -i "$(( doc_num_start - 1 ))r final_$class-$func.txt" $file_doc
}

# ----- definition of functions finishes --------------------------------------

# ---- BODY -------------------------------------------------------------------
# ==== General variables ======================================================
# directories to be ignored during documentation.
raw_ign_dirs='pycache,tests,ipynb_checkpoints,tutorials,pre-deprected'
# files to be ignored during the documentation.
raw_ign_fils='__init__.'
pkg_name="pkgdeveloper"
mod_path=$(pkgdeveloper path)
# ==== Costumer set up ========================================================
verbose='false'
while getopts 'd:f:m:n:p:vh' flag;
do
  case "${flag}" in
    d) raw_ign_dirs=${OPTARG} ;;
    f) raw_ign_fils=${OPTARG} ;;
    n) pkg_name=${OPTARG};;
    p) mod_path=${OPTARG};;

    v) verbose='true' ;;
    h) print_help ;;
    *) echo "for usage check: pkgdeveloper <function> -h" >&2 ; exit 1 ;;
  esac
done

source "$(pkgdeveloper basics -path)" AddPythonDoc $verbose

mapfile -t ignore_dirs < <(echo "$raw_ign_dirs" | tr ',' '\n')
# files to be ignore during the check.
mapfile -t ignore_files < <(echo "$raw_ign_fils,$raw_ign_dirs" | tr ',' '\n')

# ==== Directories ============================================================
cd "$mod_path" || fail "$mod_path not found"

# directories to ignore
for ign_dir in "${ignore_dirs[@]}"
do
  bool_ign="$bool_ign -path '*$ign_dir*' -o"
done
# files to ignore
for ign_fil in "${ignore_files[@]}"
do
  bool_ign="$bool_ign -name '*$ign_fil*' -o"
done

# files
mapfile -t pck_fils < <(eval "find . -type f -not \(" "${bool_ign::-2}" \
                             "-prune \)" )

for fil in "${pck_fils[@]}"
do
  verbose $fil
  ext=$(echo "$fil" | cut -d '.' -f3 )
  # Python files
  if [ "$ext" == 'py' ]
  then
    module=$(echo "$pkg_name"${fil//\.\//\.} | sed "s/\//\./g" | sed "s/\.py//g")
    # Functions
    mapfile -t functions < <(grep "^def " "$fil" | awk '{print $2}' | \
                             cut -d "(" -f 1)
    if [ ${#functions} -ne 0 ]; then verbose "functions"; fi
 
    for func in ${functions[@]}
    do
      echo $func
      # The output of the next function is stored in final_<func>_doc.txt
      pkgdeveloper python_doc_fixer -f "$func" -m "$module" || \
        fail "creating new documentation"
      wait_until_next_file_exist final_-$func.txt
      # search n lines of the beginning of the function, the end of the
      # heading of the function and the beginning of the documentation
      n_func=$( grep -n "def $func" $fil | cut -d ":" -f 1 )
      rel_n_func_end=$( tail -n +$n_func $fil | grep -n ")" | head -n 1 | \
                        cut -d ':' -f 1)
      doc_num_start=$(( n_func + rel_n_func_end ))
 
      insert_doc $doc_num_start $fil $func
      # delete documentation file
      rm final_-$func.txt || \
        fail "not final documentation found final_-$func.txt"
    done
 
    # Classes
    mapfile -t classes < <(grep "^class " "$fil" | awk '{print $2}' | \
                             cut -d "(" -f 1)
    if [ ${#classes} -ne 0 ]; then verbose "Classes"; fi
    for class in ${classes[@]}
    do
      # Documentation of the class definition
      class=${class%:}
      echo $class
      pkgdeveloper python_doc_fixer -m $module -c $class || \
        fail "creating new documentation of $class"
      wait_until_next_file_exist final_$class-.txt
  
      # search n lines of the beginning of the function, the end of the
      # heading of the function and the beginning of the documentation
      n_class=$( grep -n "^class $class" $fil | cut -d ":" -f 1 )

      rel_n_class_end=$( tail -n +$n_class $fil | grep -n ":" | head -n 1 | \
                         cut -d ':' -f 1)
      doc_num_start=$(( n_class + rel_n_class_end ))
      insert_doc $doc_num_start $fil "" $class
      # delete documentation file
      rm final_$class-.txt || \
        fail "not final documentation found final_$class-.txt"
      # TODO: add description of the attributes.

      # ==== description of modules
      # subfile with the class only extract_subclass
      n_end_class=$(tail -n +$n_class $fil | grep -nEv "^ |^$"  | \
              grep -v "^$" | tail -n +2 | head -n 1 | cut -d ":" -f 1 )

      if [ ${#n_end_class} -eq 0 ]
      then
        tail -n +$(( n_class + 1 )) $fil > ${class}_complete_001.out
      else
        pkgdeveloper find_blocks -f $fil -s $(( n_class )) \
                            -e $(( n_class + n_end_class - 1 )) \
                            -i -o ${class}_complete || fail "finding the class"
      fi
      wait_until_next_file_exist ${class}_complete_001.out

      mapfile -t methods < <(pkgdeveloper methods_in_class $module $class | \
                             head -n -1)

      for method in ${methods[@]}
      do
        echo ${class}.$method
        pkgdeveloper python_doc_fixer -m $module -c $class -f $method || \
          fail "creating new documentation of $class.$method"
        rel_n_meth=$( grep -n "def $method(" ${class}_complete_001.out | \
                      cut -d ":" -f 1)
        if [ ${#rel_n_meth} -eq 0 ]
        then
          rel_n_meth=$( grep -En "def $method+[[:space:]]" \
                        ${class}_complete_001.out | cut -d ":" -f 1)
        fi
        
        # If the function is not defined at all in this file (if the method is
        # inheritated)
        if [ ${#rel_n_meth} -eq 0 ]
        then
          rm final_$class-$method.txt
          continue
        fi
        rel_n_meth_end=$( tail -n +$rel_n_meth ${class}_complete_001.out \
                          | grep -n ")" | head -n 1 | \
                          cut -d ':' -f 1)
        doc_num_start=$(( n_class + rel_n_meth + rel_n_meth_end ))
        insert_doc $doc_num_start $fil $method $class
        insert_doc $(( rel_n_meth + rel_n_meth_end )) \
                   ${class}_complete_001.out \
                   $method $class
        # delete documentation file
        rm final_$class-$method.txt || \
          fail "not final documentation found final_$class-$method.txt"
      done
      rm ${class}_complete_001.out || fail could not remove complete file
    done
  fi
done

finish
