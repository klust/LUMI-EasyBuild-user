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


## How to detect if we are on LUMI

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

The one issue with this approach is the ownership of the file as it will not be owned by `root`.

Other ideas for detection:

-   Does `/proc/net/arp` contain entries in `193.167.209`? No, does not work on the compute nodes.


