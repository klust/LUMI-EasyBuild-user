# CPE Containers

This containers should not be spread outside LUMI, and some even contain unofficial
versions and should not be spread to more users than needed.

Options: 

-   ccpe-23.12-cce_17-18-rocm-5.4.1-17_18.eb: Install from the instance maintained by Alfio.
  
    To offer some security though obscurity the path where the container can be found,
    is currently not shown in the EasyConfig file. Before installing, set the environment
    variable EASYBUILD_SOURCEPATH to the directory where the sif file can be found.
    
    Sample installation commands:
    
    ```
    module load LUMI/23.09 partition/container EasyBuild-user
    EASYBUILD_SOURCEPATH=<mystery directory>
    eb ccpe-23.12-cce_17-18-rocm-5.4.1-17_18.eb
    ```
    
    Note: For LUST, one can also use `/project/project_462000008/CCPE` for the mystery 
    directory. This directory should be readable to LUST only!
    
    To save space you can omit the `.sif` file from `$EBROOTCCPE` and instead use a symbolic
    link to the one in the LUST project or mystery directory.

-   ccpe-23.12-cce_17-18-rocm-5.4.1-17_18-LUST.eb: Use the instance in the LUST directory, but
    still generate a module and some bootstrap scripts to play with.
