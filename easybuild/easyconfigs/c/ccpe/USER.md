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




!!! Example "Job script to use with the CCPE containers"

    ``` bash
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
    
        save_SIF="$SIF"
        save_SIFCCPE="$SIFCCPE"
        save_BIND="$SINGULARITY_BIND"
        
        module --force purge
        eval $($LMOD_DIR/clearLMOD_cmd --shell bash --full --quiet)
        unset LUMI_INIT_FIRST_LOAD
        # Make sure that /etc/profile does not quit immediately when called.
        unset PROFILEREAD
        
        export SIF="$save_SIF"
        export SIFCCPE="$save_SIFCCPE"
        export SINGULARITY_BIND="$save_BIND"
        
        exec singularity exec "$SIFCCPE" "$0" "$@"
        
    else

        # Now we're in the container, so initialise properly.
        eval $INITCCPE

    fi

    #
    # Here you have the container environment and can simply work as you would normally do:
    # Build your environment and start commands. But you'll still have to be careful with
    # srun as whatever you start with srun will not automatically run in the container.
    #

    module list

    ``` 

## Next steps:

-   Should we set `SBATCH_EXPORT` and maybe some variants in the module, as the variables that
    need to be exported may evolve over time?

-   Create an environment variable `SWITCHTOCCPE` in the module that contains the commands for the initialisation,
    to switch to executing in a container.

Scenarios

1.  Job launched from the container and we want to execute the job script in the container:

    a.  Clean environment: Use `eval $SWITCHTOCCPE` and `--export=$EXPORTCCPE`. Then rebuild the
        desired environment. This gives a rather robust script as the environment from which the
        script was called, does not influence what happens in the job.
    
    b.  **TODO**: Inheriting the environment: Need to look at it further, but something along 
        the lines of

        ``` bash
        if [ ! -d "/.singularity.d" ]
        then
            exec singularity exec "$SIFCCPE" "$0" "$@"
        fi
        ```
        
        at the start of the jobscript may be all we need. Not sure though if, e.g., the module 
        function would be defined.

2.  Job launched from the system environment, want to execute the job script in the 
    container: Need to clean up before activating singularity, and then build a proper environment 
    in the container. We do however need to find our container and bind mounts, so 
    some environment variables should be preserved, and the container module should be loaded
    if it was not in the system environment environment.
    
    As the job script executing starts in the system environment, we can do the clean-up 
    at the start of the job script instead of by using `--export=NONE` or so, but if the 
    job script would accidentally be launched from the container, the clean-up would 
    not have the expected results.

3.  Job launched from the container, but want to deliberately execute the job script 
    in the system shell either because we only want to run tools in the system environment or
    because we fully want to rebuild in the job script before executing job steps in 
    a container with `srun`: Need to clean up before entering the job script, so we should
    not export the environment. 

4.  Job launched from the system and want to execute the job script in the system: 
    This is the usual case...
    
    
    
## Known restrictions    

-   `PrgEnv-aocc` is not provided by the container. The ROCm version is taken from the
    system and may not be the optimal one for the version of the PE.
