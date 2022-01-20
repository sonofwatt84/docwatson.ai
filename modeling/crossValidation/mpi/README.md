This is a leave-one-group-out (LOGO) cross-validation script that uses MPI for multithreading and BART for modeling.

MPI is a great scalable way to get work done fast in parallel, but BART isn't actually a great model for this application because it can be memory intensive.  If used in application make sure you reserse the correct number of resources for each node via SLURM.
