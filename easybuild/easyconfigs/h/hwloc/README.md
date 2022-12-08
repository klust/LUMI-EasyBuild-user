# hwloc instructions

The LUMI hwloc is not always the most recent one, so from time to time we like
to experiment with newer version to see if that could solve some problems with,
e.g., likwid.

The hwloc tools are a part of the Open MPI project.

-   [hwloc web site](https://www.open-mpi.org/projects/hwloc/)



## EasyBuild

-   [hwloc support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/h/hwloc)

-   [hwloc support in the CSCS repository](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/h/hwloc)


## Version 2.8.0

-   The EasyConfig is derived from the EasyBuilders one for GCCcore 12.2.0, 
    but with some elements of the CSCS one mixed in, e.g., the use of the SYSTEM 
    toolchain
    
-   This is currently a restricted version with minimal dependencies and not a full
    featured one. The support for the AMD GPUs is missing in this version (as it 
    complained it could not find some stuff, at least when tried on the login nodes).
    
-   Added the options `--disable-rocm --disable-rsmi` to disable ROCm and the ROCm 
    SMI library as that caused `lstopo` to fail when tested in the sanity check step.
