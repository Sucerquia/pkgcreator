.. pkgdeveloper documentation master file, created by
   sphinx-quickstart on Tue Oct 14 17:23:45 2025.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to pkgdeveloper's documentation!
========================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:
 
   modules/pkgdeveloper
   tutorials/tutorials



Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

.. mermaid::
   :align: center

   graph TD
   node1["pkgdeveloper"]
   click node1 "modules/pkgdeveloper.html" _self
     node1 --> node2["bash_scripts"]
     click node2 "modules/pkgdeveloper.bash_scripts.html" _self
     node1 --> node3["pkg_structure"]
     click node3 "modules/pkgdeveloper.pkg_structure.html" _self
     node1 --> node4["templates"]
     click node4 "modules/pkgdeveloper.templates.html" _self
