# likwid instructions

-   [likwid GitHub repository](https://github.com/RRZE-HPC/likwid)

    -   [GitHub releases](https://github.com/RRZE-HPC/likwid/releases)

    -   [Some documentation in the GitHub Wiki](https://github.com/RRZE-HPC/likwid/wiki)


## EasyBuild

-   [likwid support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/l/likwid).
    This EasyConfig does most work by redefining variables from `config.mk` on the `make` command line.

-   [likwid support in the CSCS repository](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/l/likwid).
    This EasyConfig works by editing `config.mk`.


### Version 5.2.2 wqith SYSTEM

-   This version does not yet fully support zen3, so problems are to be
    expected.

-   Started from the CSCS EasyConfig which edits the `config.mk` file rather
    then redefining variables on the `make` command line as the EasyBuilders
    one does.
   
-   Trying to use the system hwloc to minimize interference.
   
-   Using the system LUA interpreter turned out to be impossible as the header
    files are missing on LUMI.
    
-   TODO
    
    -   likwid-bench crashes with floating point exceptions.

