# UppASD instructions

-   [UppASD web site](http://physics.uu.se/uppasd)

-   [UppASD development on GitHub](https://github.com/UppASD/UppASD/)

    -   [GitHub releases](https://github.com/UppASD/UppASD/releases)


## EasyBuild

-   There is no support for UppASD in the easybuilders repository

-   There is no support for UppASD in the CSCS repository

-   There is no support for UppASD in Spack


### UppASD-6.0.2 with cpeGNU-22.12 and cpeAOCC-22.12

-   Derived from one in use at Dardel.

-   Does not install the Python packages that are needed to run the included
    Python code in the ASD_BUI and ASD_Tools directories.
    
-   The cpeAOCC version is a near trivial adaptation.

-   There is a `crayft-ftn` target to compile with Cray Fortran but there is
    a problem with the link line so that still fails. It looks like there are
    some source code only-options included that the Cray Fortran compiler does
    not appreciate when linking code.
    
    The problem is that one way or another the `-cpp` option also appears on the 
    link line which is not appreciated by Cray Fortran. It then expects also to
    find source files and complains that no valid file names are specified on
    the command line.
    
    To patch this, changes need to be made to `source/make/makefile.template`
    which we do via a patch file.
    
    Note that the compilation does produce some scary warnings, so it is not clear
    if the Cray version will work correctly.
