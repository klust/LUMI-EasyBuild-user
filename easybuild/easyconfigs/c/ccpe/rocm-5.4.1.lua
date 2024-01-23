--[[

    file rocm module

    (C) Copyright 2020 Hewlett Packard Enterprise Development LP.
    UNPUBLISHED PROPRIETARY INFORMATION.
    ALL RIGHTS RESERVED.

]]--


-- NOTE 1:
--[[............................................................................
    Every rocm* module needs this line. Instead of doing separate conflicts an
    Lmod family will let only one family member be loaded at any given time.
    Modules in family: amd-gpu
    ............................................................................--]]
family("rocm")
conflict("rcom")


-- local vars: define & assign --


-- template variables ----------------------------------------------------------
local MOD_LEVEL            = "5.4.1-2.6_20230412035049__g59e77d20e51e"
local MOD_MAJOR_VERSION    = "5"
local MOD_MINOR_VERSION    = "4"
--------------------------------------------------------------------------------

local ROCM_PATH     = "/opt/rocm"
local ROCM_INCLUDE_PATH = "-I" .. ROCM_PATH .. "/include -I" .. ROCM_PATH .. "/rocprofiler/include -I" .. ROCM_PATH .. "/roctracer/include -I" .. ROCM_PATH .. "/hip/include"
local ROCM_LD_PATH = "-L" .. ROCM_PATH .. "/lib64 -L" .. ROCM_PATH .. "/lib -L" .. ROCM_PATH .. "/rocprofiler/lib -L" .. ROCM_PATH .. "/rocprofiler/tool -L" .. ROCM_PATH .. "/roctracer/lib -L" .. ROCM_PATH .. "/roctracer/tool -L" .. ROCM_PATH .. "/hip/lib"
local ROCM_LD_LIBRARY_PATH = ROCM_PATH .. "/lib64:" .. ROCM_PATH .. "/lib:" .. ROCM_PATH .. "/rocprofiler/lib:" .. ROCM_PATH .. "/rocprofiler/tool:" .. ROCM_PATH .. "/roctracer/lib:" .. ROCM_PATH .. "/roctracer/tool:" .. ROCM_PATH .. "/hip/lib"

-- NOTE 2:
--[[............................................................................
    Below variables were never used in TCL consider deleting
    set _module_name [module-info name]
    set is_module_rm [module-info mode remove]
............................................................................--]]


-- standard Lmod functions --


help([[

The module file defines the system paths and variables for the ROCm Toolkit.


]])

-- NOTE 3: Took a liberty and implemented the "whatis function"
whatis("The module file defines the system paths and variables for the ROCm Toolkit.")


-- environment modifications --


setenv (    "CRAY_ROCM_VERSION",          MOD_LEVEL              )
setenv (    "CRAY_ROCM_DIR",              ROCM_PATH    )
setenv (    "CRAY_ROCM_PREFIX",           ROCM_PATH    )
setenv (    "CRAY_ROCM_INCLUDE_OPTS",     ROCM_INCLUDE_PATH .. "-D_HIP_PLATFORM_HCC__" )
setenv (    "CRAY_ROCM_POST_LINK_OPTS",   ROCM_LD_PATH .. "-lamdhip64" )

setenv (    "ROCM_PATH",                  ROCM_PATH    )
setenv (    "XTPE_LINK_TYPE",             "dynamic"              )
setenv (    "CRAYPE_LINK_TYPE",           "dynamic"              )


prepend_path (    "CRAY_LD_LIBRARY_PATH",  ROCM_LD_LIBRARY_PATH )
prepend_path (    "LD_LIBRARY_PATH",      ROCM_LD_LIBRARY_PATH )
prepend_path (    "PATH",                 ROCM_PATH .. "/bin:" .. ROCM_PATH .. "/rocprofiler/bin:" .. ROCM_PATH ..  "/hip/bin"     )
prepend_path (    "MANPATH",              ROCM_PATH .. "/share/man"    )

append_path  (    "PE_PRODUCT_LIST",      "CRAY_ROCM"                   )

prepend_path ( "PKG_CONFIG_PATH",         "/usr/lib64/pkgconfig" )
prepend_path ( "PE_PKGCONFIG_LIBS", "rocm-" .. MOD_MAJOR_VERSION .. "." .. MOD_MINOR_VERSION )
