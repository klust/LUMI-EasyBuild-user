# CPE Containers

These containers should not be spread outside LUMI, and some even contain unofficial
versions and should not be spread to more users than needed. So do not spread without
explicit agreement with HPE.

Options: 

-   ccpe-23.12-cce_17-18-rocm-5.4.1-17_18.eb: Use the instance in the LUST directory, but
    still generate a module and some bootstrap scripts to play with.
    
    Only useable for LUST, though users who were provided with a copy of the container to store
    in their own project could simply adapt one of the first lines in the file to point 
    to the container.

-   ccpe-23.12-cce_17-18-rocm-5.4.1-17_18-COPY.eb: Install from the instance maintained by Alfio.
    The module will be called `ccpe/23.12-cce_17-18-rocm-5.4.1-17_18` though and the EasyConfig
    doesn't have a name following the conventions.
  
    To offer some security though obscurity the path where the container can be found,
    is not shown in the EasyConfig file. Before installing, set the environment
    variable EASYBUILD_SOURCEPATH to the directory where the sif file can be found.
    
    Sample installation commands:
    
    ```
    module load LUMI/23.09 partition/container EasyBuild-user
    EASYBUILD_SOURCEPATH=<mystery directory>
    eb ccpe-23.12-cce_17-18-rocm-5.4.1-17_18-COPY.eb
    ```
    
    Note: For LUST, one can also use `/project/project_462000008/CCPE` for the mystery 
    directory. This directory should be readable to LUST only!
    
    To save space you can omit the `.sif` file from the `$EBROOTCCPE` directory and instead 
    use a symbolic link to the one in the LUST project or mystery directory, but if 
    that is what you want to do you might use the other easyconfig just as well.


Options after installing and loading the module:

-   Start a shell in the LUMI environment using

    ```
    singularity exec $SIFCCPE bash
    ```
    
    The `SINGULARITY_BIND` environment variable contains all necessary links to play
    around on LUMI or to use the exec subcommand to start applications.
    
-   Start a shell in the LUMI environment using the bootstrap script:

    ```
    bootstrap_lumi
    ```
    
    Note that this script resets `SINGULARITY_BIND` to avoid conflicts with
    the binding options used with the sinularity command. Hence this script is
    not compatible with the `ccpe-cpe` modules.
    
-   Start a shell in an environment which is more or less what HPE provided:

    ```
    bootstrap_pure
    ```
    
    Due to the way the `/etc/bash.bashrc.local` provided in the container works,
    you'll know be using the TCL versions of a lot - if not all - PE modules 
    rather than their LUA counterpart, so the `module` command may react a bit
    unexpected!
    
    Note that this script resets `SINGULARITY_BIND` to avoid conflicts with
    the binding options used with the sinularity command. Hence this script is
    not compatible with the `ccpe-cpe` modules.

To test with the container, you can, e.g., try the examples on compiling software 
from the first exercise session of our 
[1-day training course](https://lumi-supercomputer.github.io/intro-latest).

TODO: It is not as easy as it seems below...

Running software that only needs some basic libraries from the PE should be easy as
that software effectively uses libraries from `/opt/cray/pe/lib64` and doesn't need
the modules to be loaded to run. Other software however that requires modules that are
only available in the container, is a bit more tricky to run, certainly when these
are MPI programs as the `srun` command should be run outside the container.


## First observations

-   Experimenting with the course programs for matrix multiplication

    -   Experiment: Compile outside the container, then try to run from the container
        to check if the new environment will be compatible with older binaries.
        
        To run in the container, we used `ccpe-cpe/23.09`, a module that adds extra
        bindings to `SINGULARITY_BIND`, but then we have to use `singularity exec $SIFCCPE bash`
        to get in the container as the current bootstrap scripts reset `SINGULARITY_BIND`
        to avoid conflicts.
        
        **PROBLEM:** The libraries have changed name and/or version (now `.so.6`
        while for 23.09 they were `.so.5`, but some names have also changed).
        
        Solution: I tried BLAS software in C and Fortran compiled with the GNU and
        Cray compilers (in `cpeGNU/23.09` and `cpeCray/23.09`) and the solution to
        get them running was to simply load `lumi-CrayPath`.

