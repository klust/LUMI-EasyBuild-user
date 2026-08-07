# QUIP technical information

The QUIP library is used by the QUIP plugin of LAMMPS.

-   [QUIP on GitHub](https://github.com/libatoms/QUIP)

    -   [GitHub releases](https://github.com/libAtoms/QUIP/releases)

-   [QUIP manual](https://libatoms.github.io/QUIP/)

QUIP is built using Meson which can make it a nightmare...
The instructions on how to build are also very thin.


## EasyBuild

Neither EasyBuild nor Spack offer support for QUIP which already says a lot...


### Version 0.10.3

Tried to build an EasyConfig but it turns out the Meson installation script is complete
junk in combination with the Cray programming environment. It really wants to find OpenBLAS
which makes no sense in our environment and also fails to locate ScaLAPACK and MPI for which
it really wants files for pkg-config.
