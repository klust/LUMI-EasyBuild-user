# bgenix - Generic BGEN implemenation also used in Anaconda/BioConda

  * [BGEN web pages](https://enkre.net/cgi-bin/code/bgen)


The package should provide

  * A library and header files

  * Some tools to work with BGEN files: ``bgenix``, ``cat-bgen`` and ``edit-bgen``.

  * An R package called ``bgen`` to work with BGEN files.


## Installation instructions

  * It may be easier to reverse engineer the build instructions from the
    [anaconda package for bgenix](https://anaconda.org/conda-forge/bgenix)
    with [the recipe in conda-forge](https://github.com/conda-forge/bgenix-feedstock).
    The ``build.sh`` script in
    [the recipe subdirectory](https://github.com/conda-forge/bgenix-feedstock/tree/master/recipe)
    is certainly more helpful than the documentation of BGEN and waf.

    However, it turns out that the build recipe for some reason only builds the
    apps and not the library... The library is compiled but not installed. The
    include files are also missing.

  * Dependencies

      * The library only seems to need zlib

      * However, the applications, examples and R package also need sqlite, boost
        and zstd, all of which are part of the standard LUMI software stack.

  * Download: The download process is atypical as the file name does not contain
    the actual version but a commit label or so corresponding to the version. This
    makes version updates cumbersome.

  * Build process: The build process is highly  non-standard and uses the
    [waf build tool](https://waf.io/) which comes with the sources.

      * waf does have a configure - build - install build process but it is not trivial
        to put it in that way in EasyBuild and would essentially require the development
        of a custom EasyBlock to do it in a clean way.

      * waf will create a subdirectory ``build`` in the main project directory.

      * waf does honour the CC and CXX environment variables and the ``--prefix``
        argument to point to the install directory.

      * Problems:

          * Hard-coded options in the waf build recipes that are very GNU-specific

          * How to tell it to use our own Boost, zstd and sqlite3 libraries?

