configfile: "config/project.yaml"

from pathlib import Path
import glob

JSON_DIR = config["paths"]["json_input_dir"]
RESULTS_DIR = config["paths"]["results_dir"]

def get_jsons():
    return sorted(glob.glob(f"{JSON_DIR}/*.json"))

json_files = get_jsons()
names = [Path(f).stem for f in json_files]

rule all:
    input:
        expand(f"{RESULTS_DIR}/{{name}}", name=names)

rule run_inference:
    input:
        json=f"{JSON_DIR}/{{name}}.json"
    output:
        outdir=directory(f"{RESULTS_DIR}/{{name}}")
    threads:
        config["resources"]["inference"]["cpus"]
    params:
        image=config["af3"]["image"],
        db_dir=config["af3"]["db_dir"],
        model_dir=config["af3"]["model_dir"]
    shell:
        r"""
        mkdir -p {output.outdir}

        singularity exec \
            --nv \
            --env JAX_PLATFORMS=cuda \
            --bind {params.db_dir}:/root/public_databases \
            --bind {params.model_dir}:/root/models \
            --bind {output.outdir}:/root/af_output \
            --bind {JSON_DIR}:/root/af_input \
            {params.image} \
            python3 /app/alphafold/run_alphafold.py \
            --json_path=/root/af_input/{wildcards.name}.json \
            --model_dir=/root/models \
            --db_dir=/root/public_databases \
            --output_dir=/root/af_output \
            --run_data_pipeline=false \
            --run_inference=true
        """