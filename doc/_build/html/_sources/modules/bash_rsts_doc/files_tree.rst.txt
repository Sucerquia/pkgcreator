
==========
files_tree
==========

.. container:: bash-script-title

   :ref:`[script] <files_tree>` **pkgdeveloper/pkg_structure/files_tree.sh**

.. container:: bash-script-doc

   .. line-block::
      
      Function that creates a mermaid map of a directory structure.
      
        -d  <path_directory> path to the directory to be mapped. If not provided
            $(package_name path), where package_name provided with -n is used.
        -i  <ignoring_patterns=''> comma separated list of patterns to be ignored.
        -n  <package_name> name of the package to be mapped. Used to determine
            the path if -d is not provided.
      
      The output is the string that you have to locate in an rst file in order to
      render your map. In principle, the output can be used in markdown files
      changing the corresponding keywords.
      
      Example of output in the case that the directory to be mapped contains the
      subdirectories cli and pkg_structure and the pattern is 'pkgdeveloper':
      
      .. mermaid::
         :align: center
      
         graph TD
         node1[pkgdeveloper]
         click node1 modules/pkgdeveloper.html _self
           node1 --> node2[cli]
           click node2 modules/pkgdeveloper.cli.html _self
           node1 --> node3[pkg_structure]
           click node3 modules/pkgdeveloper.pkg_structure.html _self
      
