# CPE Containers

These containers should not be spread outside LUMI, and some even contain unofficial
versions and should not be spread to more users than needed. So do not spread without
explicit agreement with HPE.

## General ideas

### Initialisation

We need two types of initialisation of the CPE container:

-   When first going into the container, an environment fully compatible with the container
    needs to be set up.

-   If we'd ever manage to start Slurm jobs or job steps from within the container, then we really
    want that environment to be propagated and not reset to avoid having to rebuild the whole
    environment, which is tricky to do in a job step as the job step would have to start singularity,
    but then not run the actual command it wants to run in that container but first rebuild the 
    environment from within the container.

Also, a full initialisation cannot be done entirely in the container:

-   Singularity will pass the environment from the calling process. This includes also the Lmod
    data structures and all variables set by the currently loaded modules.

    While it is easy to reset the Lmod data structures, it is not possible to properly reset all other
    environment variables that are set by those modules. This can only be done by unloading the modules
    (which executes the module script while reverting the effect of all commands that set something
    in the environment). As the regular CPE modules from the system are not available in the container,
    the unloading cannot be done in the container but has to be done before calling singularity.

-   When running an interactive shell in the container, you then want to construct a proper environment
    in the container. Singularity will source `/etc/bash.bashrc` which in turn may or may not source
    other initialisation scripts such as `/etc/bash.bashrc.local`.

    It looks like if you call `singularity exec` or `singularity run`, there is no automatic initialisation
    taking place. 

    **TODO**: Check if something needs to be done about this, as this may not be ideal to, e.g., run a 
    script that first wants to build an environment before running other commands.


#### Which initialisation script is executed when?

-   Scripts in `/singularity.d/env`: At the start of `singularity shell`, `singularity exec`.

    What one can do in these scripts, is limited though. It is a good place to set environment
    variables that should be available in the container.

-   What happens with `profile`, `bash.bashrc`, `profile.local` and `bash.bashrc.local`, depends 
    also on which Linux variant, et., is being used.

    For the CPE containers:

    -   In SUSE, one is advised to only use `profile.local` and `bash.bashrc.local` for site-specific
        changes and not change `profile` and `bash.bashrc`.

    -   `/etc/profile` will source the scripts in `/etc/profile.d` and then source `/etc/profile/local`
        if that script exists. The script does not exist in the CPE containers though.
        
    However, neither of those is called when a shell is started with `singularity shell` or
    `singlarity exec`.


#### Issue: How to recognise if an environment is compatible with the container?

-   There is no easy way to see this from the PE modules that are loaded as these modules do not set
    environment variables that point at the release of the PE, except that in recent version, the PE
    release is part of the version number for LibSci and perftools.

Current solution: Set and environment variable: `CCPE_VERSION=24.11` (or whatever the actual version is)
after a proper initialisation of the environment in the container.


### `singlarity shell` wrapper script `ccpe-shell`






## EasyBuild

### Container for 24.11 obtained from the HPE support web site.

-   The goal of the EasyConfig is to mimic what the `ccpe-config` script
    from HPE does:
    -   Binding other files from the system
    -   Binding Slurm commands
    -   Binding libfabric install
    -   Binding some system files

-   We inject the file `/.singularity.d/env/99-z-ccpe-init` which we use
    to define additional environment variables in the container that can
    then be used to execute commands.
    
    Currently used so that `eval $INICCPE` does a full (re)initialization
    of LMOD so that it functions in the same way as on LUMI.
    