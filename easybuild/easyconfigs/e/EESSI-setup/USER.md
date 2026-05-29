# User information for EESSI-setup


## Functions or commands provided

-   `eessi-init` bash function
  
    -   On a compute node with EESSI enabled, it will source the 
        `/cvmfs/software.eessi.io/versions/<version>/init/lmod/bash` script.
    
    -   If EESSI cannot be found, it will print a warning and return a non-zero 
        exit code. There are different error messages, depending on whether EESSI
        cannot be found at all, the right version of EESSI is not available, or
        the initialisation script is somehow missing (pointing at a broken EESSI
        installation).

-   `eessi-shell`: Starts a new bash shell with EESSI enabled

    -   If EESSI is installed on the node: Starts a new shell with EESSI enabled.
        
        Command line arguments are ignored though.

    -   If EESSI is not installed on the node: It will start a singularity container
        with EESSI initialised and using the command line arguments when starting
        the shell in the container.
