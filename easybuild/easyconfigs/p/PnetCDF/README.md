# PnetCDF technical information

-   [PnetCDF website](https://parallel-netcdf.github.io/)

-   [PnetCDF downloads](https://parallel-netcdf.github.io/wiki/Download.html)

-   [PnetCDF on GitHub](https://github.com/Parallel-NetCDF/PnetCDF)


## EasyBuild

-   [PnetCDF in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/p/PnetCDF)

-   [parallel-netcdf Spack package](https://packages.spack.io/package.html?name=parallel-netcdf)


### 1.15.1

-   The EasyConfig is derived from those for version 1.14.1 in the EasyBuilders repository.

-   It is not clear though why that EasyConfig uses separate steps for static and shared libraries,
    as it is an autotools package and both were actually already generated in the first phase.
