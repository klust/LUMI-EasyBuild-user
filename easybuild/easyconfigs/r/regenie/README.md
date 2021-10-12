# regenie instructions

  * [regenie home page](https://rgcgithub.github.io/regenie/)

  * [regenie on GitHub](https://github.com/rgcgithub/regenie)

      * [GitHub releases](https://github.com/rgcgithub/regenie/releases)


## EasyBuild and other build tools

  * No support for regenie in the EasyBuilders repository

  * No support for regenie in the CSCS repository

  * No support for regenie in Spack

  * [BioConda recipe for regenie](https://github.com/bioconda/bioconda-recipes/tree/master/recipes/regenie)
    and the [patch that creates CMakeLists.txt for BioConda](https://github.com/bioconda/bioconda-recipes/blob/master/recipes/regenie/patches/0003-use-conda-cmakelists.patch)


### 2.2.4 for cpe 21.08

  * Extracting the list of dependencies from the BioConda recipe as the web site
    seems totally inadequate. The problem is that the BioConda recipe isn't exactly
    up-to-date either.

      * [BGEN library](https://enkre.net/cgi-bin/code/bgen) - Also mentioned in the
        regenie docs.

          * According to the BioConda recipe: bgenix, but that turns out to be the BGEN
            library.

          * [The bgen easyconfigs](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/b/bgen)
            are for a different implementation. It is not clear if that one can be
            used also.

      * BOOST IOstream with zlib.

      * According to the BioConda recipe: also zstd, sqlite3 and eigen.

        It turns out sqlite3 and zstd come in via the BGEN reference implementation.

      * Optimized BLAS but the Makefile is really made for MKL or OpenBLAS so have
        to check how to get Cray BLAS in there.





