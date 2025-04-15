# lzip-tools technical information

-   lzip:
    
    -   [Home page](https://www.nongnu.org/lzip/)
    
    -   [Downloads](https://download.savannah.gnu.org/releases/lzip/)
    
-   lunzip:

    -   [Home page](https://www.nongnu.org/lzip/lunzip.html)
    
    -   [Downloads](https://download.savannah.gnu.org/releases/lzip/lunzip/)

-   lziprecover:

    -   [Home page](https://www.nongnu.org/lzip/lziprecover.html)
    
    -   [Downloads](https://download.savannah.gnu.org/releases/lzip/lziprecover/)
   
-   plzip:

    -   [Home page](https://www.nongnu.org/lzip/plzip.html)
    
    -   [Downloads](https://download.savannah.gnu.org/releases/lzip/plzip/)
    
-   tarlz:

    -   [Home page](https://www.nongnu.org/lzip/tarlz.html)
    
    -   [Downloads](https://download.savannah.gnu.org/releases/lzip/tarlz/)
    
-   Zutils:

    -   [Home page](https://www.nongnu.org/zutils/zutils.html)
    
    -   [Downloads](https://quantum-mirror.hu/mirrors/pub/gnusavannah/zutils/)
    
-   lzlib: Library needed to build some of these tools:

    -   [Home page](https://www.nongnu.org/lzip/lzlib.html)
    
    -   [Downloads](https://download.savannah.gnu.org/releases/lzip/lzlib/) 

    
## EasyBuild

-   At the time of development, there was no support for lzip in EasyBuild
    
-   There is no support in Spack for lzip.
    
    
### lzip-tools for LUMI/24.03
    
-   The EasyConfig is a LUST development. All packages have a very simple 
    configure-make build process so developing a Bundle was easy.
    
-   Two components are only distributed in lzip format. Hence we needed a special
    bootstrapping process:
    
    ```bash
    module load LUMI/24.03 partition/common EasyBuild-user
    eb lzip-bootstrap-1.25.eb
    module load lzip-bootstrap/1.25
    eb lzip-tools-24.03.eb
    ```
    
    This is only a temporary solution. We will investigate if we can build support
    for lzip into the EasyBuild module or another module that is centrally installed
    and whose presence is ignored by EasyBuild.

    Note that EasyBuild does not know the `.tar.lz` format and hence we needed to use
    `extract_cmd`.
 