#!/bin/bash
# profiles/slurm/jobscript.sh

# Load required modules
module load Anaconda3
module load Singularity

# Activate your environment
conda activate af3-workflow

# Run Snakemake job
{exec_job}