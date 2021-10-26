# DocBook-XSL, XSL files for the DocBook project

  * [(Former) home on SourceForge](https://sourceforge.net/projects/docbook/)

      * [SourceForge downloads](https://sourceforge.net/projects/docbook/files/docbook-xsl/)

  * [New development home on GitHub](https://github.com/docbook/xslt10-stylesheets)

As the release strategy on GitHub is unclear the EasyConfig files stick to the SourceForge
releases for now.


## EasyConfigs

  * No support for DocTools-XSL in the EasyBuilders repository as of August 2021

  * No support for DocTools-XSL in the CSCS repository as of August 2021


### Strategy for the CSCS version which has /etc/xml present

  * All files from the tar-file are installed in the install directory.

  * The ``install.sh`` script does not make sense in our case.

  * The ``rewritePrefix`` fields in ``catalog.xml`` are rewritten to point
    to the correct directory. The ``catalog.xml`` file is also renamed to
    ``docbook.xml``.

  * A new main catalog is generated based on the system ``/etc/xml/catalog``
    file with the paths corrected for the system entries (not yet robust!)
    and a new entry added for ``docbook.xml``.

  * The module also sets the environment variable ``XML_CATALOG_FILES`` to
    point to the new ``catalog`` file in the install directory.

    **This implies that the main system catalog is no longer used. Any update
    to it will not be reflected in this module unless the module is reinstalled!**


### Strategy on LUMI as long as there is no /etc/xml to integrate with

  * All files from the tar-file are installed in the install directory.

  * The ``install.sh`` script does not make sense in our case.

  * The ``rewritePrefix`` fields in ``catalog.xml`` are rewritten to point
    to the correct directory.
