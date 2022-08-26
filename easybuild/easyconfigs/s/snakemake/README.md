# snakemake instructions

  * [Snakemake home page](*https://snakemake.readthedocs.io/)

  * [Snakemake on github.io](https://snakemake.github.io/)

  * [Snakemake on PyPi](https://pypi.org/project/snakemake/)

  * [Snakemake on GitHub](https://github.com/snakemake/snakemake)

      * [GitHub releases](https://github.com/snakemake/snakemake/releases/tag/v6.9.1)


## EasyBuild

  * [snakemake support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/s/snakemake) -
    not very useful for building on top of Cray Python though.

  * There is no snakemake support in the CSCS repository


## 6.9.1 for CPE 21.08

  * We started with a clean sheet as we wanted to build on top of Cray Python.

  * As Cray Python seems to simply rely on the system GCC, a version was build
    using the SYSTEM toolchain.

  * Some packages were not installed in the most recent version because they fail
    in the sanity check of EasyBuild. Some relaxing may be needed as some recent
    Python modules don't seem to return their version number in the way that
    EasyBuild expects.

    The EasyBuild community may not even have a full solution for this at this time
    (EasyBuild 4.4.2 in October 2021) as even recent development EasyConfigs return
    to old versions of those packages.

  * Also tried to make a cpeGNU version but that doesn't work yet. For some unknown
    reason some packages install differently when ``cpeGNU/21.08`` is loaded.

      * The installation process breaks when installing ``toposort``, complaining that a
        ``setup.py`` is missing, but that doesn't seem to be an issue when installing
        with the SYSTEM toolchain. In fact, there is a ``pyproject.toml`` which together
        with ``setup.cfg`` should be sufficient, but for some reason it is not for an
        EasyBuild-initiated process.

        A workarround is to install from a downloaded wheel.

      * The installation process breaks when installing ``datrie``. Here the error message
        comes from setuptools, complaining that there is no attribute ``__legacy__``.

        There is no easy solution here. One could install from a downloaded wheel but
        as this contains binary code, compatibility is not guaranteed.

        Falling back to an older version was also no option as that one does not support
        Python 3.8 and compilation fails.
