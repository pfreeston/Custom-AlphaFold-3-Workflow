configfile: "config/project.yaml"

from pathlib import Path
from scripts.targets import get_proteins

proteins = get_proteins(config)
protein_names = sorted(proteins.keys())

JSON_DIR = config["paths"]["json_input_dir"]

rule all:
    input:
        expand("{json_dir}/{name}.json", json_dir=JSON_DIR, name=protein_names)

rule make_monomer_json:
    input:
        fasta=lambda wc: proteins[wc.name]
    output:
        json="{json_dir}/{name}.json"
    params:
        outdir=JSON_DIR
    threads: config["resources"]["json_build"]["cpus"]
    run:
        from scripts.monomer_json_builder import write_monomer_json
        Path(params.outdir).mkdir(parents=True, exist_ok=True)
        write_monomer_json(wildcards.name, input.fasta, params.outdir)