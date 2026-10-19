# Input data

This directory is designed for two prepared input datasets:

- `data_alfam2.csv`: field measurements from the ALFAM2 database, used by the
  public reproducibility example;
- `data_caractair.csv`: restricted laboratory measurements from the DetAir
  database, collected with the CaractAir system and required only for the
  complete analysis.

The CaractAir dataset is not distributed in the public version of this
repository. Authorized users can place it in this directory before running the
complete data preparation.

Both files use the same tabular structure. Each row represents one measurement
interval for one plot.

## Main identifiers and variables

| Variable | Meaning |
|---|---|
| `eid` | Experiment identifier |
| `tr` | Treatment identifier within an experiment |
| `id` | Plot identifier; each plot corresponds to one emission time series |
| `rep` | Replicate identifier |
| `interval` | Measurement-interval index |
| `ct` | Cumulative time since fertilizer application |
| `e_cum` | Cumulative ammonia emission in kg N-NH3 per hectare |

The combination of `eid` and `tr` defines a trial. The preparation scripts
create the corresponding `eid_tr` identifier. Several plots may belong to the
same trial.

See
[`00_data_preparation/README.md`](../02_scripts/00_data_preparation/README.md)
for the transformations applied before modelling.
