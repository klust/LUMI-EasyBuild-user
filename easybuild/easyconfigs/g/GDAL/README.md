# GDAL

## EasyBuild


### GDAL 3.8.2 for cpeGNU 23.09 and later

-   Problems with the GDAL CMake build process

    -   The configuration fails with Cray HDF5.
    
    -   It appears that `-fPIC` is not always automatically added when
        building shared libraries, leading to link error.

        Even introducing the `-fPIC` flag via `toolchainopts` doesn't seem
        to work.
