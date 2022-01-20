#!/bin/bash
#SBATCH --nodes=1 
#SBATCH --ntasks=2
#SBATCH -p TheAwesomeJobs
#SBATCH --mail-type=END                       # Event(s) that triggers email notification (BEGIN,END,FAIL,ALL)
#SBATCH --mail-user=howdy@doody.com      # Destination email address
#SBATCH --error losoArrary.err
#SBATCH --array=1-XXX #Specify the number of folds in the CV

#Manage Modules - For UConn HPC
module purge
module load java/1.8.0_162 gcc/5.4.0-alt zlib/1.2.11 bzip2/1.0.6 libpcre/8.38 libcurl/7.49.1 xz/5.2.2-gcc540 
module load r/3.4.2-gcc540 libjpeg-turbo/1.1.90 proj/4.9.2 geos/3.5.0 mpi/openmpi/3.1.0-gcc  

# Run Script, Pass Parameters Defined Above to R Script, and Write to Logs
Rscript --no-save --no-restore --verbose CVscript-logoArray.R $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_MAX > logs/cvArray${SLURM_ARRAY_TASK_ID}of${SLURM_ARRAY_TASK_MAX}.Rout 2>&1

