# GAMESS technical instructions





## Experience with the manual compilation process

* GAMESS claims to support building in a different directory but that seems
* GAMESS claims to support building in a different directory but that seems
  to be buggy. It was correct in the Sep302021R2 version but some changes
  have been made that makes it fail now.

* GAMESS contains a lot of old code. Many of the scripts are still csh scripts
  which are not well supported on LUMI. Due to an incomplete configuration on
  LUMI, scripts that try to read the csh initialisation files will fail.
  The `config` script does not read those files and will run OK, but it
  generates a csh script that will not run properly. As the Makefile executes
  the script in a special way it should still be OK though.

  Now if they would only use standard POSIX shell scripts that can work
  with multiple shells that support POSIX...

* The scripts to download additional software that might be needed, do
  not work.

* It is not entirely clear what OpenMP GPU offload needs as it is not well
  documented. The config script has a configuration for crusher and
  frontier but that links to software on those systems that is installed
  outside of the PE and not clear how it is installed or with what options.

  It does require hipfortran and it looks like there is a configuration of
  hipfortran on Frontier which may be compiled specifically for use with
  GAMESS and works with the Cray compilers.

* Compile problems

    * The installation of libxc fails as the install step tries to copy a file
      that does not exist where it is looking.

      It turns out that the module files with the Cray compiler have a different
      name as expected: XC_F90_LIB_M.mod instead of xc_f90_lib_m.mod
      and XC_F03_LIB_M.mod instead of xc_f03_lib_m.mod.

      A possible solution is to find how one can inject the `-ef` option to the
      Fortran compiler. It might be possible to do so at the end of
      `3rd-party/libxc/m4/fcflags.m4`. DOESN'T WORK

      Set `FFLAGS` in the environment or change the root Makefile to pass the Fortran
      flags to the CMake of libxc?

      The install tests of libxc can fail due to file system issues on LUMI:
      if the file system freezes, some tests may be reported as "timeout" and
      cause the whole test process to fail.

    * The Makefile doesn't pass the installation directory for libmdi in a proper
      way when it calls CMake to configure libmdi. As a result the build fails.

      Cause: The root Makefile calls CMake and uses the make variable `$(MDI_INSTALL)`
      for the prefix argument, but it hasn't assigned a value to that variable.
      That environment variable is the remain of an older Makefile where each of
      the 3rd party libraries was installed in a separate subdirectory. It likely
      has to be replaced with $(GMS_3RD_PATH).

    * And libmdi also suffers from the same module problem as libxc: It expects
      the modulefiles with all lowercase names.
