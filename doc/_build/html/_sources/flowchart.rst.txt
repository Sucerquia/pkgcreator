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
