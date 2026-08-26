# Custom AlphaFold 3 Workflow

A Snakemake workflow for running **AlphaFold 3 (AF3)** predictions on a SLURM-managed HPC cluster.

This workflow was developed for the University of Oxford Advanced Research Computing (ARC) service. It automates the main stages required to run AlphaFold 3 predictions, including:

- generating AlphaFold 3 input JSON files from FASTA sequences;
- running the AlphaFold 3 data pipeline;
- constructing multimer input JSONs from processed monomers;
- running GPU inference;
- submitting and managing jobs through SLURM using Snakemake.

The workflow currently supports both **monomer** and **multimer** predictions.

---

## Workflow overview

### Monomer mode

```text
FASTA
  │
  ▼
Generate monomer JSON
  │
  ▼
AF3 data pipeline
  │
  ▼
AF3 inference
  │
  ▼
outputs/<protein>/
```

### Multimer mode

```text
FASTA files
     │
     ▼
Generate monomer JSONs
     │
     ▼
AF3 data pipeline
     │
     ▼
Build paired multimer JSONs
     │
     ▼
AF3 inference
     │
     ▼
outputs/<protein1>__<protein2>/
```

For multimer predictions, the expensive AF3 data pipeline is therefore performed on the individual proteins before the processed inputs are combined for inference.

---

# 1. Prerequisites

This workflow assumes access to:

- a Linux HPC system using **SLURM**;
- **Singularity/Apptainer**;
- an AlphaFold 3 container image;
- the AlphaFold 3 model parameters;
- the AlphaFold 3 sequence databases;
- Conda/Anaconda;
- GPU compute nodes for the inference stage.

On Oxford ARC, GPU jobs must run on the **HTC cluster**.

You must also have permission to access the AlphaFold 3 model parameters. These are not distributed with this repository.

---

# 2. Clone the repository

Log in to the HPC.

For Oxford ARC:

```bash
ssh <username>@htc-login.arc.ox.ac.uk
```

If connecting from outside the University network, connect to the Oxford VPN first or use the ARC gateway as appropriate.

Clone this repository:

```bash
git clone https://github.com/pfreeston/Custom-AlphaFold-3-Workflow.git
cd Custom-AlphaFold-3-Workflow
```

The repository should contain:

```text
Custom-AlphaFold-3-Workflow/
├── af3custom/
│   ├── __init__.py
│   ├── monomer_json_builder.py
│   ├── multimer_json_builder.py
│   └── targets.py
├── config/
│   ├── project.yaml
│   └── samples.yaml
├── env/
│   └── af3-custom-workflow.yaml
├── inputs/
│   └── fastas/
├── workflow/
│   └── Snakefile
└── README.md
```

---

# 3. Create the Conda environment

Do **not** perform a large Conda installation directly on an ARC login node.

Start an interactive session:

```bash
srun -p interactive --pty /bin/bash
```

Find the available Anaconda modules:

```bash
module spider Anaconda
```

Load an appropriate Anaconda 3 module, for example:

```bash
module load Anaconda3/<version>
```

The supplied environment file contains the dependencies required to run the workflow:

```text
python=3.11
snakemake-minimal
pyyaml
snakemake-executor-plugin-slurm
```

Create the environment:

```bash
conda env create -f env/af3-custom-workflow.yaml
```

Activate it:

```bash
conda activate af3-custom-workflow
```

Check the installation:

```bash
snakemake --version
```

You should also check that the SLURM executor plugin is available:

```bash
snakemake --help
```

---

# 4. Configure AlphaFold 3 paths

Before running the workflow, edit:

```text
config/project.yaml
```

The important AF3 settings are:

```yaml
af3:
  image: /path/to/alphafold3_custom.sif
  model_dir: /path/to/alphafold3/model
  db_dir: /path/to/alphafold3/public_databases
```

Change these paths for your account/HPC installation.

For the current Oxford ARC installation, the model and database locations used during development are:

```yaml
model_dir: /apps/common/commercial/AlphaFold3/model
db_dir: /apps/datasets/alphafold3/public_databases
```

The container path is user-specific and **must be changed** unless you have access to the container at the path currently specified in `project.yaml`.

---

# 5. Add input FASTA files

Place protein FASTA files underneath:

```text
inputs/fastas/
```

FASTA files may be organised into subdirectories. The workflow searches recursively for files ending in:

```text
.fasta
```

For example:

```text
inputs/fastas/
├── plants/
│   ├── p69b.fasta
│   ├── rcr3.fasta
│   └── pip1.fasta
└── pathogens/
    ├── epi1a.fasta
    ├── epi1b.fasta
    └── avr2.fasta
```

The filename is used as the protein name and must be lower case. 

For example:

```text
p69b.fasta
```

becomes:

```text
p69b
```

Avoid duplicate FASTA filenames in different subdirectories, because protein names are derived from the filename rather than the complete path.

A minimal FASTA should look like:

```text
>P69B
MSEQUENCE...
```

---

# 6. Choose the workflow mode

The workflow supports:

```yaml
workflow:
  mode: monomer
```

or:

```yaml
workflow:
  mode: multimer
```

This can be set permanently in `config/project.yaml` or overridden when Snakemake is run.

---

# 7. Running monomer predictions

Set:

```yaml
workflow:
  mode: monomer
```

or override it on the command line.

First perform a **dry run**:

```bash
snakemake \
  --snakefile workflow/Snakefile \
  --executor slurm \
  --configfile config/project.yaml \
  --config 'workflow={mode: monomer}' \
  --jobs 20 \
  -n \
  -p
```

`-n` tells Snakemake not to execute anything.

`-p` prints the commands that would be executed.

Inspect the proposed jobs before submitting them.

If the dry run looks correct, remove `-n`:

```bash
snakemake \
  --snakefile workflow/Snakefile \
  --executor slurm \
  --configfile config/project.yaml \
  --config 'workflow={mode: monomer}' \
  --jobs 20 \
  -p
```

---

# 8. Running multimer predictions

Multimer mode first processes the individual proteins and then constructs multimer JSONs for selected protein pairs.

Set:

```yaml
workflow:
  mode: multimer
```

The workflow currently supports two pairing strategies:

### All-vs-all

```yaml
workflow:
  mode: multimer
  pairing_strategy: all_vs_all

selection:
  left_group: plants
  right_group: pathogens
```

Proteins whose FASTA paths contain `plants` are paired with proteins whose paths contain `pathogens`.

For example:

```text
plants/p69b.fasta
plants/rcr3.fasta

pathogens/epi1a.fasta
pathogens/epi1b.fasta
```

produces:

```text
p69b__epi1a
p69b__epi1b
rcr3__epi1a
rcr3__epi1b
```

### One-vs-many

To compare one protein against every protein in another group:

```yaml
workflow:
  mode: multimer
  pairing_strategy: one_vs_many

selection:
  left_group: plants
  right_group: pathogens
  query_name: p69b
```

This produces predictions such as:

```text
p69b__epi1a
p69b__epi1b
p69b__avr2
```

The value of `query_name` must match the FASTA filename without `.fasta`.

---

# 9. Dry-run the multimer workflow

Always dry-run the workflow before submitting a large set of jobs:

```bash
snakemake \
  --snakefile workflow/Snakefile \
  --executor slurm \
  --configfile config/project.yaml \
  --config 'workflow={mode: multimer}' \
  --jobs 20 \
  -n \
  -p
```

For testing a single prediction, you can specify the desired final output explicitly:

```bash
snakemake \
  --snakefile workflow/Snakefile \
  --executor slurm \
  --configfile config/project.yaml \
  --config 'workflow={mode: multimer}' \
  --jobs 1 \
  -n \
  -p \
  outputs/p69b__epi1a
```

This is particularly useful when checking a new installation.

---

# 10. Submit the workflow

Once the dry run is correct:

```bash
snakemake \
  --snakefile workflow/Snakefile \
  --executor slurm \
  --configfile config/project.yaml \
  --config 'workflow={mode: multimer}' \
  --jobs 20 \
  -p
```

`--jobs 20` allows Snakemake to have up to 20 jobs active/submitted concurrently.

Adjust this value depending on the size of the experiment and local HPC policy.

---

# 11. SLURM resources

The workflow submits different stages with different resource requirements.

## Data pipeline

The AF3 data-pipeline rule currently requests approximately:

```text
8 CPUs
64 GB RAM
2 hours
short partition
```

The data pipeline does not request a GPU.

## Inference

The inference rule currently requests:

```text
8 CPUs
64 GB RAM
2 hours
1 × H100 GPU
short partition
HDR/HDR100 fabric
```

The GPU request is:

```text
gpu:h100:1
```

These settings are specific to the Oxford ARC/HTC environment and may need to be changed for another HPC system.

The current workflow also contains a SLURM account setting for:

```text
dops-plant-genomics
```

If you are not submitting under this project, change the SLURM account in `workflow/Snakefile` before running the workflow.

---

# 12. Output structure

Intermediate files are written under:

```text
work/
```

Final predictions are written under:

```text
outputs/
```

Logs are written under:

```text
logs/
```

A typical run will produce something similar to:

```text
work/
└── json/
    ├── monomers/
    ├── multimers/
    └── pipeline/

logs/
├── data_pipeline/
└── inference/

outputs/
├── p69b__epi1a/
├── p69b__epi1b/
└── ...
```

For monomer mode:

```text
outputs/
├── p69b/
├── rcr3/
└── ...
```

---

# 13. Monitoring jobs

Snakemake submits jobs to SLURM.

To see your jobs:

```bash
squeue -u $USER
```

For more detailed information about a completed job:

```bash
sacct -j <jobid>
```

Snakemake's own output will also report job submission and completion.

Workflow-specific logs can be found in:

```text
logs/data_pipeline/
logs/inference/
```

For example:

```bash
less logs/data_pipeline/p69b.log
```

or:

```bash
less logs/inference/p69b__epi1a.log
```

---

# 14. Re-running the workflow

One advantage of using Snakemake is that successfully generated outputs are not normally recomputed unnecessarily