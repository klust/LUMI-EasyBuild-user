# git



## Build instructions

To install git against the sytem toolchain, several libraries need to be installed
in development versions:
  * Header files libintl.h, iconv.h (glibc-devel on SUSE)
  * zlib with zlib.h (zlib-devel on SUSE)
  * libexpat with expat.h (libexpat-devel on SUSE)
  * libcurl with curl.h (libcurl-devel on SUSE)
  * OpenSSL development libraries?? Needed according to EasyBuilders but not found
    in the configure log.

To generate man pages or info pages, [AsciiDoc](https://asciidoc.org/)
is needed. Futhermore, to generate man pages, [xmlto](https://pagure.io/xmlto) is
needed and to generate info pages, TEXTODO is needed.


## EasyBuild

  * [Support for git in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/g/git)

  * [Support for git in the CSCS repository](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/g/git)

### git 2.33 for cpe 21.06

  * Started from the EasyBuilders recipe that doesn't build the documentation,
    but checked options from configure, switched to OS dependencies and the
    ?SysTE? toolchain.
