# PyTorch container examples

-   `PyTorch-2.2.0-rocm-5.6.1-python-3.10-singularity-venv-1-20240209.eb`:
    This is an example where we use a Conda environment inside the container,
    but also already add a virtual environment outside the container during
    the installation process. See the module help for instructions: This version
    provides some scripts to start PyTorch, but it still uses 
    `$WITH_CONDA`/`$WITH_VENV`/`$WITH_CONDA_VENV` for initialising the
    environments.
    
    Matching `create_container_vars` in the LMOD `SitePAckage.lua` file at
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

