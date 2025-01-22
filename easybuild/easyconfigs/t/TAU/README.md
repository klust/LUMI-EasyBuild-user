# TAU technical information

-   [TAU web page](https://www.cs.uoregon.edu/research/tau/home.php)

    -   [Download page](https://www.cs.uoregon.edu/research/tau/downloads.php): The latest 
        version requires filling in a form, so not clear if we can do an automatic download.

    -   [Documentation](https://www.cs.uoregon.edu/research/tau/docs.php)
    
        The documentation does include an installation guide, but it is beter to also
        check the `INSTALL` file included with the 
    
-   [Public GitHub mirror of TAU development](https://github.com/UO-OACISS/tau2).
    The mirror does not maintain releases.

-   On LUMI, there is commercial support via [ParaTools, Inc.](https://www.paratools.com/)


## Installation

The problem with TAU is that to cover all use cases, one needs multiple installations.
In particular, one can configure with the maximum number of external packages, as those are
only selected by the user when using TAU. However, one needs to be careful with compiler
and MPI library options. Each different set of compiler and MPI libraries requires a 
different setup of TAU. For LUMI this really only means that currently TAU needs to be 
built for each compiler in each LUMI stack, as there is only one supported MPI configuration
in each toolchain.

The installation process is equally unconventional and central installation unfriendly 
as that of PDT, or even worse.

-   It is clear that part of TAU consists of libraries and possibly tools for instrumentation
    that may depend on compiler options being used. However, part of the tools are just for
    postprocessing (and some libraries even require OpenGL). These should ideally be 
    separated in two parts so that users who need a specific configuration of the 
    instrumentation libraries, can build them with minimal effort why keeping using 
    already installed versions of the other tools. Unfortunately, this is not the way TAU
    is built.
    
    In fact, one should take into account that not all nodes in a cluster may have 
    working OpenGL software, even not with software emulation, as installing such tools 
    requires a considerable effort and as an installation in the OS image may not be
    what you want if you want to keep the images small, e.g., because they are located in
    a RAM disk as is the case on LUMI.

-   Just as PDT, the installation process looks like a traditional configure - 
    make - make install process but is not.
    
    -   The configure script does not honour any of the traditional environment variables
        to pass compilers and compiler options.
        
    -   The configure script already creates the installation directory and copies 
        several scripts to it.
        
    -   Simply using `make` seems equivalent with `make install` and already does an 
        installation in the final installation directories.
        
    This implies that a special EasyBlock will be needed to install this software as 
    it does not follow the model of EasyBuild were touching any final installation
    directory is postponed as long as is possible in the installation process to 
    minimise the chance that a mess is left in the actual software installation
    directories if a build fails, while still leaving the failed state in the build
    directories so that one can investigate what went wrong.
    
-   Even when specifying the compilers that should be used with `-cc`, `-c++`
    and `-fortran`, some code is compiled with a different compiler (`gcc`/`g++`
    so far in our experiments).
    
    Even though we don't see any compilation using `mpicc` etc., they are still searched
    in the configure process and it is not clear what consequences this may have for
    the later build.

-   Several of the scripts have `/tmp` hardcoded rather than using an environment
    variable if defined to look for the temporary directory. Hence it may leave a
    mess on `/tmp` which is a directory that is hard to clean on a shared node.
    
    Hopefully redirecting `/tmp` to a job or user specific directory which the 
    system administrators are investigating, will offer a solution for this.

-   Analysis of `bin/craycnl/Makefile.tau-gnu-mpi-pdt` (the name when using the GNU
    toolchain with support for MPI and PDT), also shows a number of issues
    
    -   The variable `TAUROOT` refers to the directory from which the software was
        installed, not the installation directory. So
        
        -   Either some of those files are needed when using TAU also but not copied
            to the installation directory, which effectively means that we cannot 
            even properly install to a different directory as the sources directory
            needs to be kept,
            
        -   Or this is an error in the setup and the value of that variable should
            be replaced by the directory specified with `-prefix` if that flag is used
            to install in a different directory from the sources directory.
            
    -   The environment variables that are used to set libraries and are manipulated 
        to add the TAU MPI wrappers will cause problems also. They are based on lists
        reported by the Cray PE wrapper scripts and then hard-coded in the Makefile,
        but the problem is that that list is dependent on both the status of the system
        at that day (e.g., path to `xpmem` may change in any update that updates `xpmem`
        as there is only one such library on the system) and also dependent on what other
        modules a user has loaded.
        
        -   It is not clear how that list will interact with any libraries that are 
            then added by the compiler wrappers.
             
        -   Compile TAU with only those modules loaded that TAU really needs. E.g., 
            unload the `cray-libsci` module or those libraries will also be added, 
            while they are different depending on whether OpenMP is used or not.

        -   Some problems may be solved by editing `Makefile.tau-XXX` during the 
            installation process. E.g., there is a path to the `xpmem` libraries that
            stays the same after a system update, but it is not that one that the compiler
            wrapper scripts report.
            
        -   If we need tricks like changing the MPI module that is loaded with a given
            version of the LUMI stack because the version that officially belongs to 
            the CPE version that the stack uses, is no longer compatible with the libfabric
            library on the system, it is unclear what the consequences are for using
            the TAU compiler wrapper scripts. 
            
            Several things may go wrong:
            
            -   The TAU compiler wrapper scripts will add one set of MPI libraries 
                while the Cray wrapper scripts that are then hopefully called,
                will add another set.
                
            -   It looks like the wrappers add an rpath to the directory where the 
                MPI libraries are located so the likely consequence is that the 
                old and broken libraries would be used when running the program
                compiled via the TAU wrapper script.
            
            Apart from that, users who would not be using the LUMI software stacks 
            with strict version control of all libraries, need to be aware that they 
            should rebuild TAU when they change to a different Cray MPICH library or
            they may run in the above problem.




## EasyBuild

-   [There is no support for TAU in the EasyBuilders repository](https://docs.easybuild.io/version-specific/supported-software/#t)

-   [There is no support for TAU in the CSCS repository](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/t)

-   [Support for tau in Spack](https://packages.spack.io/package.html?name=tau)

The Spack package suggests a lot of dependencies, but many are software that 
comes with the GPU software stack or other system software.


### Version 2.33.2

-   To minimise dependencies we currently rely on the OS-provided Java.

-   In principle one needs to register and then download TAU, but from the Spack
    `package.py` file we see that a direct download is possible using the URL
    `https://www.cs.uoregon.edu/research/tau/tau_releases/tau-2.33.2.tar.gz`.
