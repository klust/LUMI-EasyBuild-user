# User information for EESSI-setup

!!! Warning "Very experimental module"
    The `EESSI-setup` module is currently considered very experimental and is also
    hard to support.

    -   Issues caused by the module itself should be sorted out by the LUMI User Support
        Team (LUST) who developed this module.
    -   However, LUST does not develop EESSI, and any EESSI-specific issue can only be dealt
        with by [the help desk of the EuroHPC Federation Platform (EFP)](https://docs.my-eurohpc.eu/support/).

    It is not always clear though what is the cause of an issue, so there may be some bouncing
    back and forth between help desks.

    LUST is also not responsible for performance issues with EESSI or any issues with its MPI
    implementations. EESSI does not follow all best practices for working on HPE Cray EX machines 
    in general and LUMI in particular and this may lead to restrictions that are not present on
    all other machines or loss of performance (or scalability) of applications. 


## What is EESSI?

[EESSI](https://www.eessi.io/) is an effort to build a software stack that works in the same way on all computers.
For this it also builds upon [EasyBuild](https://easybuild.io/).

EESSI is also the basis for the [Federated Software Catalog (FSC) of the EuroHPC Federation Platform (EFP)](https://docs.my-eurohpc.eu/software-catalog/overview/) and this is also the prime base of information about running EESSI on LUMI.

One feature of EESSI is that it tends to be distributed via CernVM-FS, but there are multiple technical reasons to not
offer EESSI that way on LUMI. EESSI is instead offered through mounted images on most of the compute nodes of LUMI,
and that image is synchronised with the central EESSI repository once a day. This also leads to some
[special instructions to use EESSI on LUMI](https://docs.my-eurohpc.eu/software-catalog/system-specific/lumi/).
Some other very large systems also follow a strategy with periodic synchronisation rather than using
CernVM-FS on all the compute nodes.

Apart from the [EFP documentation](https://docs.my-eurohpc.eu/software-catalog/overview/),
more documentation is available from the EESSI project itself:

-   [EESSI documentation](https://www.eessi.io/docs/) on the 
    [EESSI web site](https://www.eessi.io/). This documentation is currently a mix of
    topics for regular users and topics for sysadmins, though the latter are also useful
    if, e.g., you want to have the EESSI software stack also on your Mac or Windows 
    laptop or workstation.

-   There are [weekly EESSI Happy Hour sessions](https://www.eessi.io/docs/training-events/happy-hours-sessions/).
    Each week, focus is on a particular EESSI-related topic, but there is also plenty of time 
    afterwards to ask other questions.

It is also possible to install additional software on top of EESSI at the site level, at the project
level, and at the user level. There are currently no plans by LUST to provide a site-wide stack built
on top of EESSI though, so some tools that you may be used to on LUMI, e.g., for checking MPI task
mapping, are not available in the EESSI environment. 


## What is EESSI-setup?

`EESSI-setup` is a module that tries to make work with a specific release of EESSI (the version of
the module) a bit easier on LUMI. It sets a number of useful environment variables and provides a 
proper container to run EESSI on nodes where it is not available (such as the login nodes) with
limited Slurm support also.


## How to get EESSI-setup?

Due to its very experimental nature, `EESSI-setup` is not installed in the central software stack
as updates there are too painful and as the module cannot be fully supported. It falls in the category
of user-installable software, documented in the LUMI documentation on the 
["EasyBuild" page](https://docs.lumi-supercomputer.eu/software/installing/easybuild/) in the
["Software" section](https://docs.lumi-supercomputer.eu/software/installing/easybuild/).

To install:
```
module load LUMI partition/container EasyBuild-user
eb EESSI-ssetup-2025.06.eb
```
(or whatever the name of the EasyConfig is that you want to install, see further down this page
for a list of available EasyConfigs).

You may not want to do this in your home directory but in the project directory instead, following
the instructions in the  
["Beginner's guide to installing software on LUMI"](https://docs.lumi-supercomputer.eu/software/installing/easybuild/#beginners-guide-to-installing-software-on-lumi)
to select the installation location through the `EBU_USER_PREFIX` environment variable.


## Functionality provided by the module

The module provides several commands and sets several environment variables to make 
working with EESSI on LUMI easier, in particular on nodes where a container is 
needed. During the installation, the installation process will also build a relatively
small container capable of running EESSI, but also providing support for some Slurm
commands.


### Commands and functions

-   `eessi-init` bash function
  
    -   On a compute node with EESSI enabled, it will source the 
        `/cvmfs/software.eessi.io/versions/<version>/init/lmod/bash` script.
    
    -   If EESSI cannot be found, it will print a warning and return a non-zero 
        exit code. There are different error messages, depending on whether EESSI
        cannot be found at all, the right version of EESSI is not available, or
        the initialisation script is somehow missing (pointing at a broken EESSI
        installation).

-   `eessi-shell`: Basically a `singularity shell` wrapper that starts a new 
    bash shell with EESSI enabled and initialised if EESSI is not available, 
    but will not use a container if EESSI is found on the node.

    -   If EESSI is installed on the node: Starts a new EESSI bash shell with EESSI
        initialised.
        
        Command line arguments will used as the command line arguments for the 
        EESSI bash command that is called after the initialisation.

    -   If EESSI is not installed on the node: It will start a singularity container
        with EESSI initialised.

        It will currently ignore command line arguments passed to it due to singularity
        restrictions. Use `eessi-run` instead (discussed below) if you want to pass
        command line arguments to the bash shell command.

-   `eessi-exec`: Basically a `singularity exec` wrapper that runs a command in
    a container with EESSI enabled and initialised if EESSI is not available, 
    but will not use a container if EESSI is found on the node.

    -   If EESSI is installed on the node: Runs the command (arguments of 
        `eessi-exec`) in an initialised EESSI bash shell. (Initialised meaning
        that the EESSI initialisation script has been called.)

        The command line arguments are run through an EESSI bash shell started
        with -c and passing it the commands. There may be some differences with 
        how the command reacts when using a container apart from the different
        environment (native versus container).

    -   If EESSI is not installed on the node: It will execute the command with 
        `singularity exec` in a singularity container with EESSI initialised.

-   `eessi-run`: Basically a `singularity run` wrapper that again runs an EESSI bash
    shell, passing all command line arguments to it, in a container with 
    EESSI enabled and initialised if EESSI is not available, 
    but will not use a container if EESSI is found on the node.

    -   If EESSI is installed on the node: Runs EESSI bash with the given command line
        arguments in an environment with EESSI properly initialised.

    -   If EESSI is not installed on the node: It calls `singularity run` with the
        given command line arguments in a container with EESSI mounted and initialised.

        The action os `singularity run` is to initialise EESSI and call EESSI bash with
        all arguments provided.

All commands try to do a reasonable thing both when EESSI is available and when EESSI is
not available on the node, though `eessi-init` is meant to be used on compute nodes with 
EESSI available but not correctly initialised yet, while the other commands are really 
meant to be used on nodes without EESSI such as the LUMI login nodes where a container 
setup is needed. These commands are really meant to make life easier than the 
[approach described in "Access on login nodes" in the LUMI-specific instructions in the EFP docs](https://docs.my-eurohpc.eu/software-catalog/system-specific/lumi/#access-on-login-nodes).

Compared to that approach, working with the module provides

-   Faster access to the container as it doesn't need to be pulled in every time (though
    that could be easily solved)

-   Some additional software in the Ubuntu container so that some Slurm commands can also
    be mounted in the container (and some are mounted by the default bindings set by 
    the module).

Even though it is easy to call singularity directly with the environment variables
that are set by the module, this is not recommended as once in the container, the LUMI 
environment cannot be properly cleaned up as the modulefiles from LUMI are not available
in the container. So all modules that are loaded before the EESSI initialisation (which
is run automatically when entering the container) will appear unloaded, but the
environment variables they set will not be unset, and the PATH-style environment variables
will not be correctly adjusted. LMOD needs access to the modulefiles to do so. The wrapper
scripts take care of this by unloading the modules before entering the container while
ensuring that those environment variables that are set by this module and are useful in
the container, remain set.


### Environment variables

-   The module will set `SBATCH_CONSTRAINT`, `SALLOC_CONSTRAINT` and `SLURM_CONSTRAINT`
    to ensure that jobs started with the module loaded will allocate EESSI-enabled nodes.
    With the module loaded, it is not needed to specify `--constraint=eessi` as the 
    environment variables do so automatically for respectively the `sbatch`, `salloc` and
    `srun` command.

-   It currently also sets `SBATCH_NETWORK`, `SALLOC_NETWORK` and `SRUN_NETWORK` to
    `single_node_vni,job_vni,def_tles=0` which is recommended in the [MPI example in 
    the LUMI-specific page of the FSC documentation in the EFP documentation](https://docs.my-eurohpc.eu/software-catalog/system-specific/lumi/#multi-node-jobs).

    Hence it is not needed anymore to specify `--network=single_node_vni,job_vni,def_tles=0` as in that example.

    Note that if you want to change the value of `--network`, you will have to unset those
    environment variables if you want to do it through the batch script, as environment
    variables take priority over lines in the batch script (but command line arugments
    overwrite the environment variables).

-   The environment variables `SIF` and `SIFEESSI` point to the location (full path
    and filename) of the EESSI container and can be used if you want to use singularity
    commands directly.

    Be aware though that running the EESSI initialisation script in the container
    cannot properly unload all modules that are loaded, as the module files themselves
    for those modules are not available in the container. The modules will be unloaded,
    but environment variables will not be unset or PATH-style environment variables
    will not be properly adjusted. This is the whole reason to use the various
    `eessi-*` wrappers as they take care of properly cleaning up the environment
    before entering the container.

-   `SINGULARITY_BINDPATH` is set so that:

    -   All LUMI user and project filesystems are available in the usual way.

    -   The main Slurm commands are mounted.

        Currently available: `sacct`, `sbatch`, `sinfo`, `squeue`, `srun` and `sstat`.

        `salloc` is provided also, 
        but note that it does not completely work as it does outside the
        container as it cannot find the right shell to start. The way to use it,
        is to add 'bash' as the last argument, e.g.,
        ```
        salloc -N1 -n1 -c128 -pstandard -t15:00 bash
        ```
        as otherwise you will get the error message:
        ```
        salloc: error: _fork_command: Unable to find command ""
        ```

    -   The latest EESSI image available on LUMI is mounted.
  
        If you study the EasyConfig and `/pfs/lustref1/eessicvmfs`, you will see that
        it would be easy to ensure a specific image of EESSI is loaded rather than the
        latest one, should this be important for you for reproducibility of results. 
        You would need to copy the desired image to your own project space though 
        as old images are removed after a while. Note also that these images are huge
        so you will need enough storage billing units.

-   `EESSI_START`: Command to initialise this version of EESSI.
    In the container, this should not be needed and outside the container it is simply
    easier to use the `eessi-init` function instead.


## Some notes

### CPU architectures in EESSI

EESSI auto-detects the CPU architecture when the initialisation script is called.

After initialisation, check the environment variable `EESSI_SOFTWARE_SUBDIR` to check
which architecture will be used. For LUMI this should be

-   `x86_64/amd/zen2` on the login nodes, large memory nodes and visualisation GPU nodes.

-   `x86_64/amd/zen3` on the LUMI-C and LUMI-G compute nodes.

You can override this before initialisation (or before entering the container) by setting 
`EESSI_SOFTWARE_SUBDIR_OVERRIDE` to one of these values. Other values are not supported on 
LUMI and are not present in the images.

Software for zen3 usually runs correctly on zen2 CPUs also. Depending on how you structure
your jobs or work on LUMI, you may want to load the zen3 software from EESSI on the login
nodes (e.g., when using `salloc` and launching job steps on the compute nodes).


## Known issues affecting users

-   MPI programs cannot be started with `srun` but have to be started with `mpirun`,
    so MPI rank binding is different from the regular LUMI environment where 
    Cray MPICH is used. It is expected that when ROCm support appears in EESSI 
    (which is under development at this time, mid 2026), may also require different
    techniques for proper mapping of MPI ranks onto the available cores and GPUs.
