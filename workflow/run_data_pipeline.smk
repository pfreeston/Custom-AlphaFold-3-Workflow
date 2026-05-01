configfile: "config/project.yaml"

from pathlib import Path
from af3custom.targets import get_proteins

proteins = get_proteins(config)
protein_names = sorted(proteins.keys())

JSON_DIR = config["paths"]["json_input_dir"]
PIPELINE_DIR = config["paths"]["json_pipeline_dir"]

rule all:
    input:
        expand(f"{PIPELINE_DIR}/{{name}}", name=protein_names)

rule make_monomer_json:
    input:
        fasta=lambda wc: proteins[wc.name]
    output:
        json=f"{JSON_DIR}/{{name}}.json"
    params:
        outdir=JSON_DIR
    threads: 1
    run:
        from af3custom.monomer_json_builder import write_monomer_json
        Path(params.outdir).mkdir(parents=True, exist_ok=True)
        write_monomer_json(wildcards.name, input.fasta, params.outdir)

rule data_pipeline:
    input:
        json=f"{JSON_DIR}/{{name}}.json"
    output:
        outdir=directory(f"{PIPELINE_DIR}/{{name}}")
    params:
        image=config["af3"]["image"],
        db_dir=config["af3"]["db_dir"]
    shell:
        r"""
        mkdir -p {output.outdir}
        singularity exec \
            --bind {params.db_dir}:/root/public_databases \
            --bind {output.outdir}:/root/af_output \
            --bind {JSON_DIR}:/root/af_input \
            {params.image} \
            python3 /app/alphafold/run_alphafold.py \
            --json_path=/root/af_input/{wildcards.name}.json \
            --db_dir=/root/public_databases \
            --output_dir=/root/af_output \
            --run_data_pipeline=true \
            --run_inference=false
        """