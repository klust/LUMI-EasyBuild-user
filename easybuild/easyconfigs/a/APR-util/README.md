# APR-util instructions

## Notes

  * The pkgconfig file apr-util-1.pc lacks the path to the expat library
    which in case of a build with EasyBuild is different from the one to the
    APR-util libraries. The same holds for the bin/apu-1-config script.
    This is fixed in installopts (or could be fixed in postinstallcmds)

