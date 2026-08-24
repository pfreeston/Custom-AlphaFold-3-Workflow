# Custom-AlphaFold-3-Workflow

A custom AlphaFold 3 workflow for use on the HPC by Phoebe Freeston.

## Getting set up on the HPC

Activate an interactive session by running

```         
srun -p interactive -c 1 -t 60 --pty /bin/bash
```

## Cloning the Custom AlphaFold 3 Workflow on the HPC

## Setting up your environment

Go to the repo

```         
cd cloned/repo/location
```

Activating Conda

```         
module spider Anaconda
module load <latest version>
```

Ensure you have the correct channels

```         
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
```

Create virtual environment using the env/af3-custom-workflow.yaml
'''
conda env create -f af3-custom-workflow.yaml 
'''

...

Activate virtual environment

```         
conda activate af3-custom-workflow
```

## Running the first prediction

```         
snakemake   --snakefile workflow/Snakefile   --executor slurm   --configfile config/project.yaml   --config workflow="{mode: multimer}"   --jobs 20   -p   --default-resources   slurm_extra="--account=dops-plant-genomics --mail-user=phoebe.freeston@biology.ox.ac.uk"
```

test with:
snakemake \
  --snakefile workflow/Snakefile \
  --executor slurm \
  --configfile config/project.yaml \
  --config 'workflow={mode: multimer}' \
  --jobs 1 \
  -p \
  --default-resources \
  slurm_account=dops-plant-genomics \
  slurm_extra="--mail-user=phoebe.freeston@biology.ox.ac.uk" \
  -n

  gives:
  