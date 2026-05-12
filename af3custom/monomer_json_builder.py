import json
import os
import hashlib
from pathlib import Path


def read_fasta_sequence(fasta_path: str) -> str:
    sequence_parts = []

    with open(fasta_path, "r") as handle:
        for line in handle:
            line = line.strip()
            if not line or line.startswith(">"):
                continue
            sequence_parts.append(line)

    sequence = "".join(sequence_parts)
    if not sequence:
        raise ValueError(f"No sequence found in FASTA: {fasta_path}")

    return sequence


def seed_from_name(name: str) -> int:
    return int(hashlib.sha256(name.encode()).hexdigest(), 16) % (2**32)


def build_monomer_json_dict(name: str, fasta_path: str) -> dict:
    sequence = read_fasta_sequence(fasta_path)

    return {
        "name": name,
        "dialect": "alphafold3",
        "version": 2,
        "modelSeeds": [seed_from_name(name)],
        "sequences": [
            {
                "protein": {
                    "id": "A",
                    "sequence": sequence,
                    "unpairedMsa": None,
                    "pairedMsa": None,
                }
            }
        ],
    }


def write_monomer_json(name: str, fasta_path: str, output_dir: str) -> str:
    os.makedirs(output_dir, exist_ok=True)

    json_dict = build_monomer_json_dict(name, fasta_path)
    output_path = Path(output_dir) / f"{name}.json"

    with open(output_path, "w") as handle:
        json.dump(json_dict, handle, indent=2)

    return str(output_path)