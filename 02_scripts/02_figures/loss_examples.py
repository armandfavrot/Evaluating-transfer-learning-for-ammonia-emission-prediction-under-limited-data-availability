"""Plot representative training and validation loss curves."""

import pickle
from pathlib import Path

import matplotlib.pyplot as plt


SCRIPT_DIR = Path(__file__).resolve().parent
RESULTS_DIRECTORY = SCRIPT_DIR.parent / "01_transfer_learning/results"
FIGURES_DIRECTORY = SCRIPT_DIR / "pdf"
FIGURES_DIRECTORY.mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------------
### Example configuration

origin = "cat"
p = 40
repetition = 1
k = 1

source_domain = f"all_but_{origin}"
target_mm_data = f"micro_met_{origin}"

initial_model_name = (
    f"source_{source_domain}_alternative_none_"
    f"target_mm_none_p_none_r_{repetition}_k_none"
)
finetuned_model_name = (
    f"source_{source_domain}_alternative_none_"
    f"target_mm_{target_mm_data}_p_{p}_r_{repetition}_k_{k}"
)

panels = [
    (
        "Initial source-model training",
        RESULTS_DIRECTORY / "transfer_01/losses",
        initial_model_name,
    ),
    (
        "Full fine-tuning",
        RESULTS_DIRECTORY / "transfer_01/losses",
        finetuned_model_name,
    ),
    (
        "Partial fine-tuning",
        RESULTS_DIRECTORY / "transfer_02/losses",
        finetuned_model_name,
    ),
    (
        "Fertilizer-origin embedding fine-tuning",
        RESULTS_DIRECTORY / "transfer_03/losses",
        finetuned_model_name,
    ),
]


# ---------------------------------------------------------------------
### Functions


def load_losses(losses_directory, model_name):
    training_file = losses_directory / f"train_losses_model_{model_name}.pkl"
    validation_file = losses_directory / f"validation_losses_model_{model_name}.pkl"

    with open(training_file, "rb") as file:
        training_losses = pickle.load(file)

    with open(validation_file, "rb") as file:
        validation_losses = pickle.load(file)

    return training_losses, validation_losses


# ---------------------------------------------------------------------
### Loss examples

figure, axes = plt.subplots(2, 2, figsize=(10, 7))

for axis, (title, losses_directory, model_name) in zip(axes.flat, panels):
    training_losses, validation_losses = load_losses(
        losses_directory,
        model_name,
    )
    training_epochs = range(1, len(training_losses) + 1)
    validation_epochs = range(1, len(validation_losses) + 1)
    best_validation_epoch = (
        min(
            range(len(validation_losses)),
            key=validation_losses.__getitem__,
        )
        + 1
    )

    axis.plot(
        training_epochs,
        training_losses,
        color="#56B4E9",
        linewidth=1.2,
        label="Training",
    )
    axis.plot(
        validation_epochs,
        validation_losses,
        color="#D95F02",
        linewidth=1.2,
        label="Validation",
    )
    axis.axvline(
        best_validation_epoch,
        color="#666666",
        linestyle="--",
        linewidth=1,
        label="Best validation epoch",
    )

    axis.set_title(title)
    axis.set_xlabel("Epoch")
    axis.set_ylabel("Mean squared error")
    axis.spines["top"].set_visible(False)
    axis.spines["right"].set_visible(False)

handles, labels = axes.flat[0].get_legend_handles_labels()
figure.legend(
    handles,
    labels,
    loc="lower center",
    ncol=3,
    frameon=False,
)
figure.suptitle(
    f"Illustrative loss curves for cattle, p = {p}, repetition = {repetition}, and k = {k}",
    fontsize=13,
)
figure.tight_layout(rect=(0, 0.08, 1, 0.95))
figure.savefig(
    FIGURES_DIRECTORY / "loss_examples.pdf",
    bbox_inches="tight",
)
plt.close(figure)
