import os
import glob


def name_from_path(p):
    return os.path.basename(p).replace(".fasta", "")


def get_proteins(config):
    fasta_root = config["paths"]["fasta_root"]
    files = glob.glob(os.path.join(fasta_root, "**/*.fasta"), recursive=True)

    return {name_from_path(f): f for f in files}


def get_pairs(config, proteins):
    if config["workflow"]["mode"] != "multimer":
        return []

    strategy = config["workflow"]["pairing_strategy"]

    left_group = config["selection"]["left_group"]
    right_group = config["selection"]["right_group"]

    left = {k: v for k, v in proteins.items() if left_group in v}
    right = {k: v for k, v in proteins.items() if right_group in v}

    if strategy == "all_vs_all":
        return [(l, r) for l in left for r in right]  # noqa: E741

    elif strategy == "one_vs_many":
        query = config["selection"]["query_name"]
        return [(query, r) for r in right]

    else:
        raise ValueError(f"Unknown pairing strategy: {strategy}")