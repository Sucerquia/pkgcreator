
===========
doc_modules
===========

.. container:: bash-script-title

   :ref:`[script] <doc_modules>` **pkgdeveloper/pkg_structure/doc_modules.sh**

.. container:: bash-script-doc

   .. line-block::
      
      Code that explores the files in the package and automatically create the
      documentation of all classes and functions that finds in it.
      
         -d   <dir1,dir2...> directories to be ignored. Default: 'tests,cli'
         -f   <fil1,fil2...> files to be ignored. Default: '__init__'
         -p   <relative_path=../../src/name/, where 'name' is defined with '-n'>
              relative path directory to be checked. Relative in respect to the
              directory that stores the modules documentation (see the flag -m).
         -m   <absolute_path=$('name' path)/../../doc/modules, where name is defined
              with '-n'> absolute path to the directory that stores the modules
              documentation.
         -n   <name> pakage name.
      
         -h   prints this message.
      
