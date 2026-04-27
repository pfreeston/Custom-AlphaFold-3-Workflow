#!/bin/bash
# profiles/slurm/jobscript.sh

# Load required modules
module load Anaconda3/2025.06-1
module load Singularity

# Activate your environment
conda activate af3-custom-workflow

# Run Snakemake job
{exec_job}