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
    `singlarity exec`. As can be seen from files in `/.singularity.d/actions`, `singularity 
    exec` simply execs the command in a restricted shell (`/bin/sh`) while `singularity shell`
    starts bash with the `--norc` option.
    
    `singularity run` as defined for the CPE container however does source `/etc/bash.bashrc`
    and hence `/etc/bash.bashrc.local` and the `~/.bashrc` file from the user. However,
    after reading `~/.bashrc`, there is still some code somewhere that resets the `PS1`
    environment variable to either the value of `SINGULARITYENV_PS1` or `Singlarity>`.
    Somehow, before calling `~/.bashrc`, `PROMPT_COMMAND` is set to something like
    `PS1=<prompt from singularity> ; unset PROMPT_COMMAND`. Now if PROMPT_COMMAND is
    set, it is executed before showing the prompt defined by `PS1` and this hence resets
    the prompt that is set in., e.g., `~/.bashrc`.
    
As currently we have no proper solution to fully initialise the container from the 
regular Linux scripts when using `singularity shell` or `singularity exec`, 
the modules define the `INITCCPE` environment variable which 
contains the commands to execute to initialise Lmod in the container. 
Use `eval $SIFCCPE` for that purpose.

Our EasyBuild modules do provide a `/etc/bash.bashrc.local` file that does the same 
initialisations as `eval $SIFCCPE`. So calling `source /etc/bash.bashrc` is also an option 
to initialise Lmod in the container.


#### Issue: How to recognise if an environment is compatible with the container?

-   There is no easy way to see this from the PE modules that are loaded as these modules do not set
    environment variables that point at the release of the PE, except that in recent version, the PE
    release is part of the version number for LibSci and perftools.

Current solution: Set and environment variable: `CCPE_VERSION=24.11` (or whatever the actual version is)
after a proper initialisation of the environment in the container.

This is important as we do not want to clear an environment that is compatible with 
the container, and only want to do so if it is not. If we'd ever manage to start Slurm 
jobs from within the container, this is important as one can then set the necessary 
environment variables in the calling container already, greatly simplifying the job 
script as there one would need to run a script in the container before the main application 
runs to do the proper initialisations. This is both cumbersome and costly, as in that 
case, each MPI rank would have to load a set of modules that may come from the system 
instead of from the container and hence put stress on Lustre.


#### Issue: Lmod caches

As the environment in the container is not compatible with the environment outside, 
we cannot use the regular user Lmod cache, or it may get corrupted, certainly if a 
user is working both in and out of the container at the same time.

Possible solutions/workarounds:

1.  Work with `LMOD_IGNORE_CACHE=1` in the container. 
    As the whole of `/appl/lumi` is mounted in the containers by our EasyConfigs, this 
    will slow down module searches in Lmod considerably.

2.  Modify `/opt/cray/pe/lmod/lmod/libexec/myGlobals.lua`: Look for the line with `usrCacheDir` 
    and define a unique directory for it, e.g., `.cache/lmod/ccpe-{version}-{versionsuffix}`.


#### Recognising that you're working in a container.

An easy way to check if you're in working in a singularity container, is to check if 
the directory `/.singularity.d` exists. Based on that, you can adapt your prompt in
your `~/.bashrc` file and source that file when you enter the container.

Our EasyBuild-generated modules do set the environment variable `SINGULARITYENV_PS1` 
which in turn sets the `PS1` environment variable in the shell. If you don't like the 
default, search in the EasyConfig file for `modextravars` and outcomment the line thet
sets `SINGULARITYENV_PS1`. If you rebuild in your own space, you'll get a module that 
does not set `PS1` in the container.


### Wrapper scripts

The EasyBuild-installed modules do provide some wrapper scripts that make some tasks 
easier. 


#### `singlarity shell` wrapper script `ccpe-shell`

This is a convenience wrapper script and is not usefull if you want to pass arguments 
to singularity (rather than to the shell it starts).

The script does a clean-up of the modules in your environment and then cleans up Lmod 
completely, as the environment outside the container is not compatible with the environment 
in the container and as the loaded modules are needed to correctly unload them. It 
does save the environment variables set by the `ccpe` module to restore them after 
the `module --force purge` operation as otherwise the container wouldn't function properly 
anymore. 

To make sure that `/etc/profile` would execute properly if it were called, the script 
also unsets `PROFILEREAD`, as the environment generated by the system `/etc/profile` 
may not be the ideal one for the container.


#### `singlarity exec` wrapper script `ccpe-exec`

This is a convenience wrapper script and is not usefull if you want to pass arguments 
to singularity rather than to the command you start.

It performs the same functions as `ccpe-shell`, but passes its arguments to the
`singularity exec $SIFCCPE` command.


#### `singularity run` wrapper script `ccpe-run`


This is a convenience wrapper script and is not usefull if you want to pass arguments 
to singularity (rather than to the command it tries to run, if given).

It performs the same functions as `ccpe-shell`, but passes its arguments to the
`singularity run $SIFCCPE` command.


## EasyBuild

### Container for 24.11 obtained from the HPE support web site.

#### Version: ccpe-24.11-raw

In this version, we use the container obtained from the HPE web site without
changes in the container, but try to do everything via files and directories that we 
bind mount in the container and environment variables that we inject into the container 
using `SINGULARITYENV_*`.

-   The goal of the EasyConfig is to mimic what the `ccpe-config` script
    from HPE does:
    -   Binding other files from the system
    -   Binding Slurm commands
    -   Binding libfabric install
    -   Binding some system files

-   We inject the file `/.singularity.d/env/99-z-ccpe-init` which we use
    to define additional environment variables in the container that can
    then be used to execute commands.
    
    Currently used so that `eval $INITCCPE` does a full (re)initialization
    of Lmod so that it functions in the same way as on LUMI.

-   Lmod cache strategy: Set `LMOD_IGNORE_CACHE=1`.
    
    TODO: How is this done?

-   libfabric and CXI provider: Bind mount from the system.

-   ROCm: ROCm version from the system, so 6.0.3 at the time of writing.


#### Version: ccpe-24.11-lumi

In this version, we made several modifications to the container so that we can install 
a LUMI software stack almost the way we would do so without a container. Several of the
files that we bind mount in the `-raw` version are now also included in the container build
itself, though we still store copies of it in the installation directory, subdirectory
`config`, which may be useful to experiment with changes and overwrite the versions in
the container.

-   Lmod cache strategy: User cache stored in a separate directory, 
    `~/.cache/lmod/ccpe-%(version)s-%(versionsuffix)s`, by editing
    `/opt/cray/pe/lmod/lmod/libexec/myGlobals.lua`.
    
-   libfabric and CXI provider: Bind mount from the system.

-   ROCm: ROCm version from the system, so 6.0.3 at the time of writing.

