# GNU gv instructions

  * [gv home page](https://www.gnu.org/software/gv/)

Note that gv is dead code, it has not been updated since 2013. So future problems
are to be expected.

It needs Ghostscript, and needs libXaw3d which is not part of the standard
EasyBuild X11 bundle.


## EasyBuild

  * There is no support for gv in the EasyBuilders repository

  * There is no support for gv in the CSCS repository


### Version 3.7.4 from cpe 21.08 on

  * Build the EasyConfig file from scratch.

  * Chose to extend the X11 bundle with libXaw3d

