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
Moreover, the `module --force purge` cannot have the expected effect as it does not
have access to the standard CPE modules so they cannot be properly unloaded.

We ended up creating a variable that gives the commands to initialise the programming 
environment. It works in the same style as the `$WITH_CONDA` for the AI containers 
made by AMD for LUMI. To initialise the CPE, use `eval $INITCCPE`.


## How to detect if we are on LUMI to warn for license violations

```bash
if [[ -f /etc/slurm/slurm.conf && $(/usr/bin/grep ClusterName /etc/slurm/slurm.conf) == "ClusterName=lumi" ]] ; then echo "On lumi"; fi
if [[ -f /etc/slurm/slurm.conf && $(/usr/bin/grep ClusterName /etc/slurm/slurm.conf) == *lumi ]] ; then echo "On lumi"; fi
if [[ -f /etc/slurm/slurm.conf && $(/usr/bin/grep ClusterName /etc/slurm/slurm.conf) =~ lumi$ ]] ; then echo "On lumi"; fi
```

```bash
if [[ -f /etc/opt/cray/cos/cos-config && $(/usr/bin/grep API_GW_URL /etc/opt/cray/cos/cos-config) == *lumi.csc.fi ]] ; then echo "On lumi"; fi
if [[ -f /etc/opt/cray/cos/cos-config && $(/usr/bin/grep API_GW_URL /etc/opt/cray/cos/cos-config) =~ lumi.csc.fi$ ]] ; then echo "On lumi"; fi
```

Or the reverse: 

```bash
if [[ ! ( -f /etc/slurm/slurm.conf && $(/usr/bin/grep ClusterName /etc/slurm/slurm.conf) =~ lumi$ ) ]] ; then echo "Not on lumi"; fi
if [[ ! ( -f /etc/opt/cray/cos/cos-config && $(/usr/bin/grep API_GW_URL /etc/opt/cray/cos/cos-config) =~ lumi.csc.fi$ ) ]] ; then echo "Not on lumi"; fi
```

It would be better to do so in a POSIX-compliant way:

```bash
if [ ! -f /etc/slurm/slurm.conf ] || ! /usr/bin/grep -q 'ClusterName[[:space:]]*=[[:space:]]*lumi$' /etc/slurm/slurm.conf; then echo "Not on lumi" ; fi
if [ ! -f /etc/opt/cray/cos/cos-config ] || ! /usr/bin/grep -q 'API_GW_URL.*lumi\.csc\.fi$' /etc/opt/cray/cos/cos-config; then echo "Not on lumi" ; fi
```

The problem is that these tests cannot be taken into LUMI unless we tell the users to mount those files.

Otherwise, the idea is to inject this test in `/.singularity.d/env/00-license.sh` and print a message warning the user if they
take the container to a different machine.

```
Bootstrap: localimage

From: cpe_2411.orig.sif

%post

cat > /.singularity.d/env/00-license.sh << EOF
if [ ! -f /etc/slurm/slurm.conf ] || ! /usr/bin/grep -q 'ClusterName=lumi\$' /etc/slurm/slurm.conf
then 
    echo -e 'This container was prepared by the LUMI User Support Team and can only legally' \
            '\nbe used on LUMI by LUMI users with a personal active account. Using this' \
            '\ncontainer on other systems than LUMI or by other than registered active users,' \
            '\nis considered a breach of the "LUMI General Terms of Use", point 4.\n' \
            '\nIf you see this message on LUMI, then most likely your bindings are not OK.' \
            '\nPlease also bind mount /etc/slurm/slurm.conf in the container.'
    
    # Break off the initialisation of the container.
    exit
fi
EOF

chmod a+rx /.singularity.d/env/00-license.sh

```

The issue with this approach is that building on top of this container will fail because this
script is executed and calls "exit".

Possible solutions are:

1.  Be less strict with the license handling and do not call exit so that the initialisation
    of the container can proceed normally.

    The output of `singularity build` will still show the message though.
    
    It can be worked around in the `singularity build` process by copying `/etc/slurm/slurm.conf`
    from the system in the `%files` section and then delete the file again in the `%post`
    section.

2.  Create a mount point for Slurm: `mkdir -p /etc/slurm` and make sure that the `/etc/slurm` from
    the system is mounted here when calling the build process. However, there is a chance that this
    may come and haunt us if we want to inject other stuff in `/etc/slurm`.

    We have tested this and this works, but the problem is that users who download the container themselves
    cannot use the easyconfigs that build upon those containers as `singularity build` will not be able to 
    bind mount `/etc/slurm`. 

One can also consider a combination of both:

```
Bootstrap: localimage

From: cpe_2411.orig.sif

%post

cat > /.singularity.d/env/00-license.sh << EOF
if [ ! -f /etc/slurm/slurm.conf ] || ! /usr/bin/grep -q 'ClusterName=lumi\$' /etc/slurm/slurm.conf
then 
    echo -e 'This container was prepared by the LUMI User Support Team and can only legally' \
            '\nbe used on LUMI by LUMI users with a personal active account. Using this' \
            '\ncontainer on other systems than LUMI or by other than registered active users,' \
            '\nis considered a breach of the "LUMI General Terms of Use", point 4.\n' \
            '\nIf you see this message on LUMI, then most likely your bindings are not OK.' \
            '\nPlease also bind mount /etc/slurm/slurm.conf in the container.'
fi
EOF

chmod a+rx /.singularity.d/env/00-license.sh

mkdir -p   /etc/slurm
chmod a+rx /etc/slurm

```

but for now we go for the first solution.


Other ideas for detection:

-   Does `/proc/net/arp` contain entries in `193.167.209`? No, does not work on the compute nodes.


## Tests for the container modules

1.  `ccpe-shell` test:

    ```bash
    ccpe-shell
    ```

    and in the singularity session,

    ```bash
    eval $INITCCPE
    module list
    exit
    ```
    
    should show the default set of modules. Check for `cce` to see if you get the one from the
    compiler, and `libfabric`, to see if you  get the intended version for the container.
    
2.  `ccpe-shell` test

    ```bash
    ccpe-shell
    ```

    and in the singularity session,

    ```bash
    source /etc/bash.bashrc
    module list
    exit
    ```

    should show the same output as the previous test.

3.  `ccpe-exec` test

    ```bash
    ccpe-exec uname -a
    ```

4.  `ccpe-exec` test

    ```bash
    ccpe-exec bash -c 'eval $INITCCPE ; module list'
    ```

    should show the same modules as the `ccpe-shell` tests and then return to the command prompt
    outside the container.

5.  `ccpe-exec` test: Start a bash prompt in an interactive shell.

    ```bash
    ccpe-exec bash -i
    ```

    The output will differ depending on the module. But in all cases, you should end up with a command prompt at the
    end, but which one will depend on your `~/.bashrc` and on whether you unset `PROMPT_COMMAND` 
    in that file or not (as if you do not unset it, you'll get a prompt determined by he module or
    simply `Singularity>` if the module does not set `SINGULARITYENV_PS1`).

    Also check

    ```bash
    ml
    exit
    ```

    which should show a correctly initialised module environment for the container.

6.  `ccpe-run` test

    ```bash
    ccpe-run
    ```

    The output will differ depending on the module. Currently, for the raw versions the runscript will
    generate a number of warnings. But in all cases, you should end up with a command prompt at the
    end, but which one will depend on your `~/.bashrc` and on whether you unset `PROMPT_COMMAND` 
    in that file or not (as if you do not unset it, you'll get a prompt determined by he module or
    simply `Singularity>` if the module does not set `SINGULARITYENV_PS1`).

    Also check

    ```bash
    module list
    exit
    ```

7.  `ccpe-singularity` test

    ```bash
    ccpe-singularity exec "$SIFCCPE" bash -c 'eval $INITCCPE ; module list'
    ```

    should again show all modules you'd expect at the container setup as in previous tests, and then return 
    to the command prompt outside the container.
 
    The same should be the case for

    ```bash
    ccpe-singularity exec "$SIFCCPE" bash -i -c 'module list'
    ```

