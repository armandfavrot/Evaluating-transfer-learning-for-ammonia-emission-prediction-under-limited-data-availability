# Transfer-learning experiments

This directory contains the complete transfer-learning analysis. The three
scripts share the same datasets, partitions, architecture, and evaluation procedure,
but differ in the parameters updated during fine-tuning.

| Script | Fine-tuning scheme |
|---|---|
| `transfer_01.py` | All model parameters |
| `transfer_02.py` | Embeddings and post-RNN MLP |
| `transfer_03.py` | Fertilizer-origin embedding only |

Initial training uses a learning rate of `1e-4`. Fine-tuning also uses
`1e-4` in `transfer_01.py` and `transfer_02.py`, and `2e-3` in
`transfer_03.py`. Training uses at most 1,500 epochs, with early stopping
after 100 epochs without improvement in validation loss.

## Running the complete analysis

Run the complete workflow from this directory:

```sh
bash run_all.sh
```

The command first recreates the data splits, then runs the three transfer
scripts sequentially. The complete calculation is long and a CUDA-capable GPU
is recommended. Python automatically falls back to CPU when CUDA is not
available.

## Transfer-learning strategies

| `strategy` | Training sequence |
|---|---|
| `source_to_target_mm` | Source domain, then target micrometeorological data |
| `source_to_alternative_to_target_mm` | Source domain, alternative-method data, then target micrometeorological data |
| `alternative_to_target_mm` | Alternative-method data, then target micrometeorological data |
| `target_mm_only` | Target micrometeorological data only |
| `target_mean` | Mean final emission in the target training data |
| `source_mean` | Mean final emission in the source-domain data |

The evaluation uses ten repetitions of five-fold cross-validation. For
transfer strategies, `p = 0` means that the final target
micrometeorological fine-tuning stage is skipped. For `target_mm_only`,
`p = all` uses all available non-test target trials.

Partition seeds are the repetition numbers 1 to 10. Model initialization and
mini-batch shuffling use the fixed seed 1 in every repetition, and cuDNN is
configured in deterministic mode when CUDA is used.

## Result files

Each script writes a summary CSV to `results/df_res_x.csv`. Each row contains
the result for one strategy, repetition, and test fold:

| Column | Meaning |
|---|---|
| `strategy` | Training and fine-tuning sequence |
| `source_domain` | Source dataset, or `none` |
| `alternative_data` | Alternative-method target dataset, or `none` |
| `target_mm_data` | Target micrometeorological dataset |
| `p` | Number of available target trials, or `all` |
| `repetition` | Cross-validation repetition, numbered from 1 to 10 |
| `k` | Test-fold index, numbered from 1 to 5 |
| `mae` | Mean absolute error on the independent test fold |

Detailed outputs are stored in `results/transfer_x/`:

- `models/`: saved model checkpoints;
- `losses/`: training and validation losses;
- `prediction_results.pkl` and `mae_results.pkl`: detailed results;
- `source_mean_results.pkl` and `target_mean_results.pkl`: mean-model
  benchmarks;
- `run_report.json`: execution date, duration, device, software versions, and
  main parameters.

See [`data_splits/README.md`](data_splits/README.md) for the fold definitions.
