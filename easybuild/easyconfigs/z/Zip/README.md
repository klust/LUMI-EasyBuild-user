# UnZip instructions

The UnZip module contains the Info-ZIP tools to inspect or uncompress zip files.

  * [Info-ZIP Zip home page](http://www.info-zip.org/UnZip.html)
  
  * [Info-ZIP on SourceForge](https://sourceforge.net/projects/infozip/files/)
  

## EasyBuild

  * [Support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/u/UnZip)
  
  * There is no support for UnZip in the CSCS repository

  * [Spack package](https://github.com/spack/spack/blob/develop/var/spack/repos/builtin/packages/unzip/package.py)
  

### Version 6.0 for cpeGNU 22.06 and later

  * The EasyConfig is a straightforward adaptation of the EasyBuilders one for the
    `GCCcore` toolchains, including the security patches in recent EasyBuild versions.
    
  * It may need work for Clang-based compilers.
