# Development of the EasyConfig for 24.11.

## Initialise the containerised CPE

We tried to create a bash function for this purpose by injecting a file in `/.singularity.d/env` that would
define the following function:

```bash
function init-ccpe() {

    # Clear Lmod
    lmod_dir="\$LMOD_DIR/.."
    eval 'module --force purge'
    eval \$(\$LMOD_DIR/clearLMOD_cmd --shell bash --full)
    unset LUMI_INIT_FIRST_LOAD

    # Clear the lmod cache as we may be switching between versions of Lmod.
    [ -d \$HOME/.lmod.d/.cache ] && /bin/rm -rf \$HOME/.lmod.d/.cache  # System Lmod 8.3.1
    [ -d \$HOME/.cache/lmod ]    && /bin/rm -rf \$HOME/.cache/lmod     # Own Lmod 8.7.x

    # Source the program environment initialisation
    source /etc/cray-pe.d/cray-pe-configuration.sh

    # Initialise LMOD
    source \$lmod_dir/init/profile

    # Build MODULEPATH
    mod_paths="/opt/cray/pe/lmod/modulefiles/core
               /opt/cray/pe/lmod/modulefiles/craype-targets/default
               \$mpaths
               /opt/cray/modulefiles
               /opt/modulefiles"
    MODULEPATH=''
    for p in \$(echo \$mod_paths) ; do
        if [ -d \$p ] ; then
            MODULEPATH=\$MODULEPATH:\$p
        fi
    done
    export MODULEPATH=\${MODULEPATH/:/} # Export and remove the leading :.

    # Build LMOD_SYSTEM_DEFAULT_MODULES
    LMOD_SYSTEM_DEFAULT_MODULES=\$(echo \${init_module_list:-PrgEnv-\$default_prgenv} | sed "s_  *_:_g")
    export LMOD_SYSTEM_DEFAULT_MODULES
    # Need eval on the next line as it is a shell function.
    eval "module --initial_load --no_redirect restore"

} # End of init-ccpe
```

However, it turns out that variables can be injected that way, but functions cannot.

We ended up creating a variable that gives the commands to initialise the programming 
environment. It works in the same style as the `$WITH_CONDA` for the AI containers 
made by AMD for LUMI. To initialse the CPE, use `eval $INITCCPE`.

