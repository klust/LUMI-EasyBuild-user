# spdlog technical information

-   [spdlog on GitHub](https://github.com/gabime/spdlog)

    -   [GitHub releases](https://github.com/gabime/spdlog/releases)
    
    
## EasyBuild

-   [spdlog support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/s/spdlog)

-   There is no support for spdlog in the CSCS repository.

-   [spdlog support in Spack](https://packages.spack.io/package.html?name=spdlog)


### Version 1.14.1 fore cpeGNU/23.09 and cpeCray/23.09

-   The EasyConfig is based on the EasyBuilder ones, but changed to align
    with the LUMI customs.
    
-   For now, we build both shared and static libs even though the EasyBuilders
    version only builds the static libs.
    
-   We've also added testing the software during the build process.
