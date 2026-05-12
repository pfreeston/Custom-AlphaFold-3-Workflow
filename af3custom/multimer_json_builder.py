from pathlib import Path
import json
import copy

from af3custom.targets import get_proteins, get_pairs

def load_single_chain(path: Path):
    data = json.loads(path.read_text())

    if len(data["sequences"]) != 1:
        raise ValueError(f"{path} is not a single-chain AF3 JSON")

    return data, copy.deepcopy(data["sequences"][0])


def set_chain_id(chain_obj, chain_id):
    chain_obj = copy.deepcopy(chain_obj)
    chain_obj["protein"]["id"] = chain_id
    return chain_obj


def build_single_multimer_json(config, p1, p2):
    pipeline_dir = Path(config["paths"]["json_pipeline_dir"])
    outdir = Path(config["paths"]["multimer_json_dir"])
    outdir.mkdir(parents=True, exist_ok=True)

    path1 = find_pipeline_json(pipeline_dir, p1)
    path2 = find_pipeline_json(pipeline_dir, p2)

    data1, chain1 = load_single_chain(path1)
    data2, chain2 = load_single_chain(path2)

    merged = {
        "name": f"{p1}__{p2}",
        "dialect": "alphafold3",
        "version": 2,
        "sequences": [
            set_chain_id(chain1, "A"),
            set_chain_id(chain2, "B"),
        ],
        "modelSeeds": data1.get("modelSeeds", [1]),
    }

    outpath = outdir / f"{p1}__{p2}.json"
    outpath.write_text(json.dumps(merged, indent=2))

    return outpath


def find_pipeline_json(pipeline_dir: Path, name: str) -> Path:
    inner = name.lower()
    matches = list(pipeline_dir.glob(f"{name}/{inner}/{inner}_data.json"))

    if not matches:
        raise FileNotFoundError(f"No pipeline JSON found for {name}")

    return matches[0]

