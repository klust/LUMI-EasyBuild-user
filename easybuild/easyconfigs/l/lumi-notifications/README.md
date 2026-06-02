# lumi-notifications technical information

This tool is a development from a LUST member. Despite its name, it is not restricted to
LUMI but will likely compile on any Linux (possibly with some `-D` flags depending on the
Linux variant) and is also known to compile on Mac OS. All it needs is a Linux-style libcurl.
It may work with MinGW on Windows also, though that hasn't been tested.

-   [GitHub for development](https://github.com/klust/LUMI-notifications)

## EasyBuild

### Version 0.2 using the system compiler

-   The EasyConfig is entirely a LUST development

-   It currently uses the `MakeCp` EasyBlock.

-   Sources: Two packages are downloaded from GitHub and unpacked: The sources of 
    LUMI-notifications and the inih package.

-   In `prebuildopts`, the two files needed from the inih package are copied to the
    `src` subdirectory of LUMI-notifications after which the Makefile can be used to
    compile the package with the system gcc.

-   At the end, the binaries and manual pages are copied to the installation directory.
