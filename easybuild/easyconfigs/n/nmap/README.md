# nmap instructions

-   [nmap home page](https://nmap.org/)
    
## EasyBuild

There is no support in the EasyBuild repository at the time of writing.

The nmap code is compiled via Autotools.

### 7.92

Remarks:
-   Still needs old-style PCRE and not PCRE2 so may add that to syslibs
-   What is libssh2 and can we install it safely through EasyBuild? For now
    it uses an internal one.
-   What is pcap?
-   And it looks like a lot of other potential network libraries that can
    be recognized aren't on the system either but that is difficult to figure
    out without clear documentation.
-   The tool also detects libibvers so we may not want to use the binaries after
    the system update.
