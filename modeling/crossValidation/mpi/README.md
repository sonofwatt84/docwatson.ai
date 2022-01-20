This is a leave-one-group-out (LOGO) cross-validation script that uses MPI for multithreading and BART for modeling.  The code was written for the UConn HPC and probably won't completely work in another context.

MPI is a great scalable way to get work done fast in parallel, but using BART here can be tricky because it can be memory intensive.  If used in application make sure you reserse the correct number of resources for each node via SLURM.
