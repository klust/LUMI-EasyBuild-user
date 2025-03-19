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

Unfortunately, there seems to be no way to properly re-initialise the shell in the
container directly through `singularity shell` or `singularity exec`.

The following strategies can be used:

-   In the container, the environment variable `INITCCPE` contains the necessary
    commands to get a working Lmod environment again, but then with the relevant
    CPE modules for the container. Run as
    
    ```
    eval $INITCCPE
    ```
    
-   Alternatively, sourcing `/etc/bash.bashrc` will also properly set up Lmod.


## Known restrictions    

-   We do already mount the Slurm tools in the container. However, they do not yet
    function and it is not clear if this is fixeable.
    
-   `PrgEnv-aocc` is not provided by the container. The ROCm version is taken from the
    system and may not be the optimal one for the version of the PE.
