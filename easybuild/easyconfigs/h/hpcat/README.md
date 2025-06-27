# hpcat technical info

-   [HPE `hpcat` on GitHub](https://github.com/HewlettPackard/hpcat)

    -   [GitHub releases](https://github.com/HewlettPackard/hpcat/tags) via tags.


## EasyBuild

There is no support for `hpcat` in any repository that we know of. The tool was developed for some
sites with HPE Cray EX supercomputers.


### Version 0.3

The EasyConfig is really a bit messy for a couple of reasons:

-   LUMI lacks the `hwloc-devel` package so we simply copied the header files from another system
    and download them from LUMI-O.

-   The Makefile was modified to integrate better with EasyBuild and to work around a problem with
    finding the `hwloc` library on LUMI. 

    Rather than writing a new Makefile or a patch, we actually used a number of `sed` commands to edit
    the Makefile:

    -   `mpicc` was replaced with `$(CC)` so that the wrappers are used instead.
    -   `-O3` was replaced with `$(CFLAGS)` to pick up the options from EasyBuild
    -   '-fopenmp' is managed by the Makefile though and not by EasyBuild. On one hand because the
        ultimate goal is to integrate with another packages that sometimes needs and sometimes does not
        need the OpenMP flags, on the other hand to use `$(CFLAGS)` also for `hipcc`.
    -   `-lhwloc` is replaced with `-Wl,/usr/lib64/libhwloc.so.15`. We had to do this through `-Wl` as
        the `hipcc` driver thought this was a source file.
    -   As '-L.' is not needed, it is omitted.

-   As there is no `make install`, we simply use the `MakeCp` EasyBlock, doing the edits to the Makefile in
    `prebuiltopts`.
    
    Not that we copy the `libhip.so` file to the `lib` directory as that is the conventional 
    place to store shared objects, but it is not found there by `hpcat`, so we also create a
    symbolic link to it in the `bin` subidrecitory.

-   Note that the accelerator target module should not be loaded when using the wrappers as the OpenMP offload
    options cause a problem in one of the header files used.


### Version 0.4

This version was released shortly after 0.3 with some changes requested by the Frontier 
people. 

The EasyConfig builds on the one for 0.3:

The EasyConfig is really a bit messy for a couple of reasons:

-   LUMI lacks the `hwloc-devel` package so we simply copied the header files from another system
    and download them from LUMI-O.

-   The Makefile was modified to integrate better with EasyBuild and to work around a problem with
    finding the `hwloc` library on LUMI. 

    Rather than writing a new Makefile or a patch, we actually used a number of `sed` commands to edit
    the Makefile:

    -   `mpicc` was replaced with `$(CC)` so that the wrappers are used instead.
    -   `gcc` was replaced with `$(CC)` so that the wrappers are used instead.
    -   `-O3` was replaced with `$(CFLAGS)` to pick up the options from EasyBuild
    -   '-fopenmp' is managed by the Makefile though and not by EasyBuild. On one hand because the
        ultimate goal is to integrate with another packages that sometimes needs and sometimes does not
        need the OpenMP flags, on the other hand to use `$(CFLAGS)` also for `hipcc`.
    -   `-lhwloc` is replaced with `-Wl,/usr/lib64/libhwloc.so.15`. We had to do this through `-Wl` as
        the `hipcc` driver thought this was a source file.
    -   As '-L.' is not needed, it is omitted.

-   As there is no `make install`, we simply use the `MakeCp` EasyBlock, doing the edits to the Makefile in
    `prebuiltopts`.
    
    Not that we copy the `libhip.so` file to the `lib` directory as that is the conventional 
    place to store shared objects, but it is not found there by `hpcat`, so we also create a
    symbolic link to it in the `bin` subidrecitory.

-   Note that the accelerator target module should not be loaded when using the wrappers as the OpenMP offload
    options cause a problem in one of the header files used.


### Version 0.8

A lot has changed since version 0.4, so the EasyConfig is practically new.

-   There is now a `configure` script that actually calls CMake. So we switched to a `ConfigureMake`
    EasyConfig.
    
-   The package now uses `hwloc` and `libfort` as submodules, but they do not appear 
    in the standard GitHub download. Hence we derived the versions from the commits, download those
    two packages separately and install in the correct directory before configuring 
    and building `hpcat`
    
-   No more edits are needed.

-   The LICENSE file now needs to be copied in `postinstallcmds`.
