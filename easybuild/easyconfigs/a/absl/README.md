# absl or absl-py

-   [absl-py on PyPi](https://pypi.org/project/absl-py/)
    
-   [ absl-py on GitHub](https://github.com/abseil/abseil-py)

    -   [GitHub releases](https://github.com/abseil/abseil-py/releases)


## EasyBuild

-   There is no separate EasyConfig for `absl-py` in the EasyBuilders repository.
    
-   [Support for absl-py in the CSCS repository as absl](https://github.com/eth-cscs/production/tree/master/easybuild/easyconfigs/a/absl)
    
Note that we call the module `absl` and not `absl-py` as would be expected
in the EasyBuild universum because we would have had to use a more complicated
EasyConfig structure as the name of the module is `absl` and not `absl_py` and
the sanity check fails.


### Version 1.3.0 for cpeGNU/22.08

-   The EasyConfig is a heavily adapted one from an old CSCS EasyConfig.
