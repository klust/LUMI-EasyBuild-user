# PyTorch container examples

-   `PyTorch-2.2.0-rocm-5.6.1-python-3.10-singularity-venv-1-20240209.eb`:
    This is an example where we use a Conda environment inside the container,
    but also already add a virtual environment outside the container during
    the installation process. See the module help for instructions: This version
    provides some scripts to start PyTorch, but it still uses 
    `$WITH_CONDA`/`$WITH_VENV`/`$WITH_CONDA_VENV` for initialising the
    environments.
    
    Example command(s) to check:
    
    -   Import a package that is in the Python virtual environment and check its 
        version just to be sure:
        
        ```
        start-shell -c 'conda-python-simple -c "import torchmetrics ; print( torchmetrics.__version__ )"'
        ```
        
        Calling `conda-python-simple` in this example ensures that the conda and Python virtual 
        environment are correctly initialised before passing its arguments to `python`.
    
    Matching `create_container_vars` in the LMOD `SitePackage.lua` file at
    the time of testing:
    
    ```
    function create_container_vars( sif_file, package_name, installdir, bind )
    
        local SIF_file = get_SIF_file( sif_file, package_name, installdir )    
        local SIF_attributes = lfs.attributes( SIF_file )
    
        if SIF_attributes ~= nil and ( SIF_attributes.mode == 'file' or SIF_attributes.mode == 'link' ) then
            -- The SIF file exists so we can set the environment variables.
            local varname = convert_to_EBvar( package_name, 'SIF' )
            setenv( 'SIF',   SIF_file )
            setenv( varname, SIF_file )
        else
            -- The SIF file does not exist.
            if mode() == 'load' then
                LmodError( 'ERROR: Cannot locate the singularity container file ' .. sif_file ..
                           '. One potential cause is that it may have been removed from the system.' )
            end
        end
    
        if bind ~= nil then
    
            local user_software_squashfs_attributes = lfs.attributes( pathJoin( installdir, 'user-software.squashfs' ) )
            local user_software_dir_attributes =      lfs.attributes( pathJoin( installdir, 'user-software' ) )
    
            if user_software_squashfs_attributes ~= nil and ( user_software_squashfs_attributes.mode == 'file' or user_software_squashfs_attributes.mode == 'link' ) then
    
                setenv( 'SINGULARITY_BIND', bind .. ',' .. pathJoin( installdir, 'user-software.squashfs') .. ':/user-software:image-src=/' )
    
            elseif user_software_dir_attributes ~= nil and ( user_software_dir_attributes.mode == 'directory' or user_software_dir_attributes.mode == 'link' ) then
    
                setenv( 'SINGULARITY_BIND', bind .. ',' .. pathJoin( installdir, 'user-software') .. ':/user-software' )
    
            else -- No user-software as either a squashfs file or a directory
    
                setenv( 'SINGULARITY_BIND', bind )
    
            end
    
        end
    
    end
    ```

-   `PyTorch-2.2.0-rocm-5.6.1-python-3.10-singularity-venv-2-20240209.eb`:
    Version with automatic initialisation of the conda and python virtual environments.

    Example command(s) to check:
    
    -   Import a package that is in the Python virtual environment and check its 
        version just to be sure:
        
        ```
        start-shell -c 'python -c "import torchmetrics ; print( torchmetrics.__version__ )"'
        ```
        
        or
        
        ```
        singularity exec $SIFPYTORCH python -c "import torchmetrics ; print( torchmetrics.__version__ )"
        ```
        
    -   Using `mnist_CPP.py` and `model/model_gpu.dat` from the
        [LUMI ReFrame test repo](https://github.com/Lumi-supercomputer/lumi-reframe-tests/tree/main/checks/containers/ML_containers/src/pytorch/mnist),
        one can run the following jobscript:
        
        ``` bash
        #!/bin/bash -e
        #SBATCH --nodes=4
        #SBATCH --gpus-per-node=8
        #SBATCH --tasks-per-node=8
        #SBATCH --cpus-per-task=7
        #SBATCH --output="output_%x_%j.txt"
        #SBATCH --partition=standard-g
        #SBATCH --mem=480G
        #SBATCH --time=00:15:00
        #SBATCH --account=project_<your_project_id>
        
        module load LUMI  # Which version doesn't matter, it is only to get the container and wget.
        module load wget  # Compute nodes don't have wget preinstalled. Version and toolchain don't matter in this example.
        module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-singularity-venv-2-20240209
        
        # Get the files from the LUMI ReFrame repository
        # It is not recommended to do this in a jobscript but it works to ensure that
        # you get the correct files for the example. And even worse, the example itself
        # downloads a lot more data.
        wget https://raw.githubusercontent.com/Lumi-supercomputer/lumi-reframe-tests/main/checks/containers/ML_containers/src/pytorch/mnist/mnist_DDP.py
        mkdir -p model ; cd model
        wget https://github.com/Lumi-supercomputer/lumi-reframe-tests/raw/main/checks/containers/ML_containers/src/pytorch/mnist/model/model_gpu.dat
        cd ..

        # Optional: Inject the environment variables for NCCL debugging into the container.   
        # This will produce a lot of debug output!     
        export SINGULARITYENV_NCCL_DEBUG=INFO
        export SINGULARITYENV_NCCL_DEBUG_SUBSYS=INIT,COLL

        c=fe
        MYMASKS="0x${c}000000000000,0x${c}00000000000000,0x${c}0000,0x${c}000000,0x${c},0x${c}00,0x${c}00000000,0x${c}0000000000"
        
        srun --cpu-bind=mask_cpu:$MYMASKS \
          singularity exec $SIFPYTORCH \
            conda-python-distributed -u mnist_DDP.py --gpu --modelpath model
        ```
               
