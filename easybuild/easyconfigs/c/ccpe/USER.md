# User instructions for the HPE CPE containers.

## How to enable the containers?

We recommend using our EasyBuild modules to run the HPE CPE containers
as these modules do create a lot of bind mounts to provide all necessary
parts from the system to the container.

The modules provide a number of environment variables to make life easier:

-   Outside the container, `SIF` and `SIFCCPE` point to the container file,
    which is very handy to use with the `singularity` command.
    
-   Inside the container, `INITCCPE` contains the commands to fully initialise
    the CPE in the container. Use as `eval $INITCCPE`.

The module also provides access to two wrapper scripts to start the container.
Note though that those wrapper scripts only function properly when the module
is loaded. They do not take care of the bindings themselves and in that sense
are certainly different from the wrapper scripts provided by Tykky/lumi-container-wrapper.
Both scripts do however purge all modules before going into the container,
as modules from the system PE are not valid in the container, and fully clear Lmod.
Currently, the following scripts are provided:

-   `ccpe-shell` to start a shell in the container. The arguments of `ccpe-shell`
    are simply added to the `singularity shell $SIF`.
    
-   `ccpe-exec` to run a command in the container. The arguments of `ccpe-exec` 
    are simply added to the `singularity exec $SIF` command.


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
