# CPE Containers

These containers should not be spread outside LUMI, and some even contain unofficial
versions and should not be spread to more users than needed. So do not spread without
explicit agreement with HPE.

## EasyBuild



### Container for 24.11 obtained from the HPE support web site.

-   The goal of the EasyConfig is to mimic what the `ccpe-config` script
    from HPE does:
    -   Binding other files from the system
    -   Binding Slurm commands
    -   Binding libfabric install
    -   Binding some system files

-   We inject the file `/.singularity.d/env/99-z-ccpe-init` which we use
    to define additional environment variables in the container that can
    then be used to execute commands.
    
    Currently used so that `eval $INICCPE` does a full (re)initialization
    of LMOD so that it functions in the same way as on LUMI.
    