#!/bin/bash
#SBATCH --ntasks=21     # Number of MPI ranks
#SBATCH -p HaswellPriority
#SBATCH --mail-type=END # Event(s) that triggers email notification.  Possible: (BEGIN,END,FAIL,ALL)
#SBATCH --mail-user=howdy@doody.com      # Destination email address for notifications

#Manage Modules - The modules on the UConn HPC are a bit messy...
module purge
module load java/1.8.0_162 gcc/5.4.0-alt zlib/1.2.11 bzip2/1.0.6 libpcre/8.38 libcurl/7.49.1 xz/5.2.2-gcc540 
module load r/3.4.2-gcc540 libjpeg-turbo/1.1.90 proj/4.9.2 geos/3.5.0 mpi/openmpi/3.1.0-gcc  

# Run Script and Export Log
mpirun -np 1 Rscript --no-save bartCVer-MPI.R > bartCVer-MPI.Rlog 
