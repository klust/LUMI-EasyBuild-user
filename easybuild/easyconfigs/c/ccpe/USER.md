# User instructions for the HPE CPE containers.

!!! Warning "These containers are beta software"
    They are made available by HPE without guarantee of suitability for your
    purpose, as a way for users to test programming environments that are not
    (yet) on the system. 
    
    LUST together with HPE have made modules and implemented changes to the 
    containers to adapt them to LUMI and integrate somewhat in the regular 
    environment.
    
    However, working with these containers is different from working with a 
    programming environment that is installed natively on the system and requires
    a good insight in how containers work. So they are not for every user, and
    LUST can only offer very limited support. These containers are only for 
    users who are very experienced with the Cray Programming Environment and also
    understand how singularity containers work.
    
    The container only offers `PrgEnv-cray` and `PrgEnv-gnu`. 
    With some imports from the system, we also offer `PrgEnv-amd`, but it
    may not be entirely as intended by the version of the PE as we may be 
    using a different version of ROCm. The container does contain some
    elements of `PrgEnv-nvidia` but that is obviously not functional on LUMI.
    `PrgEnv-aocc` is not available.
    
    HPE has a community Slack channel for feedback and questions at
    [slack.hpdev.io](https://slack/hpdev.io/), channel `#hpe-cray-programming-environment`,
    but bear in mind that this is mostly a community channel, monitored
    by some developers, but those developers don't have time to answer each and
    every question themselves. It is a low volume channel and in no means
    a support channel for inexperienced users.


## How to enable the containers?

We recommend using our EasyBuild modules to run the HPE CPE containers
as these modules do create a lot of bind mounts to provide all necessary
parts from the system to the container.

All modules provide a number of environment variables to make life easier:

-   Outside the container, `SIF` and `SIFCCPE` point to the container file,
    which is very handy to use with the `singularity` command.
    
-   Inside the container, `INITCCPE` contains the commands to fully initialise
    the CPE in the container. Use as `eval $INITCCPE`.
    
    This is not needed when using `singularity run` or the corresponding wrapper script.

The module also provides access to four wrapper scripts to start the container.
Note though that those wrapper scripts only function properly when the module
is loaded. They do not take care of the bindings themselves and in that sense
are certainly different from the wrapper scripts provided by Tykky/lumi-container-wrapper.
All these scripts do however purge all modules before going into the container,
as modules from the system PE are not valid in the container, and fully clear Lmod.
Currently, the following scripts are provided:

-   `ccpe-shell` to start a shell in the container. The arguments of `ccpe-shell`
    are simply added to the `singularity shell $SIF`.
    
-   `ccpe-exec` to run a command in the container. The arguments of `ccpe-exec` 
    are simply added to the `singularity exec $SIF` command.
    
-   `ccpe-run` to run the container. The arguments of `ccpe-run`
    are simply added to the `singularity run $SIF` command.
    
-   `ccpe-singularity` will clean up the environment for the singularity, then
    call `singularity` passing all arguments to `singularity`. So with this 
    command, you still need to specify the container also (e.g., using the 
    `SIF` or `SIFCCPE` environment variable), but can specify options for 
    the singularity subcommand also.


## How to get a proper environment in the container?

Unfortunately, there seems to be no way to properly (re-)initialise the shell 
or environment in the container directly through `singularity shell` or 
`singularity exec`.

The following strategies can be used:

-   In the container, the environment variable `INITCCPE` contains the necessary
    commands to get a working Lmod environment again, but then with the relevant
    CPE modules for the container. Run as
    
    ```
    eval $INITCCPE
    ```
    
-   Alternatively, sourcing `/etc/bash.bashrc` will also properly set up Lmod.

Cases that do give you a properly initiated shell, are `singularity exec bash -i` 
and `singularity run`. These commands do source `/etc/bash.bashrc` but do not 
read `/etc/profile`. But the latter shouldn't matter too much as that is usually
used to set environment variables, and those that are typically set in that file
and the files it calls, are typically fine for the container, or overwritten anyway
by the files sourced by `/etc/bash.bashrc`.


## Launching jobs: A tale of two environments

The problem with running jobs, is that they have to deal with two incompatible
environments:

1.  The environment outside the container that does not know about the HPE Cray
    PE modules of the PE version in the container, and may not know about some other
    modules depending on how `/appl/lumi` is set up.
    
    *TODO: We may consider pre-installing modules in an alternative for `/appl/lumi`
    but mount that as `/appl/lumi` in the container. This would make it easier for
    LUST to support the same container with different ROCm versions.*
    
2.  The environment inside the container that does not know about the HPE Cray PE
    modules installed in the system, and may not know abvout some other 
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

??? Example "See how broken the job environment can be..."

    *This example is developed running a container for the 24.11 programming environment
    on LUMI in March 2025 with the 24.03 programming environment as the default.*

    The 24.03 environment comes with `cce/17.0.1` while the 24.11 environment comes with
    `cce/18.0.1`. When loading the module, it sets the environment variable 'CRAY_CC_VERSION'
    to the version of the CCE compiler.

    Start up the container:

    ```bash
    ccpe-run
    ```

    Check the version of the module tool:

    ```bash
    module --version
    ```

    which returns version 8.7.37:

    ```
    Modules based on Lua: Version 8.7.37  [branch: release/cpe-24.11] 2024-09-24 16:53 +00:00
        by Robert McLay mclay@tacc.utexas.edu    
    ```
    
    and list the modules:

    ```bash
    module list
    ```

    returns

    ```
    Currently Loaded Modules:
    1) craype-x86-rome                                 6) cce/18.0.1           11) PrgEnv-cray/8.6.0
    2) libfabric/1.15.2.0                              7) craype/2.7.33        12) ModuleLabel/label (S)
    3) craype-network-ofi                              8) cray-dsmml/0.3.0     13) lumi-tools/24.05  (S)
    4) perftools-base/24.11.0                          9) cray-mpich/8.1.31    14) init-lumi/0.2     (S)
    5) xpmem/2.9.6-1.1_20240510205610__g087dc11fc19d  10) cray-libsci/24.11.0

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ```

    so we start with the Cray programming environment loaded.

    Now use an interactive `srun` session to start a session on the compute node.

    ```bash
    srun -n1 -c1 -t10:00 -psmall -A<my_account> --pty bash
    ```

    Let's check the version of the module tool again:

    ```bash
    module --version
    ```

    now returns version 8.7.32: 
    
    ```
    Modules based on Lua: Version 8.7.32  2023-08-28 12:42 -05:00
        by Robert McLay mclay@tacc.utexas.edu
    ```
    
    as we are no longer in the container but in a regular LUMI environment. 

    Trying

    ```bash
    module list
    ```

    returns

    ```
    Currently Loaded Modules:
    6) craype-x86-rome                                 6) cce/18.0.1           11) PrgEnv-cray/8.6.0
    7) libfabric/1.15.2.0                              7) craype/2.7.33        12) ModuleLabel/label (S)
    8) craype-network-ofi                              8) cray-dsmml/0.3.0     13) lumi-tools/24.05  (S)
    9) perftools-base/24.11.0                          9) cray-mpich/8.1.31    14) init-lumi/0.2     (S)
    10) xpmem/2.9.6-1.1_20240510205610__g087dc11fc19d  10) cray-libsci/24.11.0

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ```

    so the modules we were using in the container.

    The environment variable `CRAY_CC_VERSION` is also set:

    ```bash
    echo $CRAY_CC_VERSION
    ```

    returns `18.0.1`.

    Now do a

    ```bash
    module purge
    ```

    which shows the perfectly normal output

    ```
    The following modules were not unloaded:
    (Use "module --force purge" to unload all):

    1) ModuleLabel/label   2) lumi-tools/24.05   3) init-lumi/0.2

    The following sticky modules could not be reloaded:

    1) lumi-tools
    ```

    and 

    ```bash
    module list
    ```

    now shows

    ```
    Currently Loaded Modules:
    1) ModuleLabel/label (S)   2) lumi-tools/24.05 (S)   3) init-lumi/0.2 (S)

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ```

    but 

    ```bash
    echo $CRAY_CC_VERSION
    ```

    still return `18.0.1`, so even though it appears that the `cce/18.0.1` module has been unloaded,
    not all (if any) environment variables set by the module, have been correctly unset. 

    We can now load the `cce` module again:

    ```bash
    module load cce
    ```

    and now

    ```bash
    module list cce
    ```

    returns

    ```
    Currently Loaded Modules Matching: cce
    1) cce/17.0.1
    ```

    so it appears we have the `cce` module from the system. This went well in this case. And in fact,

    ```bash
    module list
    ```

    which returns

    ```
    Currently Loaded Modules:
    1) ModuleLabel/label (S)   4) craype/2.7.31.11     7) craype-network-ofi   10) PrgEnv-cray/8.5.0
    2) lumi-tools/24.05  (S)   5) cray-dsmml/0.3.0     8) cray-mpich/8.1.29    11) cce/17.0.1
    3) init-lumi/0.2     (S)   6) libfabric/1.15.2.0   9) cray-libsci/24.03.0

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ```

    suggests that some other modules, like `cray-mpich` and `cray-libsci` have also been reloaded.

    ```bash
    echo $CRAY_CC_VERSION
    ```

    returns `17.0.1` as expected, and after

    ```bash
    module purge
    ```

    we now note that

    ```bash
    echo $CRAY_CC_VERSION
    ```

    returns nothing and is reset.

    However, it is clear that we are now in an environment where we cannot use what we prepared in the
    container.
    

### Example job script 1: Run the job script itself in the container

To make writing job scripts easier, some common code has been put in an
environment variable that can be executed via the `eval` function of bash.
 
This job script will start with as clean an environment as possible, except when called
from a correctly initialised container with passing of the full environment:
 
<!-- One space indent needed as this goes through a too simple script that will
     replace a # in the first column. -->
   
 ``` bash linenums="1"
 #!/bin/bash
 #
 # This test script should be submitted with sbatch from within a CPE 24.11 container.
 # It shows very strange behaviour as the `module load` of some modules fails to show
 # those in `module list` and also fails to change variables that should be changed.
 #
 #SBATCH -J example-jobscript
 #SBATCH -p small
 #SBATCH -n 1
 #SBATCH -c 1
 #SBATCH -t 5:00
 #SBATCH -o %x-%j.md
 # And add line for account
 
 #
 # Ensure that the environment variable SWITCHTOCCPE and with it 
 #
 if [ -z "${SWITCHTOCCPE}" ]
 then
     module load CrayEnv ccpe/24.11-LUMI || exit
 fi
 
 #
 # Now switch to the container and clean up environments when needed and possible.
 #
 eval $SWITCHTOCCPE
 
 #
 # Here you have the container environment and can simply work as you would normally do:
 # Build your environment and start commands. But you'll still have to be careful with
 # srun as whatever you start with srun will not automatically run in the container.
 #
 
 module list

 ``` 

What this job script does:

-   The body of the job script (lines after `eval $SWITCHTOCCPE`) will always run in the container.

-   When launching this batch script from within the container:

    -   When launched using `sbatch --export=$EXPORTCCPE`, the body will run in a clean container environment.

    -   When launched with `--export` flag, the body will run in the environment of the calling container.

        This behaviour requires that the environment variable `CCPE_VERSION` is set to the value that belongs
        to this version of the container. This is something what would have been done during the initialisation
        of the container from which `sbatch` was called, at least if that one was fully initialised either by
        the startup scripts or by doing an `eval $INITCCPE`.

    -   Behaviour with `--export=none`: As the container cannot be located, 
        
        ``` bash
        if [ -z "${SWITCHTOCCPE}" ]
        then
            module load CrayEnv ccpe/24.11-LUMI || exit
        fi
        ```

        will first try to load the container module, and if successful, proceed creating a clean environment.

-   When launching this batch script from a regular system shell:

    -   When launched using `sbatch --export=$EXPORTCCPE`, the body will run in a clean container environment.

    -   When launched with `--export` flag, `eval $SWITCHTOCCPE` will first try to clean the system
        environment (and may fail during that phase if it cannot find the modules that you had loaded
        when calling `sbatch`.)

        If the `ccpe` module was not loaded when calling the job script, the block 
        
        ``` bash
        if [ -z "${SWITCHTOCCPE}" ]
        then
            module load CrayEnv ccpe/24.11-LUMI || exit
        fi
        ```

        will try to take care of that. If the module can be loaded, the script will proceed with building
        a clean container environment.

    -   Behaviour with `--export=none`: As the container cannot be located, 
        
        ``` bash
        if [ -z "${SWITCHTOCCPE}" ]
        then
            module load CrayEnv ccpe/24.11-LUMI || exit
        fi
        ```

        will first try to load the container module, and if successful, proceed creating a clean environment.

        **TODO** check if this works!

-   So in all cases you get a clean environment (which is the only logical thing to get) *except*
    if `sbatch` was already called from within the container without `--export` flag.

??? Note "Technical notes about the above job script"

    Line 18-21 ensure that the environment variable `SWITCHTOCCPE` is set. We assume that 
    other environment variables set by the container modules will also be set (and hence 
    have been forwarded to the job script) but currently do not test for those. If the variable
    is not set, the script will try to load the module. This only works if `EBU_USER_PREFIX`
    is set properly in the script, or if the module is installed in the default location (which
    is nearly impossible due to the size of the package, but one could still use a symbolic link for 
    the default location to a different file system with sufficient block quota). The `|| exit` 
    ensures that we exit the job script if the `module load` fails, as the job script would fail
    anyway.

    The `eval $SWITCHTOCCPE` is where most of the magic happens. It executes the commands

    ```bash linenums="1"
    if [ ! -d "/.singularity.d" ] ;
    then

        if [ "$CCPE_VERSION" != "24.11" ] ;
        then
        
            for var in ${{EXPORTCCPE//,/ }} ;
            do
                eval $(declare -p $var | sed -e "s/$var/save_$var/") ;
            done ;
        
            module --force purge ;
            eval $($LMOD_DIR/clearLMOD_cmd --shell bash --full --quiet) ;
            unset LUMI_INIT_FIRST_LOAD ;
            unset PROFILEREAD ;
        
            for var in ${{save_EXPORTCCPE//,/ }} ;
            do
                varname="save_$var" ;
                eval $(declare -p $varname | sed -e "s/save_$var/$var/") ;
                unset $varname ;
            done ;
            
        fi ;

        exec singularity exec "$SIFCCPE" "$0" "$@" ;

    fi ;

    eval $INITCCPE ;
    ```

    The first block (lines 1-28) of the code for `eval $SWITCHTOCCPE` is only executed if not in the 
    context of the container. If it does not detect an environment from the container (the test on line 4)
    then 
    
    -   it saves some environment variables set by the CCPE modules that should not be erased,  

    -   purges all currently loaded modules which hopefully are from the system environment as otherwise 
        variables may not be unset,

    -   clears Lmod to that all Lmod data structures are removed,
  
    -   and then restores the environment variables from the `ccpe` module as they have been erased by
        the `module purge`.

    Finally, it restarts the batch script with all its arguments in the container. This causes the batch
    script to execute again from the start, but as `SWITCHTOCCPE` should be defined when we get here, and
    since we will now be in the container, all code discussed so far will be skipped.

    The second block of the code for `eval $SWITCHTOCCPE`, basically just the statement `eval $INITCCPE`
    will then be executed in the container. This expands to:

    ```bash linenums="1"
    if [ "$CCPE_VERSION" != "24.11" ] ;
    then

        lmod_dir="/opt/cray/pe/lmod/lmod" ;
            
        function clear-lmod() { [ -d $HOME/.cache/lmod ] && /bin/rm -rf $HOME/.cache/lmod ; } ;
        
        source /etc/cray-pe.d/cray-pe-configuration.sh ;
        
        source $lmod_dir/init/profile ;
        
        mod_paths="/opt/cray/pe/lmod/modulefiles/core /opt/cray/pe/lmod/modulefiles/craype-targets/default $mpaths /opt/cray/modulefiles /opt/modulefiles" ;
        MODULEPATH="" ;
        for p in $(echo $mod_paths) ;
        do 
            if [ -d $p ] ; 
            then
                MODULEPATH=$MODULEPATH:$p ;
            fi ;
        done ;
        export MODULEPATH=${MODULEPATH/:/} ;
        
        LMOD_SYSTEM_DEFAULT_MODULES=$(echo ${init_module_list:-PrgEnv-$default_prgenv} | sed -E "s_[[:space:]]+_:_g") ;
        export LMOD_SYSTEM_DEFAULT_MODULES ;
        eval "source $BASH_ENV && module --initial_load --no_redirect restore" ;
        unset lmod_dir ;

        export CCPE_VERSION="%(version)s" ;
        
    fi ;
    ```

    So if the code detects that there is already a valid environment for the container
    (where we again simply test for the value of `CCPE_VERSION`), nothing more is done,
    but if there is no proper environment, the remaining part of this routine basically
    runs the code used on LUMI to initialise Lmod with the proper modules from the HPE
    Cray Programming Environment, but now in the container. As it is done in the container, 
    you will get the programming environment from the container.

    The remainder of the job script is then executed in the container.

    One needs to be careful though when starting job steps through `srun`. These will inherit the
    environment from the container, but will start again outside the container, so each job
    step will have to start singularity again in the same way as other jobs that use containers
    for job steps.



## Next steps:

-   Build MPI tools to better document how to start such jobs, with a proper example
    in these notes.

-   To what extent can we get the same effect from the version that makes no changes
    to the container except for those needed to get Slurm working?    


## Known restrictions    

-   `PrgEnv-aocc` is not provided by the container. The ROCm version is taken from the
    system and may not be the optimal one for the version of the PE.
