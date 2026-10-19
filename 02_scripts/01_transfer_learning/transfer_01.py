"""Run all transfer-learning strategies using full fine-tuning."""

import pickle
import random
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import torch


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = next(
    path
    for path in (SCRIPT_DIR, *SCRIPT_DIR.parents)
    if (path / "00_functions" / "rnn_module.py").is_file()
)
sys.path.insert(0, str(PROJECT_ROOT / "00_functions"))

import python_functions as mf
from rnn_module import AmmoniaRNN


DEVICE = "cuda:0" if torch.cuda.is_available() else "cpu"
print(f"Device: {DEVICE}")

training_seed = 1
random.seed(training_seed)
np.random.seed(training_seed)
torch.manual_seed(training_seed)
if torch.cuda.is_available():
    torch.cuda.manual_seed_all(training_seed)
torch.backends.cudnn.benchmark = False
torch.backends.cudnn.deterministic = True

output_directory = SCRIPT_DIR / "results/transfer_01"
results_file = SCRIPT_DIR / "results/df_res_1.csv"
(output_directory / "models").mkdir(parents=True, exist_ok=True)
(output_directory / "losses").mkdir(parents=True, exist_ok=True)
run_start_counter, run_start_datetime = mf.start_run_timer()


# ---------------------------------------------------------------------
### Data

data = pd.read_csv(PROJECT_ROOT / "02_scripts/00_data_preparation/data.csv")
data = data.rename(columns={"id": "pmid"})

# Used for back-transformation in mf.predict_emissions.
data_origin = data.copy()


# ---------------------------------------------------------------------
### Training, validation and test splits

splits_directory = SCRIPT_DIR / "data_splits"

with open(splits_directory / "test_trial_ids_by_target.pkl", "rb") as file:
    test_trial_ids_by_target = pickle.load(file)

with open(splits_directory / "training_trial_ids_by_source.pkl", "rb") as file:
    training_trial_ids_by_source = pickle.load(file)

with open(splits_directory / "validation_trial_ids_by_source.pkl", "rb") as file:
    validation_trial_ids_by_source = pickle.load(file)

with open(splits_directory / "training_trial_ids_by_alternative.pkl", "rb") as file:
    training_trial_ids_by_alternative = pickle.load(file)

with open(splits_directory / "validation_trial_ids_by_alternative.pkl", "rb") as file:
    validation_trial_ids_by_alternative = pickle.load(file)

with open(splits_directory / "training_trial_ids_by_target_mm.pkl", "rb") as file:
    training_trial_ids_by_target_mm = pickle.load(file)

with open(splits_directory / "validation_trial_ids_by_target_mm.pkl", "rb") as file:
    validation_trial_ids_by_target_mm = pickle.load(file)


# ---------------------------------------------------------------------
### Parameters

# These lists can be reduced for a lighter run, for example to ["cat"] and
# ["wt"] for the reproducibility example.
fertilizer_origins = ["cat", "pig"]
alternative_methods = ["CaractAir", "wt", "chamber", "cps"]

n_repetitions = 10
n_folds = 5
p_values = [10, 20, 40, 80]

categorical_variables = [
    "app_method",
    "incorp",
    "till",
    "meas_tech",
    "fer_origin",
    "fer_forme",
    "fer_trt1",
    "fer_trt2",
    "fer_trt3",
    "crop",
    "soil_type",
]

continuous_variables = [
    "ct",
    "dt",
    "air_temp",
    "wind_2m",
    "rain_rate",
    "rain_cum",
    "tan_app",
    "app_rate",
    "fer_dm",
    "fer_ph",
    "time_incorp",
    "furrow_z",
    "soil_water",
    "soil_ph",
    "soil_dens",
    "soil_oc",
    "crop_z",
    "air_temp_ind",
    "wind_2m_ind",
    "fer_dm_ind",
    "fer_ph_ind",
    "soil_water_ind",
    "soil_ph_ind",
    "soil_dens_ind",
    "soil_oc_ind",
    "crop_z_ind",
    "time_incorp_ind",
]

num_epochs = 1500
patience = 100
batch_size = 32
num_layers = 1
response = "e_cum"
initial_learning_rate = 1e-4
finetuning_learning_rate = 1e-4
nonlinearity = "relu"
bidirectional = True
hidden_size = 512

categorical_dimensions = [max(data[x]) + 1 for x in categorical_variables]
embedding_dimensions = [8] * len(categorical_variables)
input_size = len(continuous_variables) + len(categorical_variables)
output_size = 1

alternative_data_values = [
    f"{method}_{origin}"
    for method in alternative_methods
    for origin in fertilizer_origins
]
target_mm_data_values = [f"micro_met_{origin}" for origin in fertilizer_origins]
source_domain_values = [f"all_but_{origin}" for origin in fertilizer_origins]


# ---------------------------------------------------------------------
### Helper functions


def make_model_name(
    source_domain="none",
    alternative_data="none",
    target_mm_data="none",
    p="none",
    repetition="none",
    k="none",
):
    return (
        f"source_{source_domain}_alternative_{alternative_data}_"
        f"target_mm_{target_mm_data}_p_{p}_r_{repetition}_k_{k}"
    )


def build_model():
    torch.manual_seed(training_seed)
    return AmmoniaRNN(
        input_size=input_size,
        output_size=output_size,
        hidden_size=hidden_size,
        nonlinearity=nonlinearity,
        num_layers=num_layers,
        bidirectional=bidirectional,
        cat_dims=categorical_dimensions,
        embedding_dims=embedding_dimensions,
    ).to(DEVICE)


def load_model(model, model_name):
    model_file = output_directory / "models" / f"model_{model_name}.pth"
    model.load_state_dict(
        torch.load(model_file, map_location=DEVICE, weights_only=True)
    )


def prepare_model_for_finetuning(model):
    for parameter in model.parameters():
        parameter.requires_grad = True


def get_plot_ids(trial_ids):
    return data[data["eid_tr"].isin(trial_ids)]["pmid"].unique().tolist()


def fit_model(
    model,
    training_plot_ids,
    validation_plot_ids,
    model_name,
    learning_rate,
):
    x_training, y_training, x_validation, y_validation = mf.make_tensors(
        training_plot_ids,
        validation_plot_ids,
        data,
        response,
        continuous_variables,
        categorical_variables,
        DEVICE,
    )
    random.seed(training_seed)
    mf.train_model(
        model,
        num_epochs,
        learning_rate,
        x_training,
        y_training,
        x_validation,
        y_validation,
        DEVICE,
        str(output_directory) + "/",
        model_name,
        print_epoch=False,
        batch_size=batch_size,
        patience=patience,
    )


def train_initial_model(training_trial_ids, validation_trial_ids, model_name):
    model = build_model()
    fit_model(
        model,
        get_plot_ids(training_trial_ids),
        get_plot_ids(validation_trial_ids),
        model_name,
        initial_learning_rate,
    )


def fine_tune_model(
    model_to_load,
    training_trial_ids,
    validation_trial_ids,
    model_name,
):
    model = build_model()
    load_model(model, model_to_load)
    prepare_model_for_finetuning(model)
    fit_model(
        model,
        get_plot_ids(training_trial_ids),
        get_plot_ids(validation_trial_ids),
        model_name,
        finetuning_learning_rate,
    )


def compute_mae(predictions):
    return np.mean(np.abs(predictions["e_cum_origin"] - predictions["prediction_ecum"]))


# ---------------------------------------------------------------------
### Shared initial models: source domains

print("Preparing initial source-domain models...")
for repetition in range(1, n_repetitions + 1):
    for source_domain in source_domain_values:
        train_initial_model(
            training_trial_ids_by_source[repetition][source_domain],
            validation_trial_ids_by_source[repetition][source_domain],
            make_model_name(
                source_domain=source_domain,
                repetition=repetition,
            ),
        )


# ---------------------------------------------------------------------
### Shared initial models: target alternative-method data

print("Preparing initial alternative-method models...")
for repetition in range(1, n_repetitions + 1):
    for alternative_data in alternative_data_values:
        train_initial_model(
            training_trial_ids_by_alternative[repetition][alternative_data],
            validation_trial_ids_by_alternative[repetition][alternative_data],
            make_model_name(
                alternative_data=alternative_data,
                repetition=repetition,
            ),
        )


# ---------------------------------------------------------------------
### Strategy 1: source to target micrometeorological data

print("Strategy 1/3: source to target micrometeorological data")
for repetition in range(1, n_repetitions + 1):
    for origin in fertilizer_origins:
        source_domain = f"all_but_{origin}"
        target_mm_data = f"micro_met_{origin}"
        source_model_name = make_model_name(
            source_domain=source_domain,
            repetition=repetition,
        )

        for p in p_values:
            for fold_index in range(n_folds):
                # Python indices start at 0; article fold indices start at 1.
                k = fold_index + 1
                fine_tune_model(
                    source_model_name,
                    training_trial_ids_by_target_mm[repetition][target_mm_data][str(p)][
                        fold_index
                    ],
                    validation_trial_ids_by_target_mm[repetition][target_mm_data][
                        str(p)
                    ][fold_index],
                    make_model_name(
                        source_domain=source_domain,
                        target_mm_data=target_mm_data,
                        p=p,
                        repetition=repetition,
                        k=k,
                    ),
                )


# ---------------------------------------------------------------------
### Strategy 2: source to alternative method to target micrometeorological data

print("Strategy 2/3: source to alternative method to target micrometeorological data")
for repetition in range(1, n_repetitions + 1):
    for origin in fertilizer_origins:
        source_domain = f"all_but_{origin}"
        source_model_name = make_model_name(
            source_domain=source_domain,
            repetition=repetition,
        )

        for method in alternative_methods:
            alternative_data = f"{method}_{origin}"
            fine_tune_model(
                source_model_name,
                training_trial_ids_by_alternative[repetition][alternative_data],
                validation_trial_ids_by_alternative[repetition][alternative_data],
                make_model_name(
                    source_domain=source_domain,
                    alternative_data=alternative_data,
                    repetition=repetition,
                ),
            )


## Final fine-tuning on target micrometeorological data


for repetition in range(1, n_repetitions + 1):
    for origin in fertilizer_origins:
        source_domain = f"all_but_{origin}"
        target_mm_data = f"micro_met_{origin}"

        for method in alternative_methods:
            alternative_data = f"{method}_{origin}"
            intermediate_model_name = make_model_name(
                source_domain=source_domain,
                alternative_data=alternative_data,
                repetition=repetition,
            )

            for p in p_values:
                for fold_index in range(n_folds):
                    k = fold_index + 1
                    fine_tune_model(
                        intermediate_model_name,
                        training_trial_ids_by_target_mm[repetition][target_mm_data][
                            str(p)
                        ][fold_index],
                        validation_trial_ids_by_target_mm[repetition][target_mm_data][
                            str(p)
                        ][fold_index],
                        make_model_name(
                            source_domain=source_domain,
                            alternative_data=alternative_data,
                            target_mm_data=target_mm_data,
                            p=p,
                            repetition=repetition,
                            k=k,
                        ),
                    )


# ---------------------------------------------------------------------
### Strategy 3: alternative method to target micrometeorological data

print("Strategy 3/3: alternative method to target micrometeorological data")
for repetition in range(1, n_repetitions + 1):
    for origin in fertilizer_origins:
        target_mm_data = f"micro_met_{origin}"

        for method in alternative_methods:
            alternative_data = f"{method}_{origin}"
            alternative_model_name = make_model_name(
                alternative_data=alternative_data,
                repetition=repetition,
            )

            for p in p_values:
                for fold_index in range(n_folds):
                    k = fold_index + 1
                    fine_tune_model(
                        alternative_model_name,
                        training_trial_ids_by_target_mm[repetition][target_mm_data][
                            str(p)
                        ][fold_index],
                        validation_trial_ids_by_target_mm[repetition][target_mm_data][
                            str(p)
                        ][fold_index],
                        make_model_name(
                            alternative_data=alternative_data,
                            target_mm_data=target_mm_data,
                            p=p,
                            repetition=repetition,
                            k=k,
                        ),
                    )


# ---------------------------------------------------------------------
### Target-only benchmark

print("Training target-only benchmark models...")
for repetition in range(1, n_repetitions + 1):
    for target_mm_data in target_mm_data_values:
        for p in p_values + ["all"]:
            for fold_index in range(n_folds):
                k = fold_index + 1
                train_initial_model(
                    training_trial_ids_by_target_mm[repetition][target_mm_data][str(p)][
                        fold_index
                    ],
                    validation_trial_ids_by_target_mm[repetition][target_mm_data][
                        str(p)
                    ][fold_index],
                    make_model_name(
                        target_mm_data=target_mm_data,
                        p=p,
                        repetition=repetition,
                        k=k,
                    ),
                )


# ---------------------------------------------------------------------
### Target-mean benchmark

print("Computing mean-model benchmarks...")
target_mean_results = []

for repetition in range(1, n_repetitions + 1):
    for target_mm_data in target_mm_data_values:
        for p in p_values:
            for fold_index in range(n_folds):
                k = fold_index + 1
                training_trial_ids = (
                    training_trial_ids_by_target_mm[repetition][target_mm_data][str(p)][
                        fold_index
                    ]
                    + validation_trial_ids_by_target_mm[repetition][target_mm_data][
                        str(p)
                    ][fold_index]
                )
                training_data = data[
                    data["pmid"].isin(get_plot_ids(training_trial_ids))
                ]
                final_training_emissions = training_data.loc[
                    training_data.groupby("pmid")["ct"].idxmax(), "e_cum_origin"
                ]
                mean_prediction = np.mean(final_training_emissions)

                test_trial_ids = test_trial_ids_by_target[repetition][target_mm_data][
                    fold_index
                ]
                test_data = data[data["pmid"].isin(get_plot_ids(test_trial_ids))]
                final_test_emissions = test_data.loc[
                    test_data.groupby("pmid")["ct"].idxmax(), "e_cum_origin"
                ]

                target_mean_results.append(
                    pd.DataFrame(
                        {
                            "strategy": ["target_mean"],
                            "source_domain": ["none"],
                            "alternative_data": ["none"],
                            "target_mm_data": [target_mm_data],
                            "p": [p],
                            "repetition": [repetition],
                            "k": [k],
                            "mae": [
                                np.mean(np.abs(final_test_emissions - mean_prediction))
                            ],
                        }
                    )
                )

with open(output_directory / "target_mean_results.pkl", "wb") as file:
    pickle.dump(target_mean_results, file)


# ---------------------------------------------------------------------
### Source-mean benchmark

source_mean_results = []

for repetition in range(1, n_repetitions + 1):
    for source_domain in source_domain_values:
        training_trial_ids = (
            training_trial_ids_by_source[repetition][source_domain]
            + validation_trial_ids_by_source[repetition][source_domain]
        )
        training_data = data[data["pmid"].isin(get_plot_ids(training_trial_ids))]
        final_training_emissions = training_data.loc[
            training_data.groupby("pmid")["ct"].idxmax(), "e_cum_origin"
        ]
        mean_prediction = np.mean(final_training_emissions)

        origin = source_domain.removeprefix("all_but_")
        target_mm_data = f"micro_met_{origin}"

        for fold_index in range(n_folds):
            k = fold_index + 1
            test_trial_ids = test_trial_ids_by_target[repetition][target_mm_data][
                fold_index
            ]
            test_data = data[data["pmid"].isin(get_plot_ids(test_trial_ids))]
            final_test_emissions = test_data.loc[
                test_data.groupby("pmid")["ct"].idxmax(), "e_cum_origin"
            ]
            source_mean_results.append(
                pd.DataFrame(
                    {
                        "strategy": ["source_mean"],
                        "source_domain": [source_domain],
                        "alternative_data": ["none"],
                        "target_mm_data": [target_mm_data],
                        "p": [0],
                        "repetition": [repetition],
                        "k": [k],
                        "mae": [
                            np.mean(np.abs(final_test_emissions - mean_prediction))
                        ],
                    }
                )
            )

with open(output_directory / "source_mean_results.pkl", "wb") as file:
    pickle.dump(source_mean_results, file)


# ---------------------------------------------------------------------
### Independent test-set evaluation

print("Evaluating models on the test folds...")
model_configurations = []

for origin in fertilizer_origins:
    source_domain = f"all_but_{origin}"
    target_mm_data = f"micro_met_{origin}"
    model_configurations.append(
        {
            "strategy": "source_to_target_mm",
            "source_domain": source_domain,
            "alternative_data": "none",
            "target_mm_data": target_mm_data,
            "p_values": [0] + p_values,
        }
    )

    for method in alternative_methods:
        alternative_data = f"{method}_{origin}"
        model_configurations.extend(
            [
                {
                    "strategy": "source_to_alternative_to_target_mm",
                    "source_domain": source_domain,
                    "alternative_data": alternative_data,
                    "target_mm_data": target_mm_data,
                    "p_values": [0] + p_values,
                },
                {
                    "strategy": "alternative_to_target_mm",
                    "source_domain": "none",
                    "alternative_data": alternative_data,
                    "target_mm_data": target_mm_data,
                    "p_values": [0] + p_values,
                },
            ]
        )

    model_configurations.append(
        {
            "strategy": "target_mm_only",
            "source_domain": "none",
            "alternative_data": "none",
            "target_mm_data": target_mm_data,
            "p_values": p_values + ["all"],
        }
    )


def final_model_name(configuration, p, repetition, k):
    if p != 0:
        return make_model_name(
            source_domain=configuration["source_domain"],
            alternative_data=configuration["alternative_data"],
            target_mm_data=configuration["target_mm_data"],
            p=p,
            repetition=repetition,
            k=k,
        )
    if configuration["strategy"] == "source_to_target_mm":
        return make_model_name(
            source_domain=configuration["source_domain"],
            repetition=repetition,
        )
    if configuration["strategy"] == "source_to_alternative_to_target_mm":
        return make_model_name(
            source_domain=configuration["source_domain"],
            alternative_data=configuration["alternative_data"],
            repetition=repetition,
        )
    return make_model_name(
        alternative_data=configuration["alternative_data"],
        repetition=repetition,
    )


prediction_results = []
mae_results = []

for configuration in model_configurations:
    for repetition in range(1, n_repetitions + 1):
        for p in configuration["p_values"]:
            for fold_index in range(n_folds):
                k = fold_index + 1
                model = build_model()
                load_model(
                    model,
                    final_model_name(configuration, p, repetition, k),
                )

                test_trial_ids = test_trial_ids_by_target[repetition][
                    configuration["target_mm_data"]
                ][fold_index]
                test_plot_ids = get_plot_ids(test_trial_ids)
                predictions = mf.predict_emissions(
                    data_origin,
                    model,
                    test_plot_ids,
                    continuous_variables,
                    categorical_variables,
                    response,
                    DEVICE,
                )
                predictions = predictions.loc[
                    predictions.groupby("pmid")["ct"].idxmax()
                ]

                result_fields = {
                    "strategy": configuration["strategy"],
                    "source_domain": configuration["source_domain"],
                    "alternative_data": configuration["alternative_data"],
                    "target_mm_data": configuration["target_mm_data"],
                    "p": p,
                    "repetition": repetition,
                    "k": k,
                }
                mae_results.append(
                    pd.DataFrame([result_fields | {"mae": compute_mae(predictions)}])
                )
                prediction_results.append(predictions.assign(**result_fields))

with open(output_directory / "prediction_results.pkl", "wb") as file:
    pickle.dump(prediction_results, file)

with open(output_directory / "mae_results.pkl", "wb") as file:
    pickle.dump(mae_results, file)


# ---------------------------------------------------------------------
### Results export

results = pd.concat(
    [
        pd.concat(mae_results),
        pd.concat(target_mean_results),
        pd.concat(source_mean_results),
    ]
)
results.to_csv(results_file, index=False)


mf.write_run_report(
    output_directory / "run_report.json",
    script_name=Path(__file__).name,
    start_counter=run_start_counter,
    start_datetime=run_start_datetime,
    device=DEVICE,
    finetuning_scheme="full",
    parameters={
        "fertilizer_origins": fertilizer_origins,
        "alternative_methods": alternative_methods,
        "n_repetitions": n_repetitions,
        "n_folds": n_folds,
        "p_values": p_values,
        "num_epochs": num_epochs,
        "patience": patience,
        "batch_size": batch_size,
        "initial_learning_rate": initial_learning_rate,
        "finetuning_learning_rate": finetuning_learning_rate,
        "hidden_size": hidden_size,
        "num_layers": num_layers,
        "bidirectional": bidirectional,
        "partition_seeds": list(range(1, n_repetitions + 1)),
        "training_seed": training_seed,
        "cudnn_deterministic": True,
    },
)

print(f"Results saved to: {results_file}")
