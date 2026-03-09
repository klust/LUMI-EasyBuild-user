# Issues in EESSI

## General impression

-   The initialisation script contains bash-isms so that it cannot be run during a container initialisation.
    Moreover, starting lmod wouldn't make sense when run in that context, though doing other initialisations,
    including of Lmod environment variables, seems to be OK.

    The programming style is also very inconsistent.

-   The initialisation scripts should make a distinction between debug information and information that
    is useful for regular users. By default, debug information should not be shown and it should be shown
    triggered by an environment variable rather than what is happening now. And instead, some user-friendly
    information could be shown unless EESSI_SILENT is defined.

-   We really need a simple program to check how threads and MPI processes are allocated for some quick
    MPI experiments.


## LUMI issues

-   At the moment, we have no trick to start MPI programs and we do not yet support Slurm.

-   EESSI can get confused with the user module cache. This is particularly troublesome in the container,
    where the host applications are not available, while we cannot edit Lmod to use a different cache
    directory.

    It would be much nicer if EESSI had its own user Lmod cache in a different directory. Unfortunately,
    as Lmod is not in the container but in a SquashFS image that is mounted in it, this is far from
    trivial and may require working with overlays instead of bind mounts (and would be tricky again
    whenever EESSI starts a new release).


## General issues, not LUMI-specific

-   In /cvmfs/software.eessi.io/versions/$EESSI_VERSION$/compat/linux/x86_64/etc, mtab is a symbolic link
    to ../proc/self/mounts which does not make sense if the etc subdirectory is not in the root.
    Shouldn't this be /proc/self/mounts, or is this something that is normally resolved with cvmfs tricks
    and is only an error on the LUMI containers?


## Trying to get Slurm to work

### In the Ubuntu container

Forget about it? Too many packages to install to then build Slurm manually, and some packages fail to 
install:

-   `munge` wants to add a group which does not work in Singularity.
-   `python3` cannot find some dependencies, is the Ubuntu 24.04 repository broken?

Instructions that I found:

```
# Install dependencies
sudo apt update
sudo apt install -y build-essential wget munge libmunge-dev \
    libssl-dev libpam0g-dev libreadline-dev python3
# Download and extract Slurm
sudo apt update
sudo apt install -y build-essential wget munge libmunge-dev \
    libssl-dev libpam0g-dev libreadline-dev python3
# Build
# --prefix defines where Slurm will be installed. 
# --sysconfdir is where your slurm.conf should live.
./configure --prefix=/usr --sysconfdir=/etc/slurm --with-munge
make -j$(nproc)
sudo make install
# Post-installation:
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key
sudo systemctl restart munge
```

### Solution

For the client, we could do with fewer packages and also avoid the munge issue.

Moreover, we mount the binaries and, more importantly, `/usr/lib64/slurm`, in the container.
The latter ensures we also have the HPE Slingshot plugin.
