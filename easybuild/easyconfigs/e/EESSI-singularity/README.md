# EESSI-singularity module technical information

Still to be written...

THIS IS THE OLDER VERSION OF THE MODULE, TRY EESSI-setup INSTEAD...

-   [EESSI website](https://www.eessi.io/)

-   [EESSI documentation](https://www.eessi.io/docs/)


## Choices made

-   We use `SINGULARITY_BIND` rather than `SINGULARITY_BINDPATH` as when entering the container,
    singularity itself sets `SINGULARITY_BIND` with the bind mounts used for the container.

-   This version uses our own rewrite of the older singularity initialisation script rather than
    the newer one in `/cvmfs/software.eessi.io/versions/{version}/init/lmod/bash`. The script 
    needed to be changed at some points as it contains bashisms while the shell that is executing
    during the container initialisation, where we wanted to execute that script, is dash which is
    POSIX-compliant but does not implement all bash features.
