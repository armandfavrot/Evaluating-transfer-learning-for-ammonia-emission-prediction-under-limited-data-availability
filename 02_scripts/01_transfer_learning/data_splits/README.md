# Data splits

The script `create_data_splits.py` creates the training, validation, and test
trial identifiers used by the three transfer-learning scripts.

The complete partitioning procedure is repeated ten times, using the repetition
number as its random seed. Within each repetition, target micrometeorological
trials are divided into five test folds. For each test fold, `p = 10, 20, 40,
80` trials are sampled from all non-test trials; 15% (with a minimum of five)
are used for validation and the remainder for training. For `p = all`, all
non-test trials are used, with the same training-validation split.

Source-domain and alternative-method training-validation partitions are also
recreated independently for each repetition. The resulting nested dictionaries
are stored as the seven `.pkl` files in this directory.

The splits are normally recreated by `../run_all.sh`. To create them alone,
run from `01_transfer_learning/`:

```sh
python3 data_splits/create_data_splits.py
```

The generated `.pkl` files should not be edited manually.
