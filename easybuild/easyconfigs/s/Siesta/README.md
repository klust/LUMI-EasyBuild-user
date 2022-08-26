# Siesta

-   [Siesta web site](https://siesta-project.github.io/dev-portal/)
    or [alternative copy](https://departments.icmab.es/leem/siesta/)]
    
-   [Siesta documentation in HTML](https://docs.siesta-project.org/projects/siesta/index.html)
    but is this up-to-date?
    
-   [Siesta GitLab](https://gitlab.com/siesta-project/siesta)
    
    -   [GitLab releases](https://gitlab.com/siesta-project/siesta/-/releases)
    
## EasyConfigs

-   There is [support for Siesta in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/s/Siesta)
    but it requires a [custom EasyBlock](https://github.com/easybuilders/easybuild-easyblocks/blob/develop/easybuild/easyblocks/s/siesta.py)
    that doesn't seem to work with the way the CPE toolchains set environment variables 
    for the math libraries.
    
-   There is no support for Siesta in the CSCS repository.
    
-   Archer2 provides [build instructions for Siesta with PrgEnv-gnu](https://github.com/hpc-uk/build-instructions/tree/main/apps/SIESTA)
    but that seems to be the minimal install without METIS, ELPA, MUMPS, PEXSI or flook that are mentioned in
    [the PDF version of the Siesta 4.1.5 manual](https://siesta-project.org/SIESTA_MATERIAL/Docs/Manuals/siesta-4.1.5.pdf)
    as libraries that provide additional functionality.
