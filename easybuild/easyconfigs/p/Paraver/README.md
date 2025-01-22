# Paraver instructions

Paraver is a performance analysis tool.

It is here currently as a test vehicle of wxWidgets also.

-   [ Paraver web site at BSC](https://tools.bsc.es/paraver)
    
    
## EasyBuild

-   [Paraver support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/p/Paraver).
    It compiles Paraver from sources and uses a 
    [custom EasyBlock](https://github.com/easybuilders/easybuild-easyblocks/blob/develop/easybuild/easyblocks/p/paraver.py)
    for that.
    
-   [Paraver support in the CSCS repository](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/p/Paraver).
    Here Paraver is installed from downloaded binaries.
    
-   [PAraver (paraver) in Spack](https://spack.readthedocs.io/en/latest/package_list.html#paraver)
    

### Version 4.10.4

-    The EasyConfig is a direct port of the EasyBuilders one for the foss/2021a 
     toolchain due to the lack of a more recent one. The version was bumped to 4.10.4
     as 3.9.2 does not compile.

The program does not yet completely work as it should. Part of it is likely due to 
the problem with adwaita in GTK3, but the segmentation violation when quitting the
program may have a different cause.
 