# p7zip technical documentation


The p7zip package is a POSIX/Linux port of some of the 
[p7zip Windows tools](https://www.7-zip.org/).
Note that the latest version of 7zip do now support Linux already.

The p7zip tools however are used in certain EasyConfigs to work with ISO files,
e.b., the [MATLAB EasyConfigs in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/m/MATLAB).

-   New developments [on GitHub](https://github.com/p7zip-project/p7zip/).
    It is a fork from previous versions that are no longer maintained.
    It also extends the tools of the [7zip project](https://sourceforge.net/projects/sevenzip/)

    -   [GitHub releases](https://github.com/p7zip-project/p7zip/releases)


-   Older versions [on SourceForge](https://p7zip.sourceforge.net/)

    -   [SourceForge downloads](https://sourceforge.net/projects/p7zip/files/p7zip/)
        (up to version 16.02)
    
## EasyBuild

-   [p7zip in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/p/p7zip)


### Version 9.38.1

-   Trivial port of the EasyConfig in the EasyBuilders repository.


### Version 17.05

-   Based on the EasyBuilders p7zip one for 17.04, but moved to the SYSTEM
    toolchain, hence combined with the 9.38.1 one, and also downloading the
    sources differently so that the sources file gets a proper name and can
    be shared with other sources in a Bundle.
    
    The work was done in preparation for inclusion in the `EasyBuild-tools/23.09`
    bundle in the LUMI Software Stack.

    