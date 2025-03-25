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

    **TODO: This example is broken and needs to be reworked. Some commands execute in a subshell explaining why the results are wrong.**)

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

    which returns version 8.7.37 and list the modules:

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

    now returns version 8.7.32, as we are no longer in the container but in a regular LUMI
    environment. 

    Trying

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

    so the moduled we were using in the container.

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

    With `sbatch` the situation looks stranger and Lmod seems to be completely broken: Launching the job
    script

    ```bash
    #!/bin/bash
    #SBATCH -p small
    #SBATCH -n 1
    #SBATCH -c 1
    #SBATCH -t 5:00
    # And add line for account

    echo -e "Detected version of the module tool: $(module --version 2>&1)\n"
    echo -e "List of modules currently loaded:\n$(module list 2>&1)\n"
    echo -e "Environment variable CRAY_CC_VERSION: ${CRAY_CC_VERSION}\n"
    echo -e "Now executing a 'module purge':\n\n$(module purge 2>&1)\n"
    echo -e "\n\nEnvironment variable CRAY_CC_VERSION: ${CRAY_CC_VERSION}\n"
    echo -e "Now exeucting 'module load cce':\n$(module load cce 2>&1)\n"
    echo -e "And listing the modules with 'module list':\n$(module list 2>&1)\n"
    echo -e "\n\nEnvironment variable CRAY_CC_VERSION: ${CRAY_CC_VERSION}\n"
    echo -e "Now executing a 'module purge' again:\n\n$(module purge 2>&1)\n"
    echo -e "\n\nEnvironment variable CRAY_CC_VERSION: ${CRAY_CC_VERSION}\n"
    echo -e "But check if we still now the path to the container via the SIFCCPE environment variable:\n${SIFCCPE}"
    ```

    with `sbatch` from within the container,
    returns in the output file:

    ``` linenums="1"
    Detected version of the module tool: 
    Modules based on Lua: Version 8.7.32  2023-08-28 12:42 -05:00
        by Robert McLay mclay@tacc.utexas.edu

    List of modules currently loaded:

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

    Environment variable CRAY_CC_VERSION: 18.0.1

    Now executing a 'module purge':

    The following modules were not unloaded:
    (Use "module --force purge" to unload all):

    1) ModuleLabel/label   2) lumi-tools/24.05   3) init-lumi/0.2

    The following sticky modules could not be reloaded:

    1) lumi-tools



    Environment variable CRAY_CC_VERSION: 18.0.1

    Now exeucting 'module load cce':

    The following have been reloaded with a version change:
    1) PrgEnv-cray/8.6.0 => PrgEnv-cray/8.5.0
    2) cce/18.0.1 => cce/17.0.1
    3) cray-libsci/24.11.0 => cray-libsci/24.03.0
    4) cray-mpich/8.1.31 => cray-mpich/8.1.29
    5) craype/2.7.33 => craype/2.7.31.11
    6) perftools-base/24.11.0 => perftools-base/24.03.0
    7) xpmem/2.9.6-1.1_20240510205610__g087dc11fc19d => xpmem/2.8.2-1.0_5.1__g84a27a5.shasta

    And listing the modules with 'module list':

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



    Environment variable CRAY_CC_VERSION: 18.0.1

    Now executing a 'module purge' again:

    The following modules were not unloaded:
    (Use "module --force purge" to unload all):

    1) ModuleLabel/label   2) lumi-tools/24.05   3) init-lumi/0.2

    The following sticky modules could not be reloaded:

    1) lumi-tools



    Environment variable CRAY_CC_VERSION: 18.0.1

    But check if we still now the path to the container via the SIFCCPE environment variable:
    /users/kurtlust/LUMI-user/SW/container/ccpe/24.11-raw/cpe_2411.sif
    ```

    The initial output looks a lot like what we got from the interactive session, but
    from line 43 on, the output starts to differ. Line 45 to 52 suggest that we did
    indeed load `cce/17.0.1`, the default `cce` version on the system, and that several
    other corresponding modules were reloaded.

    However, the output of `module list` on lines 56 to 73, tells a different story.

    It is clear that Lmod, by inheriting the environment from the container in which 
    we called sbatch, is completely broken. This should not surprise us. Unloading a module
    correctly requires the module file to be present, and the first `module purge` did not
    have access to the module files from the HPE Cray PE in the container.

    **Morale of the story: Don't mess with Lmod if you inherit an environment from within
    a container!**

**TODO:** I was hoping that something along the lines of

```bash
#!/bin/bash
#SBATCH -p small
#SBATCH -n 1
#SBATCH -c 1
#SBATCH -t 5:00
# And add line for account

if [ -d "/.singularity.d" ]
then

	echo -e "Detected version of the module tool: $(module --version 2>&1)\n"
	echo -e "List of modules currently loaded:\n$(module list 2>&1)\n"
	echo -e "Environment variable CRAY_CC_VERSION: ${CRAY_CC_VERSION}\n"
	echo -e "Now executing a 'module purge':\n\n$(module purge 2>&1)\n"
	echo -e "\n\nEnvironment variable CRAY_CC_VERSION: ${CRAY_CC_VERSION}\n"
	echo -e "Now exeucting 'module load cce':\n$(module load cce 2>&1)\n"
	echo -e "And listing the modules with 'module list':\n$(module list 2>&1)\n"
	echo -e "\n\nEnvironment variable CRAY_CC_VERSION: ${CRAY_CC_VERSION}\n"
	echo -e "Now executing a 'module purge' again:\n\n$(module purge 2>&1)\n"
	echo -e "\n\nEnvironment variable CRAY_CC_VERSION: ${CRAY_CC_VERSION}\n"
	echo -e "But check if we still now the path to the container via the SIFCCPE environment variable:\n${SIFCCPE}"

else

    exec singularity exec $SIFCCPE $0  
    
fi
```

would work. But though we see the environment from which `sbatch` was called now again and all the `echo` 
commands clearly run in the container, Lmod still fails to unload modules as it should.


## Known restrictions    

-   We do already mount the Slurm tools in the container. However, they do not yet
    function and it is not clear if this is fixeable.
    
-   `PrgEnv-aocc` is not provided by the container. The ROCm version is taken from the
    system and may not be the optimal one for the version of the PE.
