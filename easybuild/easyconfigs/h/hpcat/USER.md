# User instructions for hpcat.


Example `hpcat`:

```
salloc -N2 -pstandard-g -G 16 -t 10:00
module load LUMI/24.03 partition/G hpcat/0.4-cpeGNU-24.03
srun -n16 -c7 bash -c 'ROCR_VISIBLE_DEVICES=$SLURM_LOCALID OMP_NUM_THREADS=7 hpcat'
srun -n16 -c7 \
    --cpu-bind=mask_cpu:0xfe000000000000,0xfe00000000000000,0xfe0000,0xfe000000,0xfe,0xfe00,0xfe00000000,0xfe0000000000 \
    bash -c 'ROCR_VISIBLE_DEVICES=$SLURM_LOCALID OMP_NUM_THREADS=7 hpcat'
```

Note that in the first `srun` command, the mapping of resources is not very good. GPUs 
don't map to their closest chiplet, and the network adapters are also linked based 
on the CPU NUMA domain. In the second case, the mapping is optimal.
