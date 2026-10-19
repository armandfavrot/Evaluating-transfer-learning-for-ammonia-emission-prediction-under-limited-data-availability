# Lightweight reproducibility example

This directory provides a reduced version of the full `transfer_01.py`
experiment using only distributable ALFAM2 data. It demonstrates the complete
modelling workflow without using the restricted CaractAir dataset.

Compared with the complete analysis, the example uses:

- cattle slurry as the only target fertilizer origin;
- wind tunnel as the only alternative measurement method;
- the first three test folds from a locally generated ten-fold partition;
- `p = 10` and `p = 20`;
- 10 training epochs;
- full fine-tuning on CPU.

## Prepare the data

First, run the public data preparation from its own directory:

```sh
cd 02_scripts/00_data_preparation
Rscript data_preparation_without_caractair.R
```

This creates `data_without_caractair.csv`. Data preparation is intentionally
kept separate from the example launcher.

## Run the example

Then run from this directory:

```sh
cd ../04_reproducibility_example
sh run_all.sh
```

The launcher checks that the prepared dataset exists, creates local data
splits, executes the Python experiment, and generates the three result figures.
The calculation normally takes several minutes, depending on the machine.

## Outputs

- `data_splits/*.pkl`: local training, validation, and test partitions;
- `results/df_res_1.csv`: summary MAE results;
- `results/models/`: model checkpoints;
- `results/losses/`: training and validation losses;
- `results/run_report.json`: execution date, duration, device, software
  versions, and main parameters;
- `images/fig_1.pdf`, `fig_2.pdf`, and `fig_3.pdf`: example result figures.

The numerical results differ from the complete analysis because the restricted
CaractAir observations are not included.
