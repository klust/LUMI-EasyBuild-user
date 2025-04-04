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


## Getting Slurm in the container

The main issue to get Slurm working in the container, is that on LUMI, Slurm daemons run under the user "slurm", 
but the container does not know that user. 

So we need to get the `slurm` user and group in the container by changing 
`/etc/passwd` and `/etc/group`.

This *can not* be done in the `%post` phase. At that moment, you are running in
the container environment with a fake `passwd` and `group` file with your userid
and groups added to them. Depending on how you try to change these files,
you either get an error or the changes are discarded when creating the SIF file.

Causes an error:

```bash
groupadd -g 982 slurm
useradd -m -u 982 -g slurm slurm
```

Changes are discarded:

```bash
echo 'slurm:x:982:'                               >>/etc/group
echo 'slurm:x:982:982::/home/slurm:/sbin/nologin' >>/etc/passwd
```

What does work though, is simply copying these files from the system during the 
`%files` phase as you are not yet running in singularity:

```
%files
    /etc/passwd
    /etc/slurm/slurm.conf
```

Mounting `/etc/passwd` and `/etc/group` from the host, also does not work because
singularity then cannot automatically add the userid of the person calling the container. 
Regular userids are not included in those files on LUMI.


## Current definition file implementing Slurm support and license check

```
Bootstrap: localimage

From: cpe_2411.orig.sif

%files

    /etc/group
    /etc/passwd

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

## Experimenting with creating the proper environments for jobs

See also the example of how broken things can be in the user documentation.

??? Example "Exploring how to run with the CCPE containers"

    The next job script tries to run some commands from the container, exploring the
    environment. It is the basis for the job script template that we will discuss next.

    ```bash
    #!/bin/bash
    #
    # This test script should be submitted with sbatch from within a CPE 24.11 container.
    # It shows very strange behaviour as the `module load` of some modules fails to show
    # those in `module list` and also fails to change variables that should be changed.
    #
    #SBATCH -J example4
    #SBATCH -p small
    #SBATCH -n 2
    #SBATCH -c 1
    #SBATCH -t 5:00
    #SBATCH -o %x-%j.md
    #SBATCH --export=SINGULARITY_BIND,SIF,SIFCCPE
    # And add line for account

    #
    # Ensure that we can find the container. This might not be the case if this job script
    # is launched from outside the container with the ccpe module not loaded.
    #
    if [ -z "${SIFCCPE}" ]
    then
        module load CrayEnv ccpe/24.11-LUMI
    fi

    #
    # Block that can simply be copied, but note that the --export above is
    # important to have a clean shell on the system side.
    #
    if [ ! -d "/.singularity.d" ]
    then

        echo -e "# Prequel - In batch script but not in the container\n"

        echo -e "-   Environment variable \`SINGULARITY_BIND\`: \`${SINGULARITY_BIND}\`.\n"
        echo -e "-   Environment variable \`SIF\`: \`${SIF}\`.\n"
        echo -e "-   Environment variable \`SIFCCPE\`: \`${SIFCCPE}\`.\n"
        echo -e "-   Environment variable \`CRAY_CC_VERSION\`: \`${CRAY_CC_VERSION}\`. Hope for \`17.0.1\`, the value in the system environment.\n"
        
        echo -e "Do we have any modules loaded? Let's check with \`module list\`:\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
        
        echo -e "Let's try a full clean-up saving \`SINGULARIT_BIND\`, \`SIF\`and \`SIFCCPE\`:\n\n\`\`\`\n"
        
        save_SIF="$SIF"
        save_SIFCCPE="$SIFCCPE"
        save_BIND="$SINGULARITY_BIND"
        
        module --force purge
        eval $($LMOD_DIR/clearLMOD_cmd --shell bash --full --quiet)
        unset LUMI_INIT_FIRST_LOAD
        ## Make sure that /etc/profile does not quit immediately when called.
        unset PROFILEREAD
        
        export SIF="$save_SIF"
        export SIFCCPE="$save_SIFCCPE"
        export SINGULARITY_BIND="$save_BIND"
        
        echo -e "\n\`\`\`\n" 

        echo -e "Check the variables again:\n"    
        echo -e "-   Environment variable \`SINGULARITY_BIND\`: \`${SINGULARITY_BIND}\`.\n"
        echo -e "-   Environment variable \`SIF\`: \`${SIF}\`.\n"
        echo -e "-   Environment variable \`SIFCCPE\`: \`${SIFCCPE}\`.\n"
        echo -e "-   Environment variable \`CRAY_CC_VERSION\`: \`${CRAY_CC_VERSION}\`. If empty then cleaning up worked.\n"
        
        echo -e "Now restarting the script in the container..."
        exec singularity exec "$SIFCCPE" "$0" "$@"
        
    else

        echo -e "\n\n# Intermediate: Set up the container environment"
    
        echo -e "Check the value of \`INITCCPE\`:\n\`\`\`\n$INITCCPE\n\`\`\`\n"
    
        echo -e "Calling \`eval \$INITCCPE\`:\n\n\`\`\`\n"
        eval $INITCCPE
        echo -e "\n\`\`\`\n "
    
        echo -e "Check the variables again:\n"    
        echo -e "-   Environment variable \`SINGULARITY_BIND\`: \`${SINGULARITY_BIND}\`.\n"
        echo -e "-   Environment variable \`SIF\`: \`${SIF}\`.\n"
        echo -e "-   Environment variable \`SIFCCPE\`: \`${SIFCCPE}\`.\n"
        echo -e "-   Environment variable \`CRAY_CC_VERSION\`: \`${CRAY_CC_VERSION}\`. Hope for\`18.0.1\`, the value for 24.11 in the container.\n"

    fi

    echo -e "\n\n# Body of the job script - Building and investigating the environment\n"

    echo -e "Detected version of the module tool (should be the container one, 8.3.37 for 24.11): \n\`\`\`\n$(module --version 2>&1)\n\`\`\`\n"
    echo -e "List of modules currently loaded (should be the container ones):\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
    echo -e "Environment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
    echo -e "Now doing a \`module unload cce\`:\n\n\`\`\`\n"
    module unload cce 2>&1
    echo -e "\n\`\`\`\n"
    echo -e "Environment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`. This should be empty\n"
    echo -e "Now executing a 'module purge':\n\n\`\`\`\n"
    module purge 2>&1
    echo -e "\n\`\`\`\n"
    echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
    echo -e "Now executing \`module load cce\`':\n\n\`\`\`\n"
    module load cce 2>&1
    echo -e "\n\`\`\`\n"
    echo -e "And listing the modules with 'module list':\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\`\n"
    echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
    echo -e "Now executing a 'module purge' again:\n\n\`\`\`\n "
    module purge 2>&1
    echo -e "\n\`\`\`\n"
    echo -e "List of modules currently loaded (should be almost empty):\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
    echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"

    echo -e "\n\n# Trying an srun...\n\n"
    echo -e "Check if we still now the path to the container via the SIFCCPE environment variable:\n\`${SIFCCPE}\`\n"

    # Note the unexpected name of the next environment variable!
    # We want to export the whole environment that we just built via srun
    echo -e "Before calling \`srun\`, we need to unset \`SLURM_EXPORT_ENV\` to avoid propagation of the \`--export\` option that we used for the batch script.\n"

    unset SLURM_EXPORT_ENV

    echo -e "Now calling srun, excuting a \`module list\`, then print the value of \`CRAY_CC_VERSION\`, then \`module load cce\` and finally print the value of \`CRAY_CC_VERSION\` again."
    echo -e "We would like to to see the small list of modules from above again, then an empty variable and then the CCE version from the container.\n"

    # Note that we want srun to take over the environment we just built.
    echo -e "\n\`\`\`"
    srun -n2 -c1 -t1:00 --label singularity exec $SIFCCPE bash -c \
    'module list 2>&1 ; 
    echo "Before loading cce: CRAY_CC_VERSION=$CRAY_CC_VERSION" ; 
    module load cce ; 
    echo "After loading cce: CRAY_CC_VERSION=$CRAY_CC_VERSION, should be the container version."' \
    | sort -t : -k 1,1n -s
    echo -e "\n\`\`\`\n"
    ```

    The markdown document that it produces when being launched from within the CCPE container is like:

    **Prequel - In batch script but not in the container**

    -   Environment variable `SINGULARITY_BIND`: `/pfs,/users,/projappl,/project,/scratch,/flash,/appl,/opt/cray/pe/lmod/modulefiles/core/rocm/6.0.3.lua,/opt/cray/pe/lmod/modulefiles/core/amd/6.0.3.lua,/opt/rocm-6.0.3,/usr/lib64/pkgconfig/rocm-6.0.3.pc,/opt/cray/libfabric/1.15.2.0,/opt/cray/modulefiles/libfabric,/usr/lib64/libcxi.so.1,/var/spool,/run/cxi,/etc/host.conf,/etc/nsswitch.conf,/etc/resolv.conf,/etc/ssl/openssl.cnf,/etc/cray-pe.d/cray-pe-configuration.sh,/etc/slurm,/usr/bin/sacct,/usr/bin/salloc,/usr/bin/sattach,/usr/bin/sbatch,/usr/bin/sbcast,/usr/bin/scontrol,/usr/bin/sinfo,/usr/bin/squeue,/usr/bin/srun,/usr/lib64/slurm,/var/spool/slurmd,/var/run/munge,/usr/lib64/libmunge.so.2,/usr/lib64/libmunge.so.2.0.0,/usr/include/slurm`.

    -   Environment variable `SIF`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `SIFCCPE`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `CRAY_CC_VERSION`: `17.0.1`. Hope for `17.0.1`, the value in the system environment.

    Do we have any modules loaded? Let's check with `module list`:

    ```

    Currently Loaded Modules:
    1) craype-x86-rome                        8) cray-dsmml/0.3.0
    2) libfabric/1.15.2.0                     9) cray-mpich/8.1.29
    3) craype-network-ofi                    10) cray-libsci/24.03.0
    4) perftools-base/24.03.0                11) PrgEnv-cray/8.5.0
    5) xpmem/2.8.2-1.0_5.1__g84a27a5.shasta  12) ModuleLabel/label   (S)
    6) cce/17.0.1                            13) lumi-tools/24.05    (S)
    7) craype/2.7.31.11                      14) init-lumi/0.2       (S)

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ```

    Let's try a full clean-up saving `SINGULARIT_BIND`, `SIF`and `SIFCCPE`:

    ```


    ```

    Check the variables again:

    -   Environment variable `SINGULARITY_BIND`: `/pfs,/users,/projappl,/project,/scratch,/flash,/appl,/opt/cray/pe/lmod/modulefiles/core/rocm/6.0.3.lua,/opt/cray/pe/lmod/modulefiles/core/amd/6.0.3.lua,/opt/rocm-6.0.3,/usr/lib64/pkgconfig/rocm-6.0.3.pc,/opt/cray/libfabric/1.15.2.0,/opt/cray/modulefiles/libfabric,/usr/lib64/libcxi.so.1,/var/spool,/run/cxi,/etc/host.conf,/etc/nsswitch.conf,/etc/resolv.conf,/etc/ssl/openssl.cnf,/etc/cray-pe.d/cray-pe-configuration.sh,/etc/slurm,/usr/bin/sacct,/usr/bin/salloc,/usr/bin/sattach,/usr/bin/sbatch,/usr/bin/sbcast,/usr/bin/scontrol,/usr/bin/sinfo,/usr/bin/squeue,/usr/bin/srun,/usr/lib64/slurm,/var/spool/slurmd,/var/run/munge,/usr/lib64/libmunge.so.2,/usr/lib64/libmunge.so.2.0.0,/usr/include/slurm`.

    -   Environment variable `SIF`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `SIFCCPE`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `CRAY_CC_VERSION`: ``. If empty then cleaning up worked.

    Now restarting the script in the container...


    **Intermediate: Set up the container environment**
    
    Check the value of `INITCCPE`:
    ```

    if [ "$CCPE_VERSION" != "24.11" ] ;
    then

        lmod_dir="/opt/cray/pe/lmod/lmod" ;
            
        function clear-lmod() { [ -d $HOME/.cache/lmod ] && /bin/rm -rf $HOME/.cache/lmod ; } ;
        
        source /etc/cray-pe.d/cray-pe-configuration.sh ;
        
        source $lmod_dir/init/profile ;
        
        mod_paths="/opt/cray/pe/lmod/modulefiles/core /opt/cray/pe/lmod/modulefiles/craype-targets/default $mpaths /opt/cray/modulefiles /opt/modulefiles" ;
        MODULEPATH="" ;
        for p in $(echo $mod_paths) ; do 
            if [ -d $p ] ; then
                MODULEPATH=$MODULEPATH:$p ;
            fi
        done ;
        export MODULEPATH=${MODULEPATH/:/} ;
        
        LMOD_SYSTEM_DEFAULT_MODULES=$(echo ${init_module_list:-PrgEnv-$default_prgenv} | sed -E "s_[[:space:]]+_:_g") ;
        export LMOD_SYSTEM_DEFAULT_MODULES ;
        eval "source $BASH_ENV && module --initial_load --no_redirect restore" ;
        unset lmod_dir ;
        
    fi ;

    export CCPE_VERSION="24.11"

    ```

    Calling `eval $INITCCPE`:

    ```


    ```
    
    Check the variables again:

    -   Environment variable `SINGULARITY_BIND`: `/pfs,/users,/projappl,/project,/scratch,/flash,/appl,/opt/cray/pe/lmod/modulefiles/core/rocm/6.0.3.lua,/opt/cray/pe/lmod/modulefiles/core/amd/6.0.3.lua,/opt/rocm-6.0.3,/usr/lib64/pkgconfig/rocm-6.0.3.pc,/opt/cray/libfabric/1.15.2.0,/opt/cray/modulefiles/libfabric,/usr/lib64/libcxi.so.1,/var/spool,/run/cxi,/etc/host.conf,/etc/nsswitch.conf,/etc/resolv.conf,/etc/ssl/openssl.cnf,/etc/cray-pe.d/cray-pe-configuration.sh,/etc/slurm,/usr/bin/sacct,/usr/bin/salloc,/usr/bin/sattach,/usr/bin/sbatch,/usr/bin/sbcast,/usr/bin/scontrol,/usr/bin/sinfo,/usr/bin/squeue,/usr/bin/srun,/usr/lib64/slurm,/var/spool/slurmd,/var/run/munge,/usr/lib64/libmunge.so.2,/usr/lib64/libmunge.so.2.0.0,/usr/include/slurm`.

    -   Environment variable `SIF`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `SIFCCPE`: `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`.

    -   Environment variable `CRAY_CC_VERSION`: `18.0.1`. Hope for`18.0.1`, the value for 24.11 in the container.



    **Body of the job script - Building and investigating the environment**

    Detected version of the module tool (should be the container one, 8.3.37 for 24.11): 
    ```

    Modules based on Lua: Version 8.7.37  [branch: release/cpe-24.11] 2024-09-24 16:53 +00:00
        by Robert McLay mclay@tacc.utexas.edu
    ```

    List of modules currently loaded (should be the container ones):

    ```

    Currently Loaded Modules:
    1) craype-x86-rome
    2) libfabric/1.15.2.0
    3) craype-network-ofi
    4) perftools-base/24.11.0
    5) xpmem/2.9.6-1.1_20240510205610__g087dc11fc19d
    6) cce/18.0.1
    7) craype/2.7.33
    8) cray-dsmml/0.3.0
    9) cray-mpich/8.1.31
    10) cray-libsci/24.11.0
    11) PrgEnv-cray/8.6.0
    12) ModuleLabel/label                             (S)
    13) lumi-tools/24.05                              (S)
    14) init-lumi/0.2                                 (S)

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ```

    Environment variable CRAY_CC_VERSION: `18.0.1`.

    Now doing a `module unload cce`:

    ```


    Inactive Modules:
    1) cray-libsci     2) cray-mpich


    ```

    Environment variable CRAY_CC_VERSION: ``. This should be empty

    Now executing a 'module purge':

    ```

    The following modules were not unloaded:
    (Use "module --force purge" to unload all):

    1) ModuleLabel/label   2) lumi-tools/24.05   3) init-lumi/0.2

    The following sticky modules could not be reloaded:

    1) lumi-tools

    ```



    Environment variable CRAY_CC_VERSION: ``.

    Now executing `module load cce`':

    ```


    ```

    And listing the modules with 'module list':

    ```

    Currently Loaded Modules:
    1) ModuleLabel/label (S)   3) init-lumi/0.2 (S)
    2) lumi-tools/24.05  (S)   4) cce/18.0.1

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ````



    Environment variable CRAY_CC_VERSION: `18.0.1`.

    Now executing a 'module purge' again:

    ```
    
    The following modules were not unloaded:
    (Use "module --force purge" to unload all):

    1) ModuleLabel/label   2) lumi-tools/24.05   3) init-lumi/0.2

    The following sticky modules could not be reloaded:

    1) lumi-tools

    ```

    List of modules currently loaded (should be almost empty):

    ```

    Currently Loaded Modules:
    1) ModuleLabel/label (S)   2) lumi-tools/24.05 (S)   3) init-lumi/0.2 (S)

    Where:
    S:  Module is Sticky, requires --force to unload or purge
    ```



    Environment variable CRAY_CC_VERSION: ``.



    **Trying an srun...**


    Check if we still now the path to the container via the SIFCCPE environment variable:
    `/users/kurtlust/LUMI-user/SW/container/ccpe/24.11-LUMI/cpe_2411.sif`

    Before calling `srun`, we need to unset `SLURM_EXPORT_ENV` to avoid propagation of the `--export` option that we used for the batch script.

    Now calling srun, excuting a `module list`, then print the value of `CRAY_CC_VERSION`, then `module load cce` and finally print the value of `CRAY_CC_VERSION` again.
    We would like to to see the small list of modules from above again, then an empty variable and then the CCE version from the container.


    ```
    0: 
    0: Currently Loaded Modules:
    0:   1) ModuleLabel/label (S)   2) lumi-tools/24.05 (S)   3) init-lumi/0.2 (S)
    0: 
    0:   Where:
    0:    S:  Module is Sticky, requires --force to unload or purge
    0: Before loading cce: CRAY_CC_VERSION=
    0: After loading cce: CRAY_CC_VERSION=18.0.1, should be the container version.
    1: 
    1: Currently Loaded Modules:
    1:   1) ModuleLabel/label (S)   2) lumi-tools/24.05 (S)   3) init-lumi/0.2 (S)
    1: 
    1:   Where:
    1:    S:  Module is Sticky, requires --force to unload or purge
    1: Before loading cce: CRAY_CC_VERSION=
    1: After loading cce: CRAY_CC_VERSION=18.0.1, should be the container version.

    ```




## Remarks for further development

Testing for LUMI:

    Perhaps a test for the container running somewhere "OK" would be to bind mount /sys/class/cxi/cxi0/device or a performance counter into the container and look for contents of a file.
    
    Anything clever will stop you testing the container in a VM, which you might want to do.

Alternative for changing the Lmod cache could be to bind mount a different directory?

-   But may need to make sure that it exists in the first place, or the bind mount may fail?



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

7.  `ccpe-run` with arguments test

    ```bash
    ccpe-run -i -c 'module list'
    ```

8.  `ccpe-singularity` test

    ```bash
    ccpe-singularity exec "$SIFCCPE" bash -c 'eval $INITCCPE ; module list'
    ```

    should again show all modules you'd expect at the container setup as in previous tests, and then return 
    to the command prompt outside the container.
 
    The same should be the case for

    ```bash
    ccpe-singularity exec "$SIFCCPE" bash -i -c 'module list'
    ```

