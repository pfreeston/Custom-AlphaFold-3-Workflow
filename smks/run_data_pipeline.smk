configfile: "config/project.yaml"

from pathlib import Path
from af3custom.targets import get_proteins

proteins = get_proteins(config)
protein_names = sorted(proteins.keys())

JSON_DIR = config["paths"]["json_input_dir"]
PIPELINE_DIR = config["paths"]["json_pipeline_dir"]

rule all:
    input:
        expand("work/json/pipeline/{name}", name=protein_names)

rule make_monomer_json:
    input:
        fasta=lambda wc: proteins[wc.name]
    output:
        json="{json_dir}/{name}.json"
    params:
        outdir=JSON_DIR
    run:
        from af3custom.monomer_json_builder import write_monomer_json
        Path(params.outdir).mkdir(parents=True, exist_ok=True)
        write_monomer_json(wildcards.name, input.fasta, params.outdir)

rule data_pipeline:
    input:
        json="work/json/input/{name}.json"
    output:
        outdir=directory("work/json/pipeline/{name}")
    params:
        image=config["af3"]["image"],
        db_dir=config["af3"]["db_dir"]
    shell:
        r"""
        mkdir -p {output.outdir}
        singularity exec \
            --bind {params.db_dir}:/root/public_databases \
            --bind {output.outdir}:/root/af_output \
            --bind work/json/input:/root/af_input \
            {params.image} \
            uv run python3 /app/alphafold/run_alphafold.py \
            --json_path=/root/af_input/{wildcards.name}.json \
            --db_dir=/root/public_databases \
            --output_dir=/root/af_output \
            --run_data_pipeline=true \
            --run_inference=false
        """