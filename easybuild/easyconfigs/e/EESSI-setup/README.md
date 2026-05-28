# Technical information about EESSI-setup

Basic idea that is being explored:

-   Make a container available on the login nodes, or possibly when EESSI is not present.
  
    Make it possible to launch jobs from within the container also.

-   On compute nodes that already support EESSI, make a simple command available that 
    initialises EESSI.

-   It also sets environment variables on the login nodes that guarantee that a job
    will be launched with the right Slurm options for EESSI and network support.


## EESSI issues

