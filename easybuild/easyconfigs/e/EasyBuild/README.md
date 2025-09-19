# Way of working to build the huge EasyBuild EasyConfigs in late versions of the LUMI softwarestack

-   Patches: The way of applying patches is different in an EasyConfig just for
    EasyBuild or in the Bundle.

    -   When installing in a single package EasyBlock, patching starts from the
        sources directory that contains the framework. Which makes it harder to 
        patch EasyBlocks or EasyConfigs.

    -   When installing EasyBuild as a Bundle component, patching starts from the 
        Bundle source directory that contains all sources of all Bundle components.

    So the `patches` part cannot just be copied, we need to make some changes to the 
    directory from which they are applied.

    We also experienced trouble trying to patch in both cases which is why for both the 
    single software install and the Bundle install, we use a more elaborate version of
    specifying the patches. 

    Note that the [documentation for `patches`](https://docs.easybuild.io/patch-files/) 
    in the EasyBuild documentation was wrong
    at the time of writing (September 2025) unless it has changed in EasyBuild 5. 
    In fact, the `opts` field does not exist in EB 4.9.

-   Uniform way of preparing patches:

    -   Uncompress the sources tar file.

    -   Rename in the same way as the `sources` field does: `easybuild_framework-5.1.1` to
        `easybuild-framework-5.1.1`, etc. This is needed because PyPi changed the way it treats
        packages with dashes in their name somewhere between the 4.9.1 and 4.9.2 releases
        of EasyBuild.

    -   Copy the file you want to change to a file with the additional extension `.orig`.

    -   Edit the file that needs changes.

    -   Create the patch. The command we use is something like:
        ``` bash
        diff -Nau easybuild-framework-5.1.1/easybuild/tools/filetools.py.orig easybuild-framework-5.1.1/easybuild/tools/filetools.py
        ```
        Comment lines can be copied from a previous version of the patch.

-   From EasyBuild 5 onwards, we started using Cray Python as the Python implementation to run EasyBuild as
    EasyBuild 5 still supported 3.6, but it was deprecated and not well tested anymore.

    To avoid having to load the `cray-python` module as a dependency, which may interfere with installations
    that would use some other Python module, and to robustify the `eb` command and various scripts installed
    by the other Python packages, we edit those scripts with `sed`:

    -   To robustify the `eb` command:

        -   `PYTHONPATH` is hard-coded in the `eb` shell script and overwrites anything from the environment:
            ```
            '-e \'s|^PYTHON=.*|export PYTHONPATH="%(installdir)s/lib/python{local_pyshortver}/site-packages:%(installdir)s/lib64/python{local_pyshortver}/site-packages"\\nPYTHON=|\' '
            ```

        -   In the loop that searches for a suitable Python command, we added the Cray Python `python3.XX` 
            command with full path and version at the front of the list:
            ```
            '-e \'s|for python_cmd in|for python_cmd in "{local_craypython_exe}"|\' '
            ```
            with
            ```
            local_pyshortver = '.'.join(local_craypython_version.split('.')[:2])
            local_craypython_exe = f'/opt/cray/pe/python/{local_craypython_version}/bin/python{local_pyshortver}'
            ```
            Therefore we don't need to load the `cray-python` module anymore when running if we do this
            in all such scripts.
            Hence strictly speaking EB_PYTHON is no longer needed.

    -   We used a similar strategy to robustify scripts from additional Python packages 
        that we installed. See the next step for how we built a list of packages and 
        package versions to install.
        
        Steps to robustify (applied to `archspec, `pygmentize`,`markdown-it` and `pycodestyle`):

        -   We change the shebang line to explicitly call `python3.XX` from `cray-python` with full path
            and version, and we added the -E option to avoid using the value of PYTHONPATH:
            ```
            '-e \'s|/opt/.*/python|{local_craypython_exe} -E|\''
            ```
            This again ensures that these scripts can run without the `cray-python` module loaded.

        -   We then used `sys.path.append` to add the `lib` subdirectory of the installation directory 
            to the Python search path.
            ```
            '-e \'s|import sys|import sys\\nsys.path.append("%(installdir)s/lib/python{local_pyshortver}/site-packages")|\''
            ```
    These steps were already the 4.9.2 version that we used from 23.12 onwards, but then using the system Python
    `python3.6` interpreter from the system installation instead.

-   Additional Python tools: We like to add them to the same module in the EasyBuild 
    installation, as that avoids a "chicken-and-egg" problem where we would need a 
    bootstrapping process to install a module with those packages which are then 
    used by another EasyBuild module, or we would have to add code to the module file
    that only tries to load that module if it can find it, but does not produce an
    error if it cannot load it (which in fact is easy in Lmod).
    
    Packages that are useful for EasyBuild 5:

    -   `rich` for rich output such as the progress bars.
    -   `PyYAML` for using EasyStack files. It is useful in containers where we do not yet have it,
        but note that Cray Python comes with yaml, so we don't need it in EasyBuild installations 
        based on `cray-python`.. 
    -   It looks like EasyBuild 5 does not use `archspec` anymore. It may still be useful to include to
        invest system properties, but we leave it out 
    -   `pycodestyle` for checking code style is also relatively innocent as it does not pull in other 
        dependencies. It is needed for `--check-style` and `--check-contrib`.
    -   `graphviz` is relatively innocent. It can be used for building dependency graphs in PDF or
        PNG formats and doesn't seem to need any dependencies.
    -   `python-graph-dot` builds dependency graphs in `.dit` format and this one also pulls in
        three other packages. 
    -   `GitPython` could be added and has a reasonable number of dependencies, but we have no clear
        use case for it at the moment.
    -   `keyring` could be added, but it may not even be fully functional on the compute nodes.
        And it comes with a crazy number of dependencies that also need to be installed.
   
    To prepare a list of package versions and their dependencies, experiment in a virtual 
    environment. For our EasyBuild 5.1.1 EasyConfig with `cray-python/3.11.7`, we explored:
    ``` bash
    python3.11 -m venv ebtest
    cd ebtest && source bin/activate
    # Need wheel as otherwise EasyBuild cannot properly install package is setuptools < 70.1
    pip3.11 install wheel
    # The rich package
    pip3.11 install rich
    # This also pulls in mdurl, pygments and markdown-it-py
    # archspec
    pip3.11 install archspec
    pip3.11 install pycodestyle
    ```
    
    Installing those packages, turned out to be painful though:

    -   Doing things the "regular" way, i.e., installing from sources, was cumbersome as now
        EasyBuild also requires that you install all build dependencies of those packages,
        and of course, do so in the right order. The result is an explosion of packages
        beyond control, and somehow we could not install `poetry` on top of Cray Python from sources.
        Moreover, those packages did not show up when we installed in the virtual environment,
        so it is hard labour to build the complete list.
        
    -   What worked better, and is as good as all the packages that we finally selected were pure
        Python packages anyway, was installing from wheels. The only thing you need to do is then 
        use `'source_tmpl': '%(name)s-%(version)s-py3-none-any.whl'` (most packages) or
        `'source_tmpl': '%(name)s-%(version)s-py2.py3-none-any.whl'` depending on the package
        (and you can put this into `exts_default_options` of course). Installation then went smoothly.
        
    -   The horror then came with the EasyBuild sanity checks as it absolutely wanted 
        a compatible Python in the `PATH` which we wanted to avoid. So for now we add 
        the Python binary at the end of the search `PATH`.
        
-   With the `EB_EasyBuildMeta` EasyBlock or its LUMI-specific variant, it is impossible to install EasyBuild
    so that it uses a different Python version than the one used by the `eb` command that does the installation.
    (Or is it impossible to use non-system Python?)
    
    Moreover, after creating a bootstrap version using the `pip install` procedure, 
    it turned out that the `EB_EasyBuildMeta` EasyBlock doesn't work with Cray Python, likely as 
    the `wheel` package that provides `bdist_wheel` is missing and the version of 
    `setuptools` is also older than 70.1 (the first version that actually contained the 
    `bdist_wheel` command itself).
    
    This was accomplished by using the `PackedBinary` generic EasyBlock with a custom
    `install_cmds` similar to what is done in the EasyBuilders recipes for NextFlow.
    The advantage of this is that we don't need to do any installation work anymore in a `postinstallcmds` 
    which is also a cleaner approach. (We still use it in the Bundle for work on other packages though.)

    After all, it is not clear though if the `EB_EasyBuildMeta` EasyBlock offers any advantages when used in a Bundle as it is mostly about 
    sanity checks that are not executed properly anyway when EasyBuild is installed as component in a Bundle as
    we started doing on LUMI at some point to include some other useful software for EasyBuild installations.

-   **Remaining issues** that we do not like:

    -   We need to add Cray Python to the `PATH` even though it is needed for nothing. 
        Otherwise the sanity checks fail.
        
        Of course, in the logic of using EasyBuild as a library, one would even need 
        to have the correct Python library as a depedency, but that could only cause issues
        when EasyBuild is then used to install another Python version or packages for a different
        Python version.
        
    -   The EasyBuild installation directory is also added to `PYTHONPATH`. This makes sense though as 
        EasyBuild can also be used as a library which is not a use case we currently have on LUMI.