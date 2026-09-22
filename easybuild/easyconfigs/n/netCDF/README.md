# netCDF technical information

The netCDF libraries are distributed in several packages:

-   netCDF-C is the core library and contains the C API. 

    -   [Project on GitHub](https://github.com/Unidata/netcdf-c))

    -   [GitHub releases](https://github.com/Unidata/netcdf-c/releases)

    -   [netCDF User's Guide](https://docs.unidata.ucar.edu/nug/current/index.html)

    -   [Guide to building netCDF](https://docs.unidata.ucar.edu/nug/current/getting_and_building_netcdf.html)

-   netCDF-Fortran: Fortran wrappers 

    -   [Project on GitHub](https://github.com/Unidata/netcdf-fortran)

    -   [GitHub releases](https://github.com/Unidata/netcdf-fortran/releases)

-   netCDF-4 C++: C++ wrappers, version 4 (the current C++ API).
    This was developed by an external party and contributed to netCDF,
    but the code is not properly maintained so issues may occur.

    -   [Project on gitHub](https://github.com/Unidata/netcdf-cxx4)

    -   [GitHub releases](https://github.com/Unidata/netcdf-cxx4/releases)


Moreover, several back-ends can be added to the netCDF package

-   [HDF5](https://www.hdfgroup.org/solutions/hdf5/) is the back-end for 
    the newest netCDF file format. Parallel access
    will be enabled if the HDF5 library supports this.

-   [PnetCDF](https://parallel-netcdf.github.io/) is a back-end for parallel 
    access when using some of the older netCDF file formats.


## EasyBuild

-   EasyBuilders packages:

    -   [netCDF](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/n/netCDF): The C interface.

    -   [netCDF-Fortran](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/n/netCDF-Fortran): 
        The Fortran interfaces, and needs the netCDF module.

    -   [netCDF-C++4](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/n/netCDF-C%2B%2B4):
        The C++-interface version 4.

-   Spack packages

    -   [netcdf-c](https://packages.spack.io/package.html?name=netcdf-c)

    -   [netcdf-fortran](https://packages.spack.io/package.html?name=netcdf-fortran)

    -   [netcdf-cxx4](https://packages.spack.io/package.html?name=netcdf-cxx4)


### General remarks

Contrary to the regular EasyBuild recipes, we try to keep the C interface and matching
Fortran and C++ interfaces in a single module. This is also a bit similar to the HPE Cray
setup where the module included both C and Fortran interfaces.


### Version 4.10.1 with Fortran interface 4.6.4 and CXX4 interface 4.3.1

-   Checked that Szip support is OK with libaec. The configure step was happy with it.
