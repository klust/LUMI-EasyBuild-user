# Zoltan instructions

  * [Zoltan web site]()

  * [Zoltan on GitHub](https://github.com/sandialabs/Zoltan)

Zoltan is part of Trilinos but can also be installed independently which is
what these EasyConfigs do.


## EasyBuild

  * There is no support for Zoltan in the EasyBuilders repository

  * There is no support for Zoltan in the CSCS repository

  * [Zoltan support in Spack](https://github.com/spack/spack/tree/develop/var/spack/repos/builtin/packages/zoltan)


### Version 3.90 for CPE 21.08

  * Building with CMake doesn't work as there are files from Trilinos
    missing.

  * Building with configure gives problems also as the packages wants
    configure to be run in a separate directory. We solve this by adding
    ``mkdir build && cd build && ln -s ../configure && `` to ``preconfigopts``
    and ``cd build && `` to ``prebuildopts`` and ``preinstallopts``.

  * The Fortran 90 interfaces produce the infamous type mismatch error message
    when using gfortran 10, so we enabled the toolchain option ``gfortran90-compat``
    when using cpeGNU.

  * The Fortran 90 interfaces fail to build with the Cray compiler. This is somewhat
    strange as the Cray build script suggests they should work, but it may be that
    that build script has only been tested with older versions of Zoltan. Cray does
    build Trilinos without the support for ParMETIS and Scotch.

    The error message is very strange: Make complains that it has no rules to make
    one of the module files, but when using cpeGNU or cpeAMD it does find the rule.


