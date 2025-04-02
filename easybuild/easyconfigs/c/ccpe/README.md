# CPE Containers

These containers should not be spread outside LUMI, and some even contain unofficial
versions and should not be spread to more users than needed. So do not spread without
explicit agreement with HPE.

## Building blocks

### Initialisation

We need two types of initialisation of the CPE container:

-   When first going into the container, an environment fully compatible with the container
    needs to be set up.

-   When starting Slurm jobs from within the container that should also run in the container, 
    then we really would like an option to propagate that environment.

    This requires some care when writing the job script, but the module defines an environment
    variable that can be `eval`'ed to properly initialise the environment in the job script
    and run the job script itself in a container. 

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
    taking place though. So we create an environment variable in the container, `INITCCPE`, that will
    at least take care of initialising Lmod properly.  


### Which initialisation script is executed when?

-   Scripts in `/singularity.d/env`: At the start of `singularity shell`, `singularity exec`,
    `singularity run`.

    What one can do in these scripts, is limited though. It is a good place to set environment
    variables that should be available in the container.

-   What happens with `profile`, `bash.bashrc`, `profile.local` and `bash.bashrc.local`, depends 
    also on which Linux variant, et., is being used.

    For the CPE containers:

    -   In SUSE, one is advised to only use `profile.local` and `bash.bashrc.local` for site-specific
        changes and to not change `profile` and `bash.bashrc`.

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

There is no easy way to see this from the PE modules that are loaded as these modules do not set
environment variables that point at the release of the PE, except that in recent version, the PE
release is part of the version number for LibSci and perftools.

Current solution: Set and environment variable: `CCPE_VERSION=24.11` (or whatever the actual version is)
after a proper initialisation of the environment in the container.

This is important as we do not want to clear an environment that is compatible with 
the container, and only want to do so if it is not. When starting Slurm jobs from
within the container, this is important as one can then set the necessary 
environment variables in the calling container already, mimicking the behaviour
that users are used to from running jobs outside containers. Moreover, we need to
be able to set up an environment in the job script that is then properly inherited
when using `srun` to create job steps as otherwise, each MPI rank would also have 
to first create a proper environment.


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

    This procedure is easy when we rebuild the container, but in EasyConfig recipes that do
    not do this, it would require to regenerate this long file outside the container, do the
    edits there, and then bind mount it when running the container, which is not very
    practical, but does work.


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

The one issue is that when using `ccpe-run`, singularity will still try to impose
its own prompt (which also shows that you are in a singularity container but is 
otherwise not very powerful) by setting the environment variable `PROMPT_COMMAND`
to some code that will try to push its prompt. You can unset this environment variable
in your `$HOME.bashrc` script if you are not using other tools that play with
this environment variable.


### Wrapper scripts

The EasyBuild-installed modules do provide some wrapper scripts that make some tasks 
easier. They try to deal with the two environments problem.


#### `singularity shell` wrapper script `ccpe-shell`

This is a convenience wrapper script and is not useful if you want to pass arguments 
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

This is a convenience wrapper script and is not useful if you want to pass arguments 
to singularity rather than to the command you start.

It performs the same functions as `ccpe-shell`, but passes its arguments to the
`singularity exec $SIFCCPE` command.


#### `singularity run` wrapper script `ccpe-run`

This is a convenience wrapper script and is not useful if you want to pass arguments 
to singularity (rather than to the command it tries to run, if given).

It performs the same functions as `ccpe-shell`, but passes its arguments to the
`singularity run $SIFCCPE` command.


#### `singularity` wrapper script `ccpe-singularity`

This wrapper only cleans up the environment and then calls `singularity` passing all
arguments of the wrapper unmodified to the `singularity` command. So you also need
to pass the name of the container image, but can now call any singularity command
with all singularity command-specific options in a clean environment.


## Starting jobs

The problem with running jobs, is that they have to deal with two incompatible
environments:

1.  The environment outside the container that does not know about the HPE Cray
    PE modules of the PE version in the container, and may not know about some other
    modules depending on how `/appl/lumi` is set up.
    
    *TODO: We may consider pre-installing modules in an alternative for `/appl/lumi`
    but mount that as `/appl/lumi` in the container. This would make it easier for
    LUST to support the same container with different ROCm versions.*
    
2.  The environment inside the container that does not know about the HPE Cray PE
    modules installed in the system, and may not know about some other 
    modules depending on how `/appl/lumi` is set up.

This is important, because unloading a module in Lmod requires access to the correct
module file, as unloading is done by "executing the module file in reverse": The module
file is executed, but each action that changes the environment, is reversed. Even a
`module purge` will not work correctly without the proper modules available. Environment
variables set by the modules may remain set. This is also why the module provides the
`ccpe-*` wrapper scripts for singularity: These scripts are meant to be executed in 
an environment that is valid outside the container, and clean up that environment before
starting commands in the container so that the container initialisation can start from 
a clean inherited environment.

See also the example of how broken things can be in the user documentation.

??? Example "Exploring how to run with the CCPE containers"

    The next job script tries to run some commands from the container, exploring the
    environment. It is the basis for the job script template that we will discuss next.

    ```bash
    #!/bin/bash
    #
    # This test script should be submitted with sbatch from within a CPE 24.11 container.
    # It shows very strange behaviour as the `module load` of some modules fails to show
    # those in `module list` and also fails to change variables that should be changed.
    #
    #SBATCH -J example4
    #SBATCH -p small
    #SBATCH -n 2
    #SBATCH -c 1
    #SBATCH -t 5:00
    #SBATCH -o %x-%j.md
    #SBATCH --export=SINGULARITY_BIND,SIF,SIFCCPE
    # And add line for account

    #
    # Ensure that we can find the container. This might not be the case if this job script
    # is launched from outside the container with the ccpe module not loaded.
    #
    if [ -z "${SIFCCPE}" ]
    then
        module load CrayEnv ccpe/24.11-LUMI
    fi

    #
    # Block that can simply be copied, but note that the --export above is
    # important to have a clean shell on the system side.
    #
    if [ ! -d "/.singularity.d" ]
    then

        echo -e "# Prequel - In batch script but not in the container\n"

        echo -e "-   Environment variable \`SINGULARITY_BIND\`: \`${SINGULARITY_BIND}\`.\n"
        echo -e "-   Environment variable \`SIF\`: \`${SIF}\`.\n"
        echo -e "-   Environment variable \`SIFCCPE\`: \`${SIFCCPE}\`.\n"
        echo -e "-   Environment variable \`CRAY_CC_VERSION\`: \`${CRAY_CC_VERSION}\`. Hope for \`17.0.1\`, the value in the system environment.\n"
        
        echo -e "Do we have any modules loaded? Let's check with \`module list\`:\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
        
        echo -e "Let's try a full clean-up saving \`SINGULARIT_BIND\`, \`SIF\`and \`SIFCCPE\`:\n\n\`\`\`\n"
        
        save_SIF="$SIF"
        save_SIFCCPE="$SIFCCPE"
        save_BIND="$SINGULARITY_BIND"
        
        module --force purge
        eval $($LMOD_DIR/clearLMOD_cmd --shell bash --full --quiet)
        unset LUMI_INIT_FIRST_LOAD
        ## Make sure that /etc/profile does not quit immediately when called.
        unset PROFILEREAD
        
        export SIF="$save_SIF"
        export SIFCCPE="$save_SIFCCPE"
        export SINGULARITY_BIND="$save_BIND"
        
        echo -e "\n\`\`\`\n" 

        echo -e "Check the variables again:\n"    
        echo -e "-   Environment variable \`SINGULARITY_BIND\`: \`${SINGULARITY_BIND}\`.\n"
        echo -e "-   Environment variable \`SIF\`: \`${SIF}\`.\n"
        echo -e "-   Environment variable \`SIFCCPE\`: \`${SIFCCPE}\`.\n"
        echo -e "-   Environment variable \`CRAY_CC_VERSION\`: \`${CRAY_CC_VERSION}\`. If empty then cleaning up worked.\n"
        
        echo -e "Now restarting the script in the container..."
        exec singularity exec "$SIFCCPE" "$0" "$@"
        
    else

        echo -e "\n\n# Intermediate: Set up the container environment"
    
        echo -e "Check the value of \`INITCCPE\`:\n\`\`\`\n$INITCCPE\n\`\`\`\n"
    
        echo -e "Calling \`eval \$INITCCPE\`:\n\n\`\`\`\n"
        eval $INITCCPE
        echo -e "\n\`\`\`\n "
    
        echo -e "Check the variables again:\n"    
        echo -e "-   Environment variable \`SINGULARITY_BIND\`: \`${SINGULARITY_BIND}\`.\n"
        echo -e "-   Environment variable \`SIF\`: \`${SIF}\`.\n"
        echo -e "-   Environment variable \`SIFCCPE\`: \`${SIFCCPE}\`.\n"
        echo -e "-   Environment variable \`CRAY_CC_VERSION\`: \`${CRAY_CC_VERSION}\`. Hope for\`18.0.1\`, the value for 24.11 in the container.\n"

    fi

    echo -e "\n\n# Body of the job script - Building and investigating the environment\n"

    echo -e "Detected version of the module tool (should be the container one, 8.3.37 for 24.11): \n\`\`\`\n$(module --version 2>&1)\n\`\`\`\n"
    echo -e "List of modules currently loaded (should be the container ones):\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
    echo -e "Environment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
    echo -e "Now doing a \`module unload cce\`:\n\n\`\`\`\n"
    module unload cce 2>&1
    echo -e "\n\`\`\`\n"
    echo -e "Environment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`. This should be empty\n"
    echo -e "Now executing a 'module purge':\n\n\`\`\`\n"
    module purge 2>&1
    echo -e "\n\`\`\`\n"
    echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
    echo -e "Now executing \`module load cce\`':\n\n\`\`\`\n"
    module load cce 2>&1
    echo -e "\n\`\`\`\n"
    echo -e "And listing the modules with 'module list':\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\`\n"
    echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
    echo -e "Now executing a 'module purge' again:\n\n\`\`\`\n "
    module purge 2>&1
    echo -e "\n\`\`\`\n"
    echo -e "List of modules currently loaded (should be almost empty):\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
    echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"

    echo -e "\n\n# Trying an srun...\n\n"
    echo -e "Check if we still now the path to the container via the SIFCCPE environment variable:\n\`${SIFCCPE}\`\n"

    # Note the unexpected name of the next environment variable!
    # We want to export the whole environment that we just built via srun
    echo -e "Before calling \`srun\`, we need to unset \`SLURM_EXPORT_ENV\` to avoid propagation of the \`--export\` option that we used for the batch script.\n"

    unset SLURM_EXPORT_ENV

    echo -e "Now calling srun, excuting a \`module list\`, then print the value of \`CRAY_CC_VERSION\`, then \`module load cce\` and finally print the value of \`CRAY_CC_VERSION\` again."
    echo -e "We would like to to see the small list of modules from above again, then an empty variable and then the CCE version from the container.\n"

    # Note that we want srun to take over the environment we just built.
    echo -e "\n\`\`\`"
    srun -n2 -c1 -t1:00 --label singularity exec $SIFCCPE bash -c \
    'module list 2>&1 ; 
    echo "Before loading cce: CRAY_CC_VERSION=$CRAY_CC_VERSION" ; 
    module load cce ; 
    echo "After loading cce: CRAY_CC_VERSION=$CRAY_CC_VERSION, should be the container version."' \
    | sort -t : -k 1,1n -s
    echo -e "\n\`\`\`\n"
    ```

    The markdown document that it produces when being launched from within the CCPE container is like:

    **Prequel - In batch script but not in the container**

    -   Environment variable `SINGULARITY_BIND`: `/pfs,/users,/projappl,/project,/scratch,/flash,/appl,/opt/cray/pe/lmod/modulefiles/core/rocm/6.0.3.lua,/opt/cray/pe/lmod/modulefiles/core/amd/6.0.3.lua,/opt/rocm-6.0.3,/usr/lib64/pkgconfig/rocm-6.0.3.pc,/opt/cray/libfabric/1.15.2.0,/opt/cray/modulefiles/libfabric,/usr/lib64/libcxi.so.1,/var/spool,/run/cxi,/etc/host.conf,/etc/nsswitch.conf,/etc/resolv.conf,/etc/ssl/openssl.cnf,/etc/cray-pe.d/cray-pe-configuration.sh,/etc/slurm,/usr/bin/sacct,/usr/bin/salloc,/usr/bin/sattach,/usr/bin/sbatch,/usr/bin/sbcast,/usr/bin/scontrol,/usr/bin/sinfo,/usr/bin/squeue,/usr/bin/srun,/usr/lib64/slurm,/var/spool/slurmd,/var/run/munge,/usr/lib64/libmunge.so.2,/usr/lib64/libmunge.so.2.0.0,/usr/include/slurm`.

    -   Environment variable `SIF`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `SIFCCPE`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `CRAY_CC_VERSION`: `17.0.1`. Hope for `17.0.1`, the value in the system environment.

    Do we have any modules loaded? Let's check with `module list`:

    ```

    Currently Loaded Modules:
    1) craype-x86-rome                        8) cray-dsmml/0.3.0
    2) libfabric/1.15.2.0                     9) cray-mpich/8.1.29
    3) craype-network-ofi                    10) cray-libsci/24.03.0
    4) perftools-base/24.03.0                11) PrgEnv-cray/8.5.0
    5) xpmem/2.8.2-1.0_5.1__g84a27a5.shasta  12) ModuleLabel/label   (S)
    6) cce/17.0.1                            13) lumi-tools/24.05    (S)
    7) craype/2.7.31.11                      14) init-lumi/0.2       (S)

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ```

    Let's try a full clean-up saving `SINGULARIT_BIND`, `SIF`and `SIFCCPE`:

    ```


    ```

    Check the variables again:

    -   Environment variable `SINGULARITY_BIND`: `/pfs,/users,/projappl,/project,/scratch,/flash,/appl,/opt/cray/pe/lmod/modulefiles/core/rocm/6.0.3.lua,/opt/cray/pe/lmod/modulefiles/core/amd/6.0.3.lua,/opt/rocm-6.0.3,/usr/lib64/pkgconfig/rocm-6.0.3.pc,/opt/cray/libfabric/1.15.2.0,/opt/cray/modulefiles/libfabric,/usr/lib64/libcxi.so.1,/var/spool,/run/cxi,/etc/host.conf,/etc/nsswitch.conf,/etc/resolv.conf,/etc/ssl/openssl.cnf,/etc/cray-pe.d/cray-pe-configuration.sh,/etc/slurm,/usr/bin/sacct,/usr/bin/salloc,/usr/bin/sattach,/usr/bin/sbatch,/usr/bin/sbcast,/usr/bin/scontrol,/usr/bin/sinfo,/usr/bin/squeue,/usr/bin/srun,/usr/lib64/slurm,/var/spool/slurmd,/var/run/munge,/usr/lib64/libmunge.so.2,/usr/lib64/libmunge.so.2.0.0,/usr/include/slurm`.

    -   Environment variable `SIF`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `SIFCCPE`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `CRAY_CC_VERSION`: ``. If empty then cleaning up worked.

    Now restarting the script in the container...


    **Intermediate: Set up the container environment**
    
    Check the value of `INITCCPE`:
    ```

    if [ "$CCPE_VERSION" != "24.11" ] ;
    then

        lmod_dir="/opt/cray/pe/lmod/lmod" ;
            
        function clear-lmod() { [ -d $HOME/.cache/lmod ] && /bin/rm -rf $HOME/.cache/lmod ; } ;
        
        source /etc/cray-pe.d/cray-pe-configuration.sh ;
        
        source $lmod_dir/init/profile ;
        
        mod_paths="/opt/cray/pe/lmod/modulefiles/core /opt/cray/pe/lmod/modulefiles/craype-targets/default $mpaths /opt/cray/modulefiles /opt/modulefiles" ;
        MODULEPATH="" ;
        for p in $(echo $mod_paths) ; do 
            if [ -d $p ] ; then
                MODULEPATH=$MODULEPATH:$p ;
            fi
        done ;
        export MODULEPATH=${MODULEPATH/:/} ;
        
        LMOD_SYSTEM_DEFAULT_MODULES=$(echo ${init_module_list:-PrgEnv-$default_prgenv} | sed -E "s_[[:space:]]+_:_g") ;
        export LMOD_SYSTEM_DEFAULT_MODULES ;
        eval "source $BASH_ENV && module --initial_load --no_redirect restore" ;
        unset lmod_dir ;
        
    fi ;

    export CCPE_VERSION="24.11"

    ```

    Calling `eval $INITCCPE`:

    ```


    ```
    
    Check the variables again:

    -   Environment variable `SINGULARITY_BIND`: `/pfs,/users,/projappl,/project,/scratch,/flash,/appl,/opt/cray/pe/lmod/modulefiles/core/rocm/6.0.3.lua,/opt/cray/pe/lmod/modulefiles/core/amd/6.0.3.lua,/opt/rocm-6.0.3,/usr/lib64/pkgconfig/rocm-6.0.3.pc,/opt/cray/libfabric/1.15.2.0,/opt/cray/modulefiles/libfabric,/usr/lib64/libcxi.so.1,/var/spool,/run/cxi,/etc/host.conf,/etc/nsswitch.conf,/etc/resolv.conf,/etc/ssl/openssl.cnf,/etc/cray-pe.d/cray-pe-configuration.sh,/etc/slurm,/usr/bin/sacct,/usr/bin/salloc,/usr/bin/sattach,/usr/bin/sbatch,/usr/bin/sbcast,/usr/bin/scontrol,/usr/bin/sinfo,/usr/bin/squeue,/usr/bin/srun,/usr/lib64/slurm,/var/spool/slurmd,/var/run/munge,/usr/lib64/libmunge.so.2,/usr/lib64/libmunge.so.2.0.0,/usr/include/slurm`.

    -   Environment variable `SIF`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `SIFCCPE`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `CRAY_CC_VERSION`: `18.0.1`. Hope for`18.0.1`, the value for 24.11 in the container.



    **Body of the job script - Building and investigating the environment**

    Detected version of the module tool (should be the container one, 8.3.37 for 24.11): 
    ```

    Modules based on Lua: Version 8.7.37  [branch: release/cpe-24.11] 2024-09-24 16:53 +00:00
        by Robert McLay mclay@tacc.utexas.edu
    ```

    List of modules currently loaded (should be the container ones):

    ```

    Currently Loaded Modules:
    1) craype-x86-rome
    2) libfabric/1.15.2.0
    3) craype-network-ofi
    4) perftools-base/24.11.0
    5) xpmem/2.9.6-1.1_20240510205610__g087dc11fc19d
    6) cce/18.0.1
    7) craype/2.7.33
    8) cray-dsmml/0.3.0
    9) cray-mpich/8.1.31
    10) cray-libsci/24.11.0
    11) PrgEnv-cray/8.6.0
    12) ModuleLabel/label                             (S)
    13) lumi-tools/24.05                              (S)
    14) init-lumi/0.2                                 (S)

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ```

    Environment variable CRAY_CC_VERSION: `18.0.1`.

    Now doing a `module unload cce`:

    ```


    Inactive Modules:
    1) cray-libsci     2) cray-mpich


    ```

    Environment variable CRAY_CC_VERSION: ``. This should be empty

    Now executing a 'module purge':

    ```

    The following modules were not unloaded:
    (Use "module --force purge" to unload all):

    1) ModuleLabel/label   2) lumi-tools/24.05   3) init-lumi/0.2

    The following sticky modules could not be reloaded:

    1) lumi-tools

    ```



    Environment variable CRAY_CC_VERSION: ``.

    Now executing `module load cce`':

    ```


    ```

    And listing the modules with 'module list':

    ```

    Currently Loaded Modules:
    1) ModuleLabel/label (S)   3) init-lumi/0.2 (S)
    2) lumi-tools/24.05  (S)   4) cce/18.0.1

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ````



    Environment variable CRAY_CC_VERSION: `18.0.1`.

    Now executing a 'module purge' again:

    ```
    
    The following modules were not unloaded:
    (Use "module --force purge" to unload all):

    1) ModuleLabel/label   2) lumi-tools/24.05   3) init-lumi/0.2

    The following sticky modules could not be reloaded:

    1) lumi-tools

    ```

    List of modules currently loaded (should be almost empty):

    ```

    Currently Loaded Modules:
    1) ModuleLabel/label (S)   2) lumi-tools/24.05 (S)   3) init-lumi/0.2 (S)

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ```



    Environment variable CRAY_CC_VERSION: ``.



    **Trying an srun...**


    Check if we still now the path to the container via the SIFCCPE environment variable:
    `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`

    Before calling `srun`, we need to unset `SLURM_EXPORT_ENV` to avoid propagation of the `--export` option that we used for the batch script.

    Now calling srun, excuting a `module list`, then print the value of `CRAY_CC_VERSION`, then `module load cce` and finally print the value of `CRAY_CC_VERSION` again.
    We would like to to see the small list of modules from above again, then an empty variable and then the CCE version from the container.


    ```
    0: 
    0: Currently Loaded Modules:
    0:   1) ModuleLabel/label (S)   2) lumi-tools/24.05 (S)   3) init-lumi/0.2 (S)
    0: 
    0:   Where:
    0:    S:  Module is Sticky, requires --force to unload or purge
    0: Before loading cce: CRAY_CC_VERSION=
    0: After loading cce: CRAY_CC_VERSION=18.0.1, should be the container version.
    1: 
    1: Currently Loaded Modules:
    1:   1) ModuleLabel/label (S)   2) lumi-tools/24.05 (S)   3) init-lumi/0.2 (S)
    1: 
    1:   Where:
    1:    S:  Module is Sticky, requires --force to unload or purge
    1: Before loading cce: CRAY_CC_VERSION=
    1: After loading cce: CRAY_CC_VERSION=18.0.1, should be the container version.

    ```





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

-   The container that has been provided by LUST as a starting point, does
    have some protection built in to prevent it being taken to other systems.
    One element of that protection, is some checks of the `/etc/slurm/slurm.conf`
    file. 

    To be able to use the `%post` section during the "unpriveleged proot build"
    process, that file has to be present in the container. Therefore we copy that
    file in the `%files` phase, but remove it again in the `%post` phase as whe
    running the container, the whole Slurm configuration directory is bind mounted
    in the container.

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
