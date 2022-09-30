# VirtualGL instructions

-   [VirtualGL web site](https://virtualgl.org/)
    
-   [ VirtualGL on GitHub](https://github.com/VirtualGL/virtualgl)
    
    -   [VirtualGL releases](https://github.com/VirtualGL/virtualgl/releases)
    
    
##  EasyBuild

-   [VirtualGL support in the EasyBuilders repository](https://github.com/easybuilders/easybuild-easyconfigs/tree/develop/easybuild/easyconfigs/v/VirtualGL)

-   There is no support for VirtualGL in the CSCS repository.


### Version 3.0.1 for cpeGNU/22.08

-   The EasyConfig is derived from the EasyBuilders one for version 3.0 as no
    newer one was available.
    
-   The OpenCL/OpenGL interoperability feature is currently disabled to avoid 
    having to build the pocl dependency which then requires Clang which then
    requires ...
    
-   The code contains some dirty type casts so the error message advise to 
    turn on `-fpermissive`. 
    
    This however still leaves some conflicting declarations that cannot be masked:
    
    -   `XkbOpenDisplay` in `server/faker-x11.cpp` does not have the `const` attribute
        for the first argument (or `_Xconst`).
    
    
Building the patch:

```
diff -ruN virtualgl-3.0.1/server/faker-x11.cpp.orig virtualgl-3.0.1/server/faker-x11.cpp
```

UNFINBISHED: Cannot find how to use this properly.
