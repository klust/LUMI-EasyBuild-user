# tabulate-pranov technical information

As this seems to be a rather little known header library and as we suspect there are
many packages that are called `tabulate`, we've chosen to call this one `tabulate-pranav`.

-   [tabulate GitHub](https://github.com/p-ranav/tabulate)

    -   [Releases via GitHub tags](https://github.com/p-ranav/tabulate/tags)
    

## EasyBuild

At the time of first installation on LUMI, the package was not found in either EasyBuild
or Spack.


### Version 1.5 for LUMI/23.09

-   The EasyConfig was developed specifically for LUMI as there were no prior ones. 

-   As this is a pure header file library, it is built with the SYSTEM toolchain so
    that it can be used with all CPE toolchains.
