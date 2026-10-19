# Data preparation

Two scripts apply the same preparation steps:

- `data_preparation.R` combines `data_alfam2.csv` and the restricted
  `data_caractair.csv`, producing `data.csv` for the complete analysis;
- `data_preparation_without_caractair.R` uses only `data_alfam2.csv`, producing
  `data_without_caractair.csv` for the public reproducibility example.

The main preparation steps are:

- reducing the temporal resolution of very long time series;
- recalculating interval and cumulative emission variables;
- handling missing and non-applicable values;
- creating missing-value indicators;
- scaling numerical variables and encoding categorical variables;
- retaining unscaled values in columns ending in `_origin`.

Run the required script from this directory:

```sh
Rscript data_preparation.R
```

or, for the public reproducibility example:

```sh
Rscript data_preparation_without_caractair.R
```

Each output contains one row per measurement interval. The scaled columns are
used as model inputs, while the `_origin` columns retain values in their
original units for interpretation and evaluation.
