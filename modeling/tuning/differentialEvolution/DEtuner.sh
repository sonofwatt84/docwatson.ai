#!/bin/bash
#SBATCH --ntasks=51 # Number of MPI ranks
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
#SBATCH -p HaswellPriority
#SBATCH --mail-type=END                       # Event(s) that triggers email notification (BEGIN,END,FAIL,ALL)
#SBATCH --error DEoptim.err


# Manage Modules
module purge
module load java/1.8.0_162 gcc/5.4.0-alt zlib/1.2.11 bzip2/1.0.6 libpcre/8.38 libcurl/7.49.1 xz/5.2.2-gcc540 
module load r/3.4.2-gcc540 libjpeg-turbo/1.1.90 proj/4.9.2 geos/3.5.0 mpi/openmpi/3.1.0-gcc  

# Run Script
mpirun -np 1 Rscript --no-save DEtuner.R > DEtuner.Rlog 
