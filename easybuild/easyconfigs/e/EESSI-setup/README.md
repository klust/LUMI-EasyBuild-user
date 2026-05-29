# Technical information about EESSI-setup

Basic idea that is being explored:

-   Make a container available on the login nodes, or possibly when EESSI is not present.
  
    Make it possible to launch jobs from within the container also.

-   On compute nodes that already support EESSI, make a simple command available that 
    initialises EESSI.

-   It also sets environment variables on the login nodes that guarantee that a job
    will be launched with the right Slurm options for EESSI and network support.


## Implementation specifics

-   The file `preserve_vars.sh` is needed to set a number of `SINGULARITYENV_` environment
    variables for EESSI variables that are needed already during the container initialisation,
    as it turns out that the environment from outside the container is only imported after 
    the initialisation currently.


## Known issues

### Issues specific to EESSI-setup

-   `salloc` does not fully work in the container as Slurm cannot start a shell in the container.
    This can be solved easily by adding the `bash` command to the `salloc` command line though:
    Use
    ```
    salloc -N1 -n1 -c128 -pstandard -t15:00 bash
    ```
    as otherwise you will get the error message:
    ```
    salloc: error: _fork_command: Unable to find command ""
    ```

    Outside the container, using `salloc` with EESSI is a tricky at least and may lead to 
    the use of the wrong architecture version of EESSI, as `salloc` does not open a shell on
    the first compute node of the allocation but on the node on which `salloc` is executed,
    which will typically be a login node.


### EESSI on LUMI

-   EESSI can get confused with the user module cache. This is particularly troublesome in the container,
    where the host applications are not available, while we cannot edit Lmod to use a different cache
    directory.

    It would be much nicer if EESSI had its own user Lmod cache in a different directory. Unfortunately,
    as Lmod is not in the container but in a SquashFS image that is mounted in it, this is far from
    trivial and may require working with overlays instead of bind mounts (and would be tricky again
    whenever EESSI starts a new release).

-   Due to the way EESSI is offered on LUMI, there is not `/opt/eessi` outside the container.


### General EESSI issues

-   In /cvmfs/software.eessi.io/versions/$EESSI_VERSION$/compat/linux/x86_64/etc, mtab is a symbolic link
    to ../proc/self/mounts which does not make sense if the etc subdirectory is not in the root.
    Shouldn't this be /proc/self/mounts, or is this something that is normally resolved with cvmfs tricks
    and is only an error on the LUMI containers?

