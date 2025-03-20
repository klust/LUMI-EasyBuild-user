# CPE Containers

These containers should not be spread outside LUMI, and some even contain unofficial
versions and should not be spread to more users than needed. So do not spread without
explicit agreement with HPE.

## Building blocks

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
    in the container. Singularity may source `/etc/bash.bashrc` which in turn may or may not source
    other initialisation scripts such as `/etc/bash.bashrc.local`.

    It looks like if you call `singularity exec` or `singularity shell`, there is no automatic initialisation
    taking place. 


### Which initialisation script is executed when?

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


### Issue: How to recognise if an environment is compatible with the container?

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


### Issue: Lmod caches

As the environment in the container is not compatible with the environment outside, 
we cannot use the regular user Lmod cache, or it may get corrupted, certainly if a 
user is working both in and out of the container at the same time.

Possible solutions/workarounds:

1.  Work with `LMOD_IGNORE_CACHE=1` in the container. 
    As the whole of `/appl/lumi` is mounted in the containers by our EasyConfigs, this 
    will slow down module searches in Lmod considerably.

2.  Modify `/opt/cray/pe/lmod/lmod/libexec/myGlobals.lua`: Look for the line with `usrCacheDir` 
    and define a unique directory for it, e.g., `.cache/lmod/ccpe-{version}-{versionsuffix}`.


### Issue: Getting Slurm to work

!!! Note "The container images that LUST provides have been prepared for Slurm support."
    The container images that LUST provides as base images, have been modified in two
    crucial places to enable Slurm support by only bind mounting other files and directories.
    The text below is relevant though if you want to download your own image from the HPE
    support site and derive from our EasyConfigs to use (on, e.g., a different system for
    which you happen to be licensed to use the containers).

Bind mounting the Slurm commands and libraries and some other libraries and work directories
that they use, is not enough to get Slurm working properly in the container. The container
needs to know the `slurm` user with the correct user- and groupid. The `slurm` user has
to be known in `/etc/passwd` and `/etc/group` in the container.

We know only one way to accomplish this: Rebuilding the container and using the `%files`
section in the definition file to copy those two files from LUMI:

```
Bootstrap: localimage

From: cpe_2411.sif

%files

    /etc/group
    /etc/passwd
```

Approaches that try to modify these files in the `%post` phase, don't work. At that
moment you're running a script in singularity, and you don't see the real files,
but virtual ones with information about your userid and groups added to those
files. Any edit will fail or be discarded, depending on how you do it.

Bind-mounting those files also does not work, as singularity then assumes that
those files contain all groups and userid, and will not add the lines for 
userid and groups of the user that is running the container to the virtual
copies.

We have adapted the base images that we provide so that the `-raw` modules below
that only rely on bind mounts and environment variables set through the module,
can still support running Slurm commands inside the container. However, if a user
wants to adapt those scripts for another container downloaded from the HPE web site,
or even the same container if they are licensed to use it elsewhere and want to build
on our work, they will have to rebuild that image with the above definition file.

And of course, if they would like to use it on a different system, things can be different,
as, e.g., the numeric user and group id for the Slurm user may be different. 
Forget about portability of containers if you need to use these tricks...


### Recognising that you're working in a container.

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
easier. They try to deal with the two environments problem.


#### `singularity shell` wrapper script `ccpe-shell`

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


#### `singularity exec` wrapper script `ccpe-exec`

This is a convenience wrapper script and is not usefull if you want to pass arguments 
to singularity rather than to the command you start.

It performs the same functions as `ccpe-shell`, but passes its arguments to the
`singularity exec $SIFCCPE` command.


#### `singularity run` wrapper script `ccpe-run`

This is a convenience wrapper script and is not usefull if you want to pass arguments 
to singularity (rather than to the command it tries to run, if given).

It performs the same functions as `ccpe-shell`, but passes its arguments to the
`singularity run $SIFCCPE` command.


#### `singularity` wrapper script `ccpe-singularity`

This wrapper only cleans up the environment and then calls `singularity` passing all
arguments of the wrapper unmodified to the `singularity` command. So you also need
to pass the name of the container image, but can now call any singularity command
with all singularity command-specific options in a clean environment.


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
    
    This is done via the 
    `/.singularity.d/env/99-z-init-ccpe.sh` script mentioned above.

-   libfabric and CXI provider: Bind mount from the system.

    To find the correct directories and files to bind, execute the following commands:

    ```bash
    module --redirect show libfabric | grep '"PATH"' | awk -F'"' '{ print $4 }' | sed -e 's|/bin||'
    module --loc --redirect show libfabric | sed -e 's|\(.*libfabric.*\)/.*|\1|'
    ldd $(module --redirect show libfabric | grep '"LD_LIBRARY_PATH"' | awk -F'"' '{ print $4 }')/libfabric.so | grep libcxi | awk '{print $3}'
    ```

-   ROCm: ROCm version from the system, so 6.0.3 at the time of writing.

    To find the correct directories and files to bind, execute the following commands:

    ```bash
    module --loc --redirect show rocm
    module --loc --redirect show amd
    module --redirect show rocm | grep ROCM_PATH | awk -F'"' '{ print $4 }'
    echo "$(module --redirect show rocm | grep PKG_CONFIG_PATH | awk -F'"' '{ print $4 }')/$(module --redirect show rocm | grep PE_PKGCONFIG_LIBS | awk -F'"' '{ print $4 }').pc"
    ```
-   Slurm support is still provided as much as possible by binding files from the system
    to ensure that the same version is used in the container as LUMI uses, as otherwise
    we may expect conflicts.

    There is an issue though users use this EasyConfig with a freshly downloaded copy
    of the container. See the remarks earlier in this text on getting Slurm to work in
    the container.

-   We made a deliberate choice to not hard-code the bindings in the `ccpe-*`
    scripts in case a user would want to add to the environment `SINGULARITY_BIND` variable,
    and also deliberately did not hard-code the path to the container file
    in those scripts as in this module, a user can safely delete the container
    from the installation directory and use the copy in `/appl/local/containers/easybuild-sif-images` 
    instead if they built the container starting from our images and in `partition/container`.


#### Version: ccpe-24.11-LUMI

In this version, we made several modifications to the container so that we can install 
a LUMI software stack almost the way we would do so without a container. Several of the
files that we bind mount in the `-raw` version are now also included in the container build
itself, though we still store copies of it in the installation directory, subdirectory
`config`, which may be useful to experiment with changes and overwrite the versions in
the container.

-   We inject the file `/.singularity.d/env/99-z-ccpe-init` which we use
    to define additional environment variables in the container that can
    then be used to execute commands.
    
    Currently used so that `eval $INITCCPE` does a full (re)initialization
    of Lmod so that it functions in the same way as on LUMI.

-   As the container is already set up to support a runscript, we simply inject
    a new one via `%files` which makes it easier to have a nice layout in the 
    runscript and in the container definition file.

-   Lmod cache strategy: User cache stored in a separate directory, 
    `~/.cache/lmod/ccpe-%(version)s-%(versionsuffix)s`, by editing
    `/opt/cray/pe/lmod/lmod/libexec/myGlobals.lua`.
    
-   libfabric and CXI provider: Bind mount from the system.

    To find the correct directories and files to bind, execute the following commands:

    ```bash
    module --redirect show libfabric | grep '"PATH"' | awk -F'"' '{ print $4 }' | sed -e 's|/bin||'
    module --loc --redirect show libfabric | sed -e 's|\(.*libfabric.*\)/.*|\1|'
    ldd $(module --redirect show libfabric | grep '"LD_LIBRARY_PATH"' | awk -F'"' '{ print $4 }')/libfabric.so | grep libcxi | awk '{print $3}'
    ```

-   ROCm: ROCm version from the system, so 6.0.3 at the time of writing.

    To find the correct directories and files to bind, execute the following commands:

    ```bash
    module --loc --redirect show rocm
    module --loc --redirect show amd
    module --redirect show rocm | grep ROCM_PATH | awk -F'"' '{ print $4 }'
    echo "$(module --redirect show rocm | grep PKG_CONFIG_PATH | awk -F'"' '{ print $4 }')/$(module --redirect show rocm | grep PE_PKGCONFIG_LIBS | awk -F'"' '{ print $4 }').pc"
    ```

-   Slurm support is still provided as much as possible by binding files from the system
    to ensure that the same version is used in the container as LUMI uses, as otherwise
    we may expect conflicts.

    One thing is done during the build process though: We need to copy the `/etc/group` 
    and `/etc/passwd` files from the system into the container during the `%files` phase
    (editing those files in the `%post` phase does not work). 

-   The sanity check is specific to the 24.11 containers and will need to be updated
    for different versions of the programming environment.

-   This module is different from the `-raw` version in that it does require that
    the sif file in installed in the installation directory of the module, as it can
    be customised in the EasyConfig.
