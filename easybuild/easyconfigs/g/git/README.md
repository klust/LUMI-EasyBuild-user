# git

From version 2.38.1 on, we bundle `git-lfs` in the `git` module.

-   [Git home page](https://git-scm.com)

-   [Git on GitHub](https://github.com/git/git)

    -   [GitHub releases via tags](https://github.com/git/git/tags)

-   [git-lfs GitHub](https://git-lfs.github.com/)
    
-   [git-lfs project on GitHub](https://git-lfs.github.com/)




## Build instructions

To install git against the sytem toolchain, several libraries need to be installed
in development versions:

-   Header files libintl.h, iconv.h (glibc-devel on SUSE)
-   zlib with zlib.h (zlib-devel on SUSE)
-   libexpat with expat.h (libexpat-devel on SUSE)
-   libcurl with curl.h (libcurl-devel on SUSE)
-   OpenSSL development libraries?? Needed according to EasyBuilders but not found
    in the configure log.

To generate man pages or info pages, [AsciiDoc](https://asciidoc.org/)
is needed. Furthermore, to generate man pages, [xmlto](https://pagure.io/xmlto) is
needed and to generate info pages, TeX is needed (which we really don't want on a
cluster).


## EasyBuild

-   [Support for git in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/g/git)

-   [Support for git in the CSCS repository](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/g/git)

-   [git-lfs support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/g/git-lfs). 
    The EasyBuilders install from sources, but then Go is needed.
    
-   [git-lfs support in the CSCS repository](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/g/git-lfs).
    CSCS installs generic downloaded binaries.


### git 2.33.1 for cpe 21.08

  * Started from the EasyBuilders recipe that doesn't build the documentation,
    but checked options from configure, switched to OS dependencies and the
    SYSTEM toolchain.

  * Further extended that one to one that can also generate the html documentation
    and man pages (but not the texinfo documentation at the moment) by building
    additional packages that provide the necessary tools. This is not yet finished
    on LUMI though as more packages are missing than on eiger.

### git 2.35.1 for LUMI/21.12

  * Straightforward port of the 2.33.1 EasyConfig file

### git 2.37.0 for LUMI/22.06

  * Straightforward port of the 2.35.1 EasyConfig file


### git 2.37.2 for LUMI/22.08

  * Straightforward port of the 2.37.0 EasyConfig file.


### git 2.38.1 for LUMI/22.??
  
  * Bundled with git-lfs, the latter installed from binairies.
  
  * git is installed using the same procedure as pre-2.38.1 versions. It is still 
    without the included documentation, but `git help` seems to work fine.
    
  * git-lfs is installed without running the included `install.sh` script as that 
    one adds information to `$HOME/.gitconfig` which does not make sense. Also,
    the install script doesn't even copy the man pages to the proper location.
    Our procedure implemented in the EasyConfig runs the important commands that the
    install script would execute and also copies the man pages to the proper location.
    It avoids running `git lfs install` though and leaves that to the user.
    
    It is a more complete procedure then the one implemented in the CSCS EasyConfig
    files.

  
 


  