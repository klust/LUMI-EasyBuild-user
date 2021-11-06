# Serf instructions

  * [Serf home page](https://serf.apache.org/)


## Problems

Serf currently fails to compile due to several bugs combined

  * The .pc file of APR-util is wrong. It adds -lexpat to the libraries
    as it should, but it doesn't add the path for the library though that
    is correct in the .pc file of expat.

    However, even after fixing the pkgconfig file, Serf still fails to pick
    up all the linker flags.

  * Moreover, LINKFLAGS is not correctly processed by the SConstruct script
    of Serf. Otherwise this could be used to add the necessary -L option to
    fix the problems.

Hence it looks like Serf can only be build when APR, APR-util and expat are
bundled together as then the -L link flags for APR and APR-util would
automatically also include the expat library.


## EasyBuild

  * [Serf support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/s/Serf)

  * [Serf support in the CSCS repository](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/s/Serf)


### 1.3.9 in the SYSTEM toolchain

  * This EasyConfig is really meant to experiment with Serf in preparation
    of inclusion in the syslibs bundle.

    In fact, it turns out that it is impossible to build Serf with the SYSTEM
    toolchain unless expat, APR andAPT-util come in a Bundle as there seems to
    be no robust way to tell the linker where to find the expat libraries.

  * Used a patch to make the SConstruct script Python 3-compatible from the
    EasyBuilders repository.

  * There seems to be no way to build static libraries only, but as we want
    to use this library purely as a build dependency, we simply remove the
    shared libraries at the end.

    We keep it that way as long as the only package that uses Serf is
    Subversion, which we want to make as independent as possible from
    Cray toolchains and only dependent on some libraries in the OS, to
    ensure minimal interference with workflows.
