# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'pkgdeveloper'
copyright = '2025, Daniel Sucerquia'
author = 'Daniel Sucerquia'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
  'sphinx_rtd_theme',
  'sphinxcontrib.mermaid',
  'sphinx.ext.githubpages',
  'sphinx.ext.mathjax',
  'sphinx.ext.intersphinx',
  'sphinx.ext.napoleon',
  'sphinx.ext.viewcode',
  'sphinx.ext.autodoc',
  'sphinx.ext.autosummary',
  ]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'alabaster'
html_static_path = ['_static']
html_theme = 'sphinx_rtd_theme'

# Add custom CSS file
html_css_files = [
    'custom.css',  # Ensure the file path is correct
]

from docutils import nodes
from docutils.parsers.rst import roles

def bashscript_role(name, rawtext, text, lineno, inliner, options={}, content=[]):
    """
    Custom role :bashscript:`display <target-label>` to render a boxed ref link.
    """
    env = inliner.document.settings.env

    parts = text.split('.')
    target = 'modules/' + '.'.join(parts[:-1])
    ref = '#' + text.replace('.', '-')
    ref = ref.replace('_', '-')
    display_text = text.replace('.', '/') + '.sh'


    # Generate relative URI correctly using positional args
    refuri = env.app.builder.get_relative_uri(env.docname, target) + ref

    # Create reference node
    refnode = nodes.reference(rawtext, display_text, refuri=refuri)
    refnode['classes'].append('bashscript')

    return [refnode], []

# Register the role
roles.register_local_role('bashscript', bashscript_role)
