# APR instructions - Apache Portable Runtime

  * [APR home page](https://apr.apache.org/)


## EasyBuild

APR is mostly a building tool for other Apache packages. The only use so far
in our stack is to build Serf which in turn is needed for Subversion.

  * [APR support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/a/APR)

  * [APR support in the CSCS repository](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/a/APR)


### Version 1.7.0 for the SYSTEM toolchain

  * The only purpose of these EasyConfigs are to prepare for integration in
    syslibs, a module of build dependencies for some tools that we want to
    compile against the system libraries (and with the SYSTEM toolchain).

  * We started from a CSCS EasyConfig.
