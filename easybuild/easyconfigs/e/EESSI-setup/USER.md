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

        One particular case is when `/cvmfs/software.eessi.io` is simply not available.
        It will still print an error message to stderr, and the error return code will
        be 1, but it will also have exported the `eessi-init` function so this can be
        abused to ensure that job scripts started with `sbatch` after loading the 
        module would still have `eessi-init` defined.

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

    However, the `eessi-init` function is not by default exported to subshells (this is
    an Lmod feature and not a bug) so it is still useful to initialise EESSI in subshells
    of where the module is loaded if initialisation is postponed.


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


## Some examples (use cases)

**These examples assume that you have installed the `EESSI-setup/2025.06` module
as instructed above.**


### Start work interactively from the login nodes

EESSI is not available on the login nodes while `salloc`, the most used command for interactive
work in Slurm, will open a shell on the node where it is called, so typically a login node.

A container with access to EESSI offers the solution, and the `EESSI-setup` module does the 
setup in such a way that it is even possible to call Slurm commands from within the container
(though in this example, we could as well first call `salloc` and only then initialise the
container).

As a demo, we'll run the OSU benchmark [used in the EFP documentation for LUMI](https://docs.my-eurohpc.eu/software-catalog/system-specific/lumi/#multi-node-jobs),
but do so interactively:

1.  Load the `EESSI-setup` module and start a shell

    ``` bash
    module load LUMI EESSI-setup/2025.06
    EESSI_SOFTWARE_SUBDIR_OVERRIDE=x86_64/amd/zen3 eessi-run
    ```
 
    Instead of loading the `LUMI` module, you can also load `CrayEnv`, but one of those 
    is needed to make the `EESSI-setup/2025.06` module available.

    We have an issue here: The EESSI initialisation is running on the login nodes, so would 
    select the zen2 architecture while the compute nodes do support zen3. Now zen3 software
    usually runs just fine on zen2 nodes as the differences in instruction sets are minimal
    so we load zen3 software right away for optimal performance on the compute nodes,
    and therefore we use an architecture overwrite which is done by ensuring that 
    `EESSI_SOFTWARE_SUBDIR_OVERRIDE` is set to `86_64/amd/zen3` when running `eessi-run`,
    the preferred command in this module to open a shell.

2.  Start an interactive job

    ``` bash
    salloc --account=<MY_SLURM_ACCOUNT> --nodes=2 --ntasks-per-node=1 \
           --cpus-per-task=1 --time=30:00 --partition=small bash
    ```

    Note the explicit mention of the shell `bash` at the end of the `salloc` command.
    This is a restriction of using `salloc` in the container. Without it, it cannot find
    the proper shell.

    Note that we didn't need to sue `--constraint=eessi` not the `--network` setting
    from the example in the EFP documentation as these are added automatically by 
    environment variables set in the `EESSI-setup` module.

3.  We'll now load the software we want to run (but could have done so also before calling
    `salloc` as that command preserves the environment):

    ``` bash
    module load OSU-Micro-Benchmarks/7.5-gompi-2025a
    ```

4.  Let's check if `mpirun` starts two ranks, each on a different node:

    ``` bash
    mpirun -n 2 hostname
    ```

    and in fact, even though there is no full Slurm support in the EESSI OpenMPI module,
    `mpirun` will still know in this case that it needs to start two processes,
    so

    ``` bash
    mpirun hostname
    ```

    gives the same result.

5.  And now we'll run the benchmark:

    ``` bash
    mpirun osu_latency
    ```

    Depending on when you run this example, you may note rather poor performance. Normally
    you would expect a small message latency (the first few lines of output) 
    in the 2-3 µs range, but if EESSI is not yet
    properly tuned for LUMI (which was the case for the initial release of the EFP),
    you'll note numbers that are more in the 20 µs range.

    As long as this is the case, you should not use EESSI for multi-node runs on LUMI. 
    Scalability will be very bad and it is better to use the [software provided by the
    LUMI User Support Team](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/)
    or other [local software stacks on LUMI](https://docs.lumi-supercomputer.eu/software/).

6.  If you note bad performance, let's check why (and this is more specialist work):
    On LUMI, OFI also known as libfabric is used for communication, and the so-called
    Cassini provider or cxi provider is needed to talk to the network card. Some versions
    of Open MPI, in particular for GPU support, will also use the so-called LinkX provider
    which is layered on top of the CXI provider and provides extra functionality that 
    Open MPI expects from a libfabric provider but Cray MPICH, the preferred MPI implementation
    on LUMI, does not need.

    Try

    ``` bash
    mpirun -n 1 fi_info | grep cxi
    ```

    This will run the `fi_info` command on a compute node and that command will print all
    available providers. The `grep cxi` command then searches for the CXI provider. If this 
    does not return anything, there is an issue.

    The other way is to use some options to make `mpirun` more verbose and show how it arranges
    communication:

    ``` bash
    mpirun -n 2 --mca pml_base_verbose 100 --mca btl_base_verbose 100 osu_latency
    ```

    and if you analyse the results you'd see that MPI is using TCP for the messages, which is
    a protocol with a lot of overhead explaining the bad results.

7.  Do not forget to exit the interactive job and then the container, so use `exit` or CTRL-D
    twice.


### A sample job script

The sample jobscript from [the EFP docs for LUMI](https://docs.my-eurohpc.eu/software-catalog/system-specific/lumi/#multi-node-jobs)
becomes:

``` bash
#!/usr/bin/bash
#SBATCH --partition=small
#SBATCH --time=00:30:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --network=single_node_vni,job_vni,def_tles=0
#SBATCH --constraint=eessi

init-lumi-h
# Load the EESSI-setup module
module load LUMI EESSI-setup/2025.06

# Configure the EESSI environment and load the modules we need for our test
eessi-init

# Load the application software
module load OSU-Micro-Benchmarks/7.5-gompi-2025a

# Check we have two different nodes
mpirun -n 2 hostname
# Launch our latency test
mpirun -n 2 osu_latency
```

This job script can launch while the `EESSI-setup` module is not yet loaded.
Therefore we do need to explicitly request nodes with EESSI support with

``` bash
#SBATCH --constraint=eessi
```

This can be omitted if the `EESSI-setup` module is loaded before launching the batch job
with `sbatch`. It is not needed to enter an EESSI container to do so.

*It is currently not clear if the `--network` line is needed or if it is only used
when actual parallel job steps are started (and in the latter case loading the 
`EESSI-setup` module in the job script as we do may be sufficient).
When writing this text, the line had no effect, but it was likely in the documentation
in preparation for full support for the high-speed interconnect in LUMI.
And again, with the `EESSI-setup` module loaded when a job is submitted, it would not
be needed. You could then even avoid loading the module in the job script, but then you
would have to use the traditional way of initialising EESSI as `eessi-init` is a
shell function that is not exported to subshells (though that also could be solved
with an explicit `declare -fx eessi-init` command before the `sbatch` command).
This would also make the job script more similar to those on other EESSI clusters.*


## Known issues affecting users

-   MPI programs cannot be started with `srun` but have to be started with `mpirun`,
    so MPI rank binding is different from the regular LUMI environment where 
    Cray MPICH is used. It is expected that when ROCm support appears in EESSI 
    (which is under development at this time, mid 2026), may also require different
    techniques for proper mapping of MPI ranks onto the available cores and GPUs.
