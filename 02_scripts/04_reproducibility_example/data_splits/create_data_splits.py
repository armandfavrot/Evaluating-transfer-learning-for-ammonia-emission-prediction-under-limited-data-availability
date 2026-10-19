"""Create data splits for the lightweight reproducibility example."""

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

data = pd.read_csv(
    PROJECT_ROOT
    / "02_scripts/00_data_preparation/data_without_caractair.csv"
)
random.seed(1)

fertilizer_origins = ["cat"]
alternative_methods = ["wt"]
n_folds = 10
p_values = [10, 20]


def format_count_range(counts):
    """Format identical counts as one value and varying counts as a range."""
    minimum = min(counts)
    maximum = max(counts)
    return str(minimum) if minimum == maximum else f"{minimum}-{maximum}"


trial_ids_by_dataset = {}

for origin in fertilizer_origins:
    trial_ids_by_dataset[f"all_but_{origin}"] = data[
        data["fer_origin_origin"] != origin
    ]["eid_tr"].unique().tolist()

    trial_ids_by_dataset[f"micro_met_{origin}"] = data[
        (data["meas_tech_origin"] == "micro met")
        & (data["fer_origin_origin"] == origin)
    ]["eid_tr"].unique().tolist()

    for method in alternative_methods:
        trial_ids_by_dataset[f"{method}_{origin}"] = data[
            (data["meas_tech_origin"] == method)
            & (data["fer_origin_origin"] == origin)
        ]["eid_tr"].unique().tolist()

print("Number of trials by dataset:")
for dataset, trial_ids in trial_ids_by_dataset.items():
    print(f"  {dataset}: {len(trial_ids)}")


# ---------------------------------------------------------------------
### Test-fold partition for target micrometeorological data

test_trial_ids_by_target = {
    f"micro_met_{origin}": {} for origin in fertilizer_origins
}

for target_mm_data in test_trial_ids_by_target:
    target_trial_ids = trial_ids_by_dataset[target_mm_data].copy()
    random.shuffle(target_trial_ids)
    test_trial_ids_by_target[target_mm_data] = [
        fold.tolist() for fold in np.array_split(target_trial_ids, n_folds)
    ]


# ---------------------------------------------------------------------
### Training and validation sets for source domains

training_trial_ids_by_source = {
    f"all_but_{origin}": {} for origin in fertilizer_origins
}
validation_trial_ids_by_source = {
    f"all_but_{origin}": {} for origin in fertilizer_origins
}

validation_fraction = 0.30

print("\nSource-domain splits (training / validation):")
for source_domain in training_trial_ids_by_source:
    available_trial_ids = trial_ids_by_dataset[source_domain]
    n_validation = int(validation_fraction * len(available_trial_ids))

    validation_trial_ids = random.sample(available_trial_ids, n_validation)
    training_trial_ids = sorted(
        set(available_trial_ids) - set(validation_trial_ids)
    )

    validation_trial_ids_by_source[source_domain] = validation_trial_ids
    training_trial_ids_by_source[source_domain] = training_trial_ids
    print(
        f"  {source_domain}: "
        f"{len(training_trial_ids)} / {len(validation_trial_ids)}"
    )


# ---------------------------------------------------------------------
### Training and validation sets for target alternative-method data

alternative_data_values = [
    f"{method}_{origin}"
    for method in alternative_methods
    for origin in fertilizer_origins
]
training_trial_ids_by_alternative = {
    alternative_data: {} for alternative_data in alternative_data_values
}
validation_trial_ids_by_alternative = {
    alternative_data: {} for alternative_data in alternative_data_values
}

validation_fraction = 0.15

print("\nAlternative-method splits (training / validation):")
for alternative_data in alternative_data_values:
    available_trial_ids = trial_ids_by_dataset[alternative_data]
    n_validation = max(5, int(validation_fraction * len(available_trial_ids)))

    validation_trial_ids = random.sample(available_trial_ids, n_validation)
    training_trial_ids = sorted(
        set(available_trial_ids) - set(validation_trial_ids)
    )

    validation_trial_ids_by_alternative[alternative_data] = validation_trial_ids
    training_trial_ids_by_alternative[alternative_data] = training_trial_ids
    print(
        f"  {alternative_data}: "
        f"{len(training_trial_ids)} / {len(validation_trial_ids)}"
    )


# ---------------------------------------------------------------------
### Training and validation sets for target micrometeorological data

target_mm_data_values = [f"micro_met_{origin}" for origin in fertilizer_origins]
p_keys = [str(p) for p in p_values] + ["all"]

training_trial_ids_by_target_mm = {
    target_mm_data: {p: {} for p in p_keys}
    for target_mm_data in target_mm_data_values
}
validation_trial_ids_by_target_mm = {
    target_mm_data: {p: {} for p in p_keys}
    for target_mm_data in target_mm_data_values
}

# For each test fold, the next fold is reserved for validation.
fold_pairs = [
    [fold_index, fold_index + 1] for fold_index in range(n_folds - 1)
] + [[n_folds - 1, 0]]
validation_fraction = 0.15

print("\nTarget micrometeorological splits (training / validation / test):")
for target_mm_data in target_mm_data_values:
    for p in p_values + ["all"]:
        training_sizes = []
        validation_sizes = []
        test_sizes = []

        for fold_index, (test_fold_index, validation_fold_index) in enumerate(
            fold_pairs
        ):
            available_trial_ids = trial_ids_by_dataset[target_mm_data]
            test_trial_ids = test_trial_ids_by_target[target_mm_data][test_fold_index]
            validation_trial_ids = test_trial_ids_by_target[target_mm_data][
                validation_fold_index
            ]
            training_trial_ids = sorted(
                set(available_trial_ids)
                - set(test_trial_ids + validation_trial_ids)
            )

            if p in p_values:
                n_validation = max(5, int(validation_fraction * p))
                n_training = p - n_validation
                validation_trial_ids = random.sample(
                    validation_trial_ids, n_validation
                )
                training_trial_ids = random.sample(training_trial_ids, n_training)

            p_key = str(p)
            validation_trial_ids_by_target_mm[target_mm_data][p_key][fold_index] = (
                validation_trial_ids
            )
            training_trial_ids_by_target_mm[target_mm_data][p_key][fold_index] = (
                training_trial_ids
            )

            training_sizes.append(len(training_trial_ids))
            validation_sizes.append(len(validation_trial_ids))
            test_sizes.append(len(test_trial_ids))

        print(
            f"  {target_mm_data}, p={p}: "
            f"{format_count_range(training_sizes)} / "
            f"{format_count_range(validation_sizes)} / "
            f"{format_count_range(test_sizes)}"
        )


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
