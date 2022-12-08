# User instructions for LIKWID.

!!! note "System support"
    LIKWID 5.2.2 does not yet fully support the zen3 architecture and does
    not support AMD GPUs. Hence the tool may not fully function on LUMI.
    
    We do not problems with `likwid-topology` even on zen2, as the dies are not
    correctly reported. Hence it is to be expected that `likwid-pin` may not
    always function as expected either, at least when specifying at the level
    of dies (which is not that useful anyway as on the compute nodes the dies
    corresponds with the outer cache domains anyway).
    
    Moreover, the performance measuring tool requires access to the performance
    counters. This access is not permanent on LUMI and is turned off whenever a
    security issue in the Linux kernel that can be exploited through the performance
    counter access appears.
    
The documentation of  LIKWID is available in the [likwid wiki](https://github.com/RRZE-HPC/likwid/wiki)
on the [likwid GitHub[(https://github.com/RRZE-HPC/likwid). The tool is frequently 
used in courses on node level performance engineering lectured by Georg Hager and
Gerhard Wellein of the 
[Erlangen National High Performace Computing Center NHR@FAU](https://hpc.fau.de/),
also in European programs.

There are also some training movies on the [NHR@FAU YouTube channel](https://www.youtube.com/@NHRFAU),
including:

-   [A short overview of the LIKWID tool suite](https://www.youtube.com/watch?v=6uFl1HPq-88)
-   [How to use likwid-topoplogy](https://www.youtube.com/watch?v=mxMWjNe73SI)
-   [How to use likwid-pin](https://www.youtube.com/watch?v=PSJKNQaqwB0)
-   [How to use likwid-pin (extended version)](https://www.youtube.com/watch?v=IKW0kRLnhyc)
-   And other videos in the [LIKWID PlayList](https://www.youtube.com/watch?v=6uFl1HPq-88&list=PLxVedhmuwLq2CqJpAABDMbZG8Whi7pKsk)
