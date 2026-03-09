# EESSI via singularity modules

!!! Note "Not pre-installed as we expect further corrections will be needed."
    This module is not yet pre-installed as we expect that further corrections may be
    needed, and also as the EasyConfig is really also a template for users who want to
    customise their environment a bit by, e.g., adding some software in the container
    that is not provided by EESSI

    To install:
    ```
    module load LUMI partition/container EasyBuild-user
    eb EESSI-2025.06-singularity.eb
    ```
    (or whatever the name of the EasyConfig is that you want to install).

The `EESSI/YYYY.MM-singularity` modules are user-installable modules to make life with the
EESSI containers a bit easier. 

These EasyConfigs perform the following tasks:

-   They build a container based on a container definition file embedded in the EasyConfig.
    Hence you can customise that definition file, e.g., to install additional packages from
    the base OS of the container to compensate for features that are missing in the EESSI
    compatibility layer and modules. E.g., EESSI itself only contains nano, a very basic
    editor, in the compatibility layer so you may want to add a more powerful editor such
    as vim or emacs.

-   The modules set a number of environment variables that make life easier:

    -   `$SIF` and `$SIFEESSI` contain the name and full path of the container.

    -   `SINGULARITY_BIND` contains all useful bind mounts: It mounts the SquashFS file 
        that contains the actual EESSI image, does a bind mount for host injections, and
        also contains the necessary bind mounts to use your files on /scratch, /project and
        /flash in the container. (Singularity itself takes care of the home directory.)

    -   `EXPORTEESSI` is purely for internal use in the wrapper scrips discussed below.

-   The containers should not import the Lmod state from the system as software from 
    `/appl/lumi` cannot run as most software relies on system libraries on LUMI that may
    not be in the container and the Cray PE that also has its requirements and initialisations
    that are difficult to do in a lightweight container.

    Hence wrapper scripts are provided that replace some singularity commands:

    -   `eessi-shell` replaces `singularity shell $SIF`

    -   `eessi-exec` replaces `singularity exec $SIF`

    -   `eessi-run` or simply `eessi` replace `singularity run $SIF`

    -   `eessi-singularity` simply replaces `singularity` without additional arguments.

-   The EasyConfig also injects some files in the container during the build process to take
    care of the EESSI initialisation. Unfortunately, the EESSI initialisation scripts had to
    be reprogrammed as they are not compatible with the restricted shell that singularity
    uses internally to initialise the container before handing over control to the user 
    command or regular shell.

    Hence there is no guarantee that adapting the current EasyConfigs to a new version of 
    EESSI is as easy as simply adapting the version at the top of the EasyConfig. However,
    as the initialisation scripts for the 2023.06 and 2025.06 versions are the same, switchting
    between these is as easy as adapting the version in the EasyConfig. As the EasyConfig is
    fully parametrised, you only need to do so at the top of the EasyConfig.

Apart from EESSI-specific variables, the following environment variables in and out of the
container are also useful:

-   The list with module extensions can become very long with all Python and R packages.
    You can hide that list by setting `LMOD_AVAIL_EXTENSIONS` to `no`, either in or out of
    the container.

    Keep in mind though that if you use the `ModuleExtensions` module in the regular LUMI 
    environment to control showing extensions in the regular LUMI stack, the variable when
    set outside the container will be deleted as all modules are force unloaded by the
    wrapper scripts due to possible compatibility issues.

Some Slurm commands are also bind mounted into the container by the module
and can be used to start or inspect other EESSI-based jobs.

-   `sacct`

-   `salloc`, but note that it does not completely work as it does outside the
    container as it cannot find the right shell to start. The way to use it,
    is to add 'bash' as the last argument, e.g.,
    ```
    salloc -N1 -n1 -c128 -pstandard -t15:00 bash
    ```
    as otherwise you will get the error message:
    ```
    salloc: error: _fork_command: Unable to find command ""
    ```

-   `sbatch`. Note however that that job will not start in the container. However,
    once EESSI is also available directly on the compute nodes, we expect it will
    be possible to use this to start jobs that can execute in EESSI without first
    re-initialising EESSI.

-   `sinfo`

-   `squeue`

-   `srun`. The same remarks hold as for `sbatch`

-   `sstat`

Other Slurm commands could probably also be bind mounted but haven't been 
tested. Note that we are running the SUSE binaries on an Ubuntu container and
these commands can also pick up libraries from EESSI, so this is a cocktail
that may give some issues. The basic functionality does work however.


## To mention

-   Support for `LMOD_AVAIL_EXTENSIONS` to hide extensions (set to `no`) or show
    them (unset or set to `yes`).

