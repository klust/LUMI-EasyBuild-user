# APR-util instructions

  * [APR home page](https://apr.apache.org/)


## Notes

  * The pkgconfig file apr-util-1.pc lacks the path to the expat library
    which in case of a build with EasyBuild is different from the one to the
    APR-util libraries. The same holds for the bin/apu-1-config script.
    This is fixed in installopts (or could be fixed in postinstallcmds)


## EasyBuild

APR and APR-util are mostly building tools for other Apache packages. The only use so far
in our stack is to build Serf which in turn is needed for Subversion.

  * [APR-util support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/a/APR-util)

  * [APR-util support in the CSCS repository](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/a/APR-util)


### Version 1.6.1 for the SYSTEM toolchain

  * The only purpose of these EasyConfigs are to prepare for integration in
    syslibs, a module of build dependencies for some tools that we want to
    compile against the system libraries (and with the SYSTEM toolchain).

  * We started from a CSCS EasyConfig.
