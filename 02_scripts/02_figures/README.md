# Article figures

The scripts in this directory generate the article figures in `pdf/`. They
must be run from `02_scripts/02_figures/`.

| Script | Output |
|---|---|
| `data_description.R` | `fig_1.pdf`, `fig_S4.pdf` to `fig_S7.pdf` |
| `results_transfer_01.R` | `fig_5.pdf`, `fig_6.pdf`, `fig_7.pdf`, `fig_S1.pdf`, `fig_S8.pdf` |
| `results_transfer_02.R` | `fig_S2.pdf`, `fig_S9.pdf` |
| `results_transfer_03.R` | `fig_S3.pdf`, `fig_S10.pdf` |
| `loss_examples.py` | `loss_examples.pdf` (requires locally generated loss files) |
| `tikz_figures/` | `fig_2.pdf`, `fig_3.pdf`, `fig_4.pdf` |

Generate all figures except the TikZ figures with:

```sh
sh run_all.sh
```

Alternatively, run the R and Python figure scripts separately with:

```sh
Rscript data_description.R
Rscript results_transfer_01.R
Rscript results_transfer_02.R
Rscript results_transfer_03.R
python3 loss_examples.py
```

The transfer-result scripts read `df_res_x.csv` from
`../01_transfer_learning/results/`. Its structure is described in
[`01_transfer_learning/README.md`](../01_transfer_learning/README.md).
`loss_examples.py` additionally requires the loss files from all three
transfer experiments.

Figures 5--7 and S1--S3 use one MAE per repetition, obtained as the simple
mean of its five fold-level MAEs. Figures S9--S11 show all 50 fold-level MAEs
for the same three fine-tuning schemes.

## Plotting data

In the transfer-result scripts:

- `df1` contains strategies that use an alternative measurement method and
  derives the fertilizer origin and method used for faceting;
- `df2` contains strategies without an alternative-method stage and duplicates
  them across the relevant method facets for comparison;
- `df_plot` combines both groups and formats strategy, origin, and method
  labels for plotting.

The loss figure uses cattle, `p = 40`, repetition 1, and `k = 1` as a
representative example. It compares the initial source model with the three
fine-tuning schemes and marks the epoch with minimum validation loss.

See [`tikz_figures/README.md`](tikz_figures/README.md) for TikZ compilation.
