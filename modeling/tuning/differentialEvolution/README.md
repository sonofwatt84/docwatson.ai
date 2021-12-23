# Optimization with Differential Evolution

This is a script for optimizing hyperparameters of an ML model using Differential Evolution (DE), and optimized with MPI.  

![diffEvDemo](https://upload.wikimedia.org/wikipedia/commons/e/e0/Ackley.gif)

Differential Evolution is pretty computationally expensive, but it's robust to local minimums, and doesn't require much adjustment or tuning so it's particularly well suited for ML hyperparameter searches.

This example tunes a GBM model using DE, and it designed for use with SLURM in an HPC environment.
