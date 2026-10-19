"""Create repeated training, validation and test trial partitions."""

import pickle
import random
from pathlib import Path

import numpy as np
import pandas as pd


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = next(
    path
    for path in (SCRIPT_DIR, *SCRIPT_DIR.parents)
    if (path / "00_functions" / "rnn_module.py").is_file()
)
output_directory = SCRIPT_DIR
output_directory.mkdir(parents=True, exist_ok=True)

data = pd.read_csv(PROJECT_ROOT / "02_scripts/00_data_preparation/data.csv")

# Test folds, source domains and alternative methods
partition_origins = ["pig", "cat"]

# Sampling of the p target trials
target_sampling_origins = ["cat", "pig"]

alternative_methods = ["CaractAir", "wt", "chamber", "cps"]
n_repetitions = 10
n_folds = 5
p_values = [10, 20, 40, 80]
p_keys = [str(p) for p in p_values] + ["all"]


def split_training_validation(trial_ids, validation_fraction, rng, minimum=0):
    """Split trial IDs into random training and validation subsets."""
    n_validation = max(minimum, int(validation_fraction * len(trial_ids)))
    validation_trial_ids = rng.sample(trial_ids, n_validation)
    validation_set = set(validation_trial_ids)
    training_trial_ids = [
        trial_id for trial_id in trial_ids if trial_id not in validation_set
    ]
    return training_trial_ids, validation_trial_ids


trial_ids_by_dataset = {}

for origin in partition_origins:
    trial_ids_by_dataset[f"all_but_{origin}"] = (
        data[data["fer_origin_origin"] != origin]["eid_tr"].unique().tolist()
    )

    trial_ids_by_dataset[f"micro_met_{origin}"] = (
        data[
            (data["meas_tech_origin"] == "micro met")
            & (data["fer_origin_origin"] == origin)
        ]["eid_tr"]
        .unique()
        .tolist()
    )

    for method in alternative_methods:
        trial_ids_by_dataset[f"{method}_{origin}"] = (
            data[
                (data["meas_tech_origin"] == method)
                & (data["fer_origin_origin"] == origin)
            ]["eid_tr"]
            .unique()
            .tolist()
        )

print("Number of trials by dataset:")
for dataset, trial_ids in trial_ids_by_dataset.items():
    print(f"  {dataset}: {len(trial_ids)}")


# ---------------------------------------------------------------------
### Repeated data splits

test_trial_ids_by_target = {}
training_trial_ids_by_source = {}
validation_trial_ids_by_source = {}
training_trial_ids_by_alternative = {}
validation_trial_ids_by_alternative = {}
training_trial_ids_by_target_mm = {}
validation_trial_ids_by_target_mm = {}

source_domain_values = [f"all_but_{origin}" for origin in partition_origins]
alternative_data_values = [
    f"{method}_{origin}"
    for method in alternative_methods
    for origin in partition_origins
]
target_mm_data_values = [f"micro_met_{origin}" for origin in target_sampling_origins]

for repetition in range(1, n_repetitions + 1):
    print(f"Creating repetition {repetition}/{n_repetitions}...")
    rng = random.Random(repetition)

    test_trial_ids_by_target[repetition] = {}
    training_trial_ids_by_source[repetition] = {}
    validation_trial_ids_by_source[repetition] = {}
    training_trial_ids_by_alternative[repetition] = {}
    validation_trial_ids_by_alternative[repetition] = {}
    training_trial_ids_by_target_mm[repetition] = {}
    validation_trial_ids_by_target_mm[repetition] = {}

    for target_mm_data in [f"micro_met_{origin}" for origin in partition_origins]:
        target_trial_ids = trial_ids_by_dataset[target_mm_data].copy()
        rng.shuffle(target_trial_ids)
        test_trial_ids_by_target[repetition][target_mm_data] = [
            fold.tolist() for fold in np.array_split(target_trial_ids, n_folds)
        ]

    for source_domain in source_domain_values:
        training_ids, validation_ids = split_training_validation(
            trial_ids_by_dataset[source_domain], 0.30, rng
        )
        training_trial_ids_by_source[repetition][source_domain] = training_ids
        validation_trial_ids_by_source[repetition][source_domain] = validation_ids

    for alternative_data in alternative_data_values:
        training_ids, validation_ids = split_training_validation(
            trial_ids_by_dataset[alternative_data], 0.15, rng, minimum=5
        )
        training_trial_ids_by_alternative[repetition][alternative_data] = training_ids
        validation_trial_ids_by_alternative[repetition][alternative_data] = (
            validation_ids
        )

    for target_mm_data in target_mm_data_values:
        training_trial_ids_by_target_mm[repetition][target_mm_data] = {
            p: {} for p in p_keys
        }
        validation_trial_ids_by_target_mm[repetition][target_mm_data] = {
            p: {} for p in p_keys
        }
        all_target_trial_ids = trial_ids_by_dataset[target_mm_data]

        for fold_index in range(n_folds):
            test_trial_ids = test_trial_ids_by_target[repetition][target_mm_data][
                fold_index
            ]
            test_trial_ids_set = set(test_trial_ids)
            available_trial_ids = [
                trial_id
                for trial_id in all_target_trial_ids
                if trial_id not in test_trial_ids_set
            ]

            for p in p_values + ["all"]:
                selected_trial_ids = (
                    available_trial_ids.copy()
                    if p == "all"
                    else rng.sample(available_trial_ids, p)
                )
                training_ids, validation_ids = split_training_validation(
                    selected_trial_ids, 0.15, rng, minimum=5
                )
                p_key = str(p)
                training_trial_ids_by_target_mm[repetition][target_mm_data][p_key][
                    fold_index
                ] = training_ids
                validation_trial_ids_by_target_mm[repetition][target_mm_data][p_key][
                    fold_index
                ] = validation_ids


# ---------------------------------------------------------------------
### Save the data splits

objects_to_save = {
    "test_trial_ids_by_target.pkl": test_trial_ids_by_target,
    "training_trial_ids_by_source.pkl": training_trial_ids_by_source,
    "validation_trial_ids_by_source.pkl": validation_trial_ids_by_source,
    "training_trial_ids_by_alternative.pkl": training_trial_ids_by_alternative,
    "validation_trial_ids_by_alternative.pkl": validation_trial_ids_by_alternative,
    "training_trial_ids_by_target_mm.pkl": training_trial_ids_by_target_mm,
    "validation_trial_ids_by_target_mm.pkl": validation_trial_ids_by_target_mm,
}

for filename, object_to_save in objects_to_save.items():
    with open(output_directory / filename, "wb") as file:
        pickle.dump(object_to_save, file)

print(f"\nData splits saved to: {output_directory}")
