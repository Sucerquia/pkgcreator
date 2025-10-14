
================
python_doc_fixer
================

.. container:: bash-script-title

   :ref:`[script] <python_doc_fixer>` **pkgdeveloper/pkg_structure/python_doc_fixer.sh**

.. container:: bash-script-doc

   .. line-block::
      
      Code takes the documentation of a function and checks the documentation adding
      TODOs in the missing parts. The output is stored in a file called
      final_<class>-<method>_doc.txt
      
        -c  <class> Class to be checked.
        -f  <method> Function to be checked
        -m  <module> Module that contains the function
        -s  <n_spaces> number of leading spaces.
      
        -v  verbose.
        -h  prints this message.
      
