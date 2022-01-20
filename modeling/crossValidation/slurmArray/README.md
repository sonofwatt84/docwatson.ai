This is a cross-validatation script that's designed to take advantage of SLURM arrays on an HPC.  By dispatching jobs via SLURM, and potentially using local parallelization via the OS and model libraries on each node, this method is capable of fast, efficient, and reliable validation.  

This code is written for the UConn HPC, so it probably won't work in your environment without modification.
