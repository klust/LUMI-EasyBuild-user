# PRoot

-   [PRoot home page](https://proot-me.github.io/)
    
-   [PRoot on GitHub](https://github.com/proot-me/proot)
    
    -   [PRoot GitHub releases](https://github.com/proot-me/proot/releases)


## EasyBuild

There is no support for PRoot in EasyBuild or Spack.


### 5.4.0 for the SYSTEM toolchain

-   The EasyConfig is a LUST development. 

-   We went for build that is fully static except for libc taken from the system to
    be as independent from anything else as possible.
    
-   Needed to fix the Makefile as the warnings about it not being a git repository
    caused EasyBuild to stop the build.
