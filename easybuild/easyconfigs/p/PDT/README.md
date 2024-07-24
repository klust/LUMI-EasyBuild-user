# PDT - Program Database Toolkit

PDT is a dependency for TAU.
Note that it is basically abandonware that only gets the minimal maintenance
required to keep it running: Version 3.25 was released in November 2017, 
version 3.25.1 in May 2019, and version 3.25.2 in January 2024 to finally
properly support the new LLVM-based Intel compilers that at that time 
had been around for a while.

PDT or Program Database Toolkit is a tool infrastructure that provides
access to the high-level interface of source code for analysis tools and
applications.  Currently, the toolkit consists of the C/C++ and Fortran 77/90/95
IL (Intermediate Language) Analyzers, and DUCTAPE (C++ program Database
Utilities and Conversion Tools APplication Environment) library and applica-
tions.  The EDG C++ (or Mutek Fortran 90) Front End first parses a source
file, and produces an intermediate language file.  The appropriate IL
Analyzer processes this IL file, and creates a "program database" (PDB) file
consisting of the high-level interface of the original source.  Use of the
DUCTAPE library then makes the contents of the PDB file accessible to
applications. This release also includes the Flint F95 parser from Cleanscape
Inc.

See http://www.cs.uoregon.edu/research/pdt for more information
on PDT.

-   [PDT home page](https://www.cs.uoregon.edu/research/pdt)

    -   [PDT documentation](https://www.cs.uoregon.edu/research/pdt/docs.php).
    
        There is no proper installation manual available online though. 

    -   [PDT downloads](https://www.cs.uoregon.edu/research/pdt/downloads.php): 
        Registration is required so one needs to manually download the sources.


## Installation instructions

Though officially registration is required to download PDT,
looking at the Spack package there is a trick: The URL is of the type
`https://www.cs.uoregon.edu/research/paracomp/pdtoolkit/Download/pdtoolkit-3.25.2.tar.gz`.

The build process is completely unconventional (to be kind as it is really a 
disaster):

-   The configure script has very untraditional behaviour. The 
    [EasyBuild EasyBlock for PDT](https://github.com/easybuilders/easybuild-easyblocks/blob/develop/easybuild/easyblocks/p/pdt.py)
    claims that the environment variables that set compiler options, are simply neglected.
    This indicates that it may give problems to on one hand have the configure script add
    proper compiler-specific optimisations, but on the other hand also use the compiler wrappers
    to compile the code. Spack does it by editing `ductape/Makefile` for some compilers.
    
    The installation directory must be created before calling the configure script,
    passing the installation directory with the `-prefix` option.
    
    The configure script already builds and installs the software that goes in the
    `contrib` subdirectory of the installation directory. It looks like those are
    actually build in-place rather than in the temporary directory in which the PDT
    package is unpacked. The whole process leaves behind a mess of files that are no
    longer needed after the build. The executables are static executables so in
    principle they could be just moved around rather than linked to from the bin
    directory of PDT, but it is not clear if they need other files at runtime that
    are found based on the location of the executable.
    
-   The build process itself is also strange. It is triggered by `make install` so 
    there is no separate build and install step. It does build `libpdb.a` that is
    installed in the `x86_64/lib` subdirectory, and some other executables
    (pdbconv, pdbtree, pdbmerge, pdbcomment, pdbstmt, xmlgen) that
    go in the `x86_64/bin` subdirectory. These are build in the build directory,
    so not in-place, and simply copied to their final locationat the end of the 
    `make install` process.
   
    
-   The name of the executables in `roseparse` suggest that PDT is based on version 
    4.4 of the Edison Design Group C/C++ front-end. This is a very old frontend that
    will not support newer C++ options.In fact, feature tables on the website of EDG
    show that even C++11 support was not complete in version 4.4. The question is 
    what effect this has on the operation of the software.
    
    When we developed the first easyconfigs for this package, in July 2024, the
    version that EDG was distributing, was 6.6, released in December 2023.


## EasyBuild

-   [There is support for PDT in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/p/PDT)
    which relies on a 
    [software-specific EasyBlock](https://github.com/easybuilders/easybuild-easyblocks/blob/develop/easybuild/easyblocks/p/pdt.py)
    to set the architecture option and specific compiler.

-   [There is support for PDT in the CSCS repository](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/p/PDT),
    installing the lite version.

    CSCS compiles PDT in the SYSTEM toolchain likely to work around the problem with compiler wrappers and
    proper optimisation options described above, yet to end up with a library that likely works with all
    other compilers on the system. Because they are simply using GCC without wrappers, they can use the standard
    EasyBlock for PDT.

-   [The spack package `pdt` also offers PDT](https://github.com/spack/spack/blob/develop/var/spack/repos/builtin/packages/pdt/package.py).


### Version 3.25.2 for LUMI/23.09

-   As we need a clean installation directory already during the configure step,
    there is no other option than to adapt the custom EasyBlock for LUMI.
    
    This of course could create a maintenance nightmare as we may need to port
    the changes to future versions of EasyBuild.

-   The problem with this setup is that a number of contributed packages are simply
    compiled with `gcc` and `g++` so in practice with the system compiler except for
    `cpeGNU`. This is certainly the case for the rose component. This may also explain
    why CSCS simply uses the SYSTEM toolchain to install a lite verion of PDT.
    
    Even the version detection of that compiler is not always correct...

-   We take away the part of code that causes `-h conform,instantiate=used`
    to be added to the compiler flags as these options are not recognised by the
    compiler. Could this be options from the days that Cray had its own C/C++
    compiler rather than one based on Clang/LLVM?


QUESTION: Do we really need to use the Cray compiler etc., or can we do with the system 
compiler? It looks like ParaTools used the system compiler to install the package
looking at the output of `ldd`.
