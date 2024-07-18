# GROMACS-SWAXS instructions

-   [GROMACS-SWAXS on the research group's pages](https://biophys.uni-saarland.de/software/gromacs-swaxs/)

-   [GROMACS-SWAXS docs](https://cbjh.gitlab.io/gromacs-swaxs-docs/index.html)

    -   When trying this first, the system requirements in the installation manual 
        were outdated compared to remarks found in the GitLab repository on compiler
        versions used.
        
-   [GROMACS-SWAXS GitLab](https://gitlab.com/cbjh/gromacs-swaxs)

    -   [GitLab releases](https://gitlab.com/cbjh/gromacs-swaxs/-/releases)
    

# EasyBuild

-   There is no support for GROMACS-SWAXS in the EasyBuilders or CSCS repositories.

-   [gromacs-swaxs in Spack](https://packages.spack.io/package.html?name=gromacs-swaxs)

    The spack package confirms that this variant is not compatible with the PLUMED modifications
    nor with OpenCL or SYCL versions of GROMACS. Otherwise it simply uses the same 
    build process as for GROMACS.


## Version 2021.7-0.5.1 for cpeGNU/23.09

-   This is a trivial port of our EasyConfig for GROMACS 21.7.

-   Generation of double precision binaries was turned off as that option was not
    mentioned in the GROMACS-SWAXS instructions. It is not clear if the additions
    also support double precision.
    
    
## Version 20225.5-0.1 for cpeGNU/23.05

-   Port of our EasyConfig for GROMACS 22.6 with the same modifications as used for
    the 2021.7-0.5.1 version of GROMACS-SWAXS.
