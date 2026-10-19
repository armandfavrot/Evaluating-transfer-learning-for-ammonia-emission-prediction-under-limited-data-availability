# Evaluating transfer learning for ammonia emission prediction

This repository contains the data-processing, modelling, table, and figure
scripts associated with the article *Evaluating transfer learning for ammonia
emission prediction under limited data availability*.

The analysis combines R and Python. R is used for data preparation, tables, and
most figures. Python and PyTorch are used for the recurrent neural networks and
transfer-learning experiments.

## Repository structure

```text
00_functions/
    Shared R and Python functions
01_data/
    Input datasets
02_scripts/
    00_data_preparation/       Data preparation
    01_transfer_learning/      Complete transfer-learning experiments
    02_figures/                Article figures
    03_tables/                 Article tables
    04_reproducibility_example/  Lightweight reproducibility example
```

Each main directory contains a short README with the information needed to run
its scripts.

## Data availability

The complete analysis uses restricted CaractAir data that are not distributed
publicly. The lightweight reproducibility example uses only the distributable
ALFAM2 data and can be run without CaractAir. See [`01_data/README.md`](01_data/README.md)
for details.

## Environments

The R environment is described by `renv.lock` (R 4.4.1) and can be restored
from the repository root with:

```sh
Rscript -e 'renv::restore(prompt = FALSE)'
```

The Python environment is described by `environment.yml` (Python 3.12.3).
It uses pip to install the package versions listed in `requirements.txt`.
Computo can use this file to create the environment with micromamba.
To create and activate it locally, run from the repository root:

```sh
micromamba create -f environment.yml
micromamba activate ammonia-transfer-learning
```

Alternatively, keep using pyenv or an existing virtual environment with Python
3.12.3 and install the same dependencies with:

```sh
python3 -m pip install -r requirements.txt
```

## Computo manuscript

The complete article is in `main.qmd`, with metadata and the abstract in
`_quarto.yml` and references in `references.bib`.

From the repository root, render the HTML and PDF versions with:

```sh
quarto render
```

The R chunks regenerate the result figures from the existing `df_res_x.csv`
files and Figure A4 from `data_without_caractair.csv`. Figure 1 and Figures
A5--A7 are included from the precomputed `fig_1.pdf`, `fig_S5.pdf`, `fig_S6.pdf`
and `fig_S7.pdf` in `02_scripts/02_figures/pdf/`, because they include restricted
CaractAir data. Their SVG versions are generated automatically for HTML.
The three diagrams use the existing `fig_2.pdf`, `fig_3.pdf` and `fig_4.pdf`
from the same directory, without recompiling TikZ. `pdftocairo` converts the
precomputed PDFs to SVG for HTML. No model training is launched, and neither
`data.csv` nor the restricted input file `data_caractair.csv` is needed to
render the manuscript.

Restore the R environment before rendering; no environment-variable override
is needed. `_dependencies.R` declares packages loaded indirectly by the scripts
or the Computo template so that `renv::snapshot()` includes them. Personal and
generated files are excluded from dependency discovery through `.renvignore`.

## Quick reproducibility example

The lightweight example uses cattle slurry, wind-tunnel data, three test folds,
and reduced training. It is designed to run on CPU in a reasonable time.

```sh
cd 02_scripts/00_data_preparation
Rscript data_preparation_without_caractair.R

cd ../04_reproducibility_example
sh run_all.sh
```

The script writes its results and execution report to `results/` and three PDF
figures to `images/`. See
[`04_reproducibility_example/README.md`](02_scripts/04_reproducibility_example/README.md)
for details.

## Complete analysis

The complete workflow is:

```text
Input data
    ↓
Data preparation
    ↓
Data splits
    ↓
Transfer-learning experiments
    ↓
Tables and figures
```

Run each command from the indicated directory:

```sh
cd 02_scripts/00_data_preparation
Rscript data_preparation.R

cd ../01_transfer_learning
bash run_all.sh

cd ../03_tables
Rscript data_description.R

cd ../02_figures
Rscript data_description.R
Rscript results_transfer_01.R
Rscript results_transfer_02.R
Rscript results_transfer_03.R
python3 loss_examples.py
```

The loss files are not distributed in this repository. Running `loss_examples.py`
requires the training and validation losses saved by the transfer-learning
scripts in their `results/transfer_x/losses/` directories. Without these files,
skip this command; it is not needed to render the manuscript.

The complete transfer-learning experiments are computationally intensive. A
CUDA-capable GPU is used automatically when available. Each transfer script
records its device, duration, software versions, and main parameters in
`results/transfer_x/run_report.json`.
