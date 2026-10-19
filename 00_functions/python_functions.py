import json
import pickle
import platform
import random
import time
from datetime import datetime

import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from torch.nn.utils.rnn import pack_sequence


def start_run_timer():
    """Record the start time of a complete experiment."""
    return time.perf_counter(), datetime.now().astimezone()


def write_run_report(
    report_file,
    script_name,
    start_counter,
    start_datetime,
    device,
    finetuning_scheme,
    parameters,
):
    """Write the main execution information to a JSON file."""
    end_datetime = datetime.now().astimezone()
    elapsed_seconds = time.perf_counter() - start_counter
    rounded_seconds = round(elapsed_seconds)
    hours, remainder = divmod(rounded_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)

    device_information = {"name": device}
    if str(device).startswith("cuda") and torch.cuda.is_available():
        device_information["gpu"] = torch.cuda.get_device_name(device)

    report = {
        "script": script_name,
        "status": "completed",
        "start_time": start_datetime.isoformat(timespec="seconds"),
        "end_time": end_datetime.isoformat(timespec="seconds"),
        "elapsed_seconds": round(elapsed_seconds, 2),
        "elapsed_time": f"{hours} h {minutes:02d} min {seconds:02d} s",
        "device": device_information,
        "finetuning_scheme": finetuning_scheme,
        "parameters": parameters,
        "software": {
            "python": platform.python_version(),
            "pytorch": torch.__version__,
            "cuda": torch.version.cuda,
        },
    }

    with open(report_file, "w", encoding="utf-8") as file:
        json.dump(report, file, indent=2)


def num_params(model):
    """Return the number of trainable and frozen model parameters."""
    return sum(p.numel() for p in model.parameters())


def generate_tensors_response(df, pmid, response, DEVICE):
    """Create the response tensor for one plot."""
    df_filtered = df[df["pmid"] == pmid]

    response_tensor = torch.tensor(
        df_filtered[response].values, dtype=torch.float32
    ).unsqueeze(1)

    return response_tensor.to(DEVICE)


def generate_tensors_predictors(df, pmid, cont_vars, cat_vars, DEVICE):
    """Create continuous and categorical predictor tensors for one plot."""
    df_filtered = df[df["pmid"] == pmid]

    x_cont = df_filtered[cont_vars]

    x_cont_tensor = torch.tensor(x_cont.values, dtype=torch.float32).view(
        len(x_cont), len(x_cont.columns)
    )
    x_cont_tensor = x_cont_tensor.to(DEVICE)

    x_cat = df_filtered[cat_vars]

    x_cat_tensor = torch.tensor(x_cat.values, dtype=torch.long).view(
        len(x_cat), len(x_cat.columns)
    )
    x_cat_tensor = x_cat_tensor.to(DEVICE)
    x_cat_tensor = torch.unbind(x_cat_tensor, dim=1)

    output = [x_cont_tensor, x_cat_tensor]

    return output


def make_tensors(
    training_plot_ids,
    validation_plot_ids,
    data,
    response,
    cont_vars,
    cat_vars,
    DEVICE,
):
    """Create predictor and response tensors for training and validation."""
    x_training = []
    y_training = []

    for pmid in training_plot_ids:
        x = generate_tensors_predictors(data, pmid, cont_vars, cat_vars, DEVICE)
        x_training.append(x)

        y = generate_tensors_response(data, pmid, response, DEVICE)
        y_training.append(y)

    x_validation = []
    y_validation = []

    for pmid in validation_plot_ids:
        x = generate_tensors_predictors(data, pmid, cont_vars, cat_vars, DEVICE)
        x_validation.append(x)

        y = generate_tensors_response(data, pmid, response, DEVICE)
        y_validation.append(y)

    return (x_training, y_training, x_validation, y_validation)


def make_mini_batches(x_training, y_training, batch_size):
    """Shuffle plot sequences and group them into mini-batches."""
    data_pairs = list(zip(x_training, y_training))

    random.shuffle(data_pairs)

    x_tensors_train_shuffled, y_tensors_train_shuffled = zip(*data_pairs)

    mini_batches_x = [
        x_tensors_train_shuffled[i : i + batch_size]
        for i in range(0, len(x_tensors_train_shuffled), batch_size)
    ]
    mini_batches_y = [
        y_tensors_train_shuffled[i : i + batch_size]
        for i in range(0, len(y_tensors_train_shuffled), batch_size)
    ]

    return (mini_batches_x, mini_batches_y)


def compute_validation_loss(x_validation, y_validation, model, criterion):
    """Compute the loss on the validation plot sequences."""
    model.eval()

    with torch.no_grad():
        predictions = model(x_validation)

        targets = pack_sequence(y_validation, enforce_sorted=False).data

        validation_loss = criterion(predictions, targets).item()

    model.train()

    return validation_loss


def train_model(
    model,
    num_epochs,
    learning_rate,
    x_training,
    y_training,
    x_validation,
    y_validation,
    DEVICE,
    directory,
    model_name,
    print_epoch=True,
    batch_size=32,
    patience=50,
    save=True,
):
    """Train a model with validation-based early stopping."""
    start_time = time.time()

    optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate)

    criterion = nn.MSELoss()

    model.train()

    validation_loss_best = np.inf
    validation_loss_list = []
    train_loss_list = []

    counter = 0

    for epoch in range(num_epochs):
        epoch_loss = 0
        n_obs = 0

        mini_batches_x, mini_batches_y = make_mini_batches(x_training, y_training, batch_size)

        n_mini_batches = len(mini_batches_x)

        for i in range(n_mini_batches):
            predictions = model(mini_batches_x[i])

            targets = pack_sequence(mini_batches_y[i], enforce_sorted=False).data

            batch_train_loss = criterion(predictions, targets)

            optimizer.zero_grad()
            batch_train_loss.backward()
            optimizer.step()

            batch_n = targets.shape[0]

            epoch_loss += batch_train_loss.item() * batch_n
            n_obs += batch_n

        train_loss = epoch_loss / n_obs
        train_loss_list.append(train_loss)

        validation_loss = compute_validation_loss(x_validation, y_validation, model, criterion)
        validation_loss_list.append(validation_loss)

        if validation_loss < validation_loss_best:
            validation_loss_best = validation_loss
            counter = 0

            if save:
                torch.save(
                    model.state_dict(),
                    directory + "models/model_" + model_name + ".pth",
                )
        else:
            counter += 1

        if counter >= patience:
            break

        if ((epoch + 1) % (num_epochs / 10) == 0) & print_epoch:
            print(
                f"Epoch {epoch + 1}/{num_epochs} | "
                f"train = {train_loss:.4f} | "
                f"validation = {validation_loss:.4f}"
            )

    if save:
        with open(
            directory + "losses/train_losses_model_" + model_name + ".pkl", "wb"
        ) as f:
            pickle.dump(train_loss_list, f)

        with open(
            directory + "losses/validation_losses_model_" + model_name + ".pkl", "wb"
        ) as f:
            pickle.dump(validation_loss_list, f)

    end_time = time.time()

    return (start_time, end_time)


def predict_emissions(data_origin, model, pmids, cont_vars, cat_vars, response, DEVICE):
    """Predict emission dynamics and restore the original response scale."""
    data_predictions = data_origin.copy()

    data_predictions = data_predictions[data_predictions["pmid"].isin(pmids)]
    pmids = (
        data_predictions["pmid"].unique().tolist()
    )  # reordering the pmids to match the order in data_predictions

    model.eval()

    with torch.no_grad():
        preds = []

        for i in pmids:
            x = generate_tensors_predictors(
                data_predictions, i, cont_vars, cat_vars, DEVICE
            )
            y = model([x])
            preds.append(y.squeeze(-1))

        all_predictions = torch.cat(preds, dim=0)

        if response == "e_cum":
            data_predictions["prediction_ecum"] = (
                all_predictions.detach().cpu().numpy()
                * data_origin["e_cum_origin"].abs().max()
            )

        elif response == "delta_e_cum":
            data_predictions["prediction_delta_ecum"] = (
                all_predictions.detach().cpu().numpy()
                * data_origin["delta_e_cum_origin"].abs().max()
            )
            data_predictions["prediction_ecum"] = data_predictions.groupby("pmid")[
                "prediction_delta_ecum"
            ].cumsum()

        elif response == "j_nh3":
            data_predictions["prediction_j_nh3"] = (
                all_predictions.detach().cpu().numpy()
                * data_origin["j_nh3_origin"].abs().max()
            )
            data_predictions["prediction_delta_ecum"] = (
                data_predictions["prediction_j_nh3"] * data_predictions["dt_origin"]
            )
            data_predictions["prediction_ecum"] = data_predictions.groupby("pmid")[
                "prediction_delta_ecum"
            ].cumsum()

    return data_predictions


def compute_metrics(df, groups=None):
    """Compute prediction metrics, optionally within groups."""
    if groups is None:
        res = pd.DataFrame(
            {
                "MAE": [np.mean(np.abs(df["e_cum_origin"] - df["prediction_ecum"]))],
                "MAPE": [
                    np.mean(
                        np.abs(
                            (df["e_cum_origin"] - df["prediction_ecum"])
                            / df["e_cum_origin"]
                        )
                    )
                ],
                "MSE": [np.mean((df["e_cum_origin"] - df["prediction_ecum"]) ** 2)],
                "RMSE": [
                    np.sqrt(((df["e_cum_origin"] - df["prediction_ecum"]) ** 2).mean())
                ],
                "ME": [
                    1
                    - (
                        ((df["e_cum_origin"] - df["prediction_ecum"]) ** 2).sum()
                        / ((df["e_cum_origin"] - df["e_cum_origin"].mean()) ** 2).sum()
                    )
                ],
                "MBE": [(df["e_cum_origin"] - df["prediction_ecum"]).mean()],
            }
        ).round(2)

    else:
        df = df.groupby(groups)[["e_cum_origin", "prediction_ecum"]]

        res = df.apply(
            lambda g: pd.Series(
                {
                    "MAE": np.mean(np.abs(g["e_cum_origin"] - g["prediction_ecum"])),
                    "MAPE": np.mean(
                        np.abs(
                            (g["e_cum_origin"] - g["prediction_ecum"])
                            / g["e_cum_origin"]
                        )
                    ),
                    "MSE": np.mean((g["e_cum_origin"] - g["prediction_ecum"]) ** 2),
                    "RMSE": np.sqrt(
                        ((g["e_cum_origin"] - g["prediction_ecum"]) ** 2).mean()
                    ),
                    "ME": 1
                    - (
                        ((g["e_cum_origin"] - g["prediction_ecum"]) ** 2).sum()
                        / ((g["e_cum_origin"] - g["e_cum_origin"].mean()) ** 2).sum()
                    ),
                    "MBE": (g["e_cum_origin"] - g["prediction_ecum"]).mean(),
                }
            )
        ).round(2)

    return res
