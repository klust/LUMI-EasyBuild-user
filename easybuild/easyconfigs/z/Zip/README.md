# Zip instructions

The Zip module contains the Info-ZIP zip compression routines but not
the `unzip` command.

  * [Info-ZIP Zip home page](http://www.info-zip.org/Zip.html)
  
  * [Info-ZIP on SourceForge](https://sourceforge.net/projects/infozip/files/)
  

## EasyBuild

  * [Support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/z/Zip)
  
  * There is no support for Zip in the CSCS repository

  * [Spack package](https://github.com/spack/spack/blob/develop/var/spack/repos/builtin/packages/zip/package.py)
  

### Version 3.0 for cpeGNU 22.06 and later

  * The EasyConfig is a straightforward adaptation of the EasyBuilders one for the
    `GCCcore` toolchains.
    
  * It may need work for Clang-based compilers.
