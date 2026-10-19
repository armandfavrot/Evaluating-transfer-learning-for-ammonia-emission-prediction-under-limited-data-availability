# Figure 3: training and validation procedure

Run `make` in this directory to build `fig_3.pdf` and copy it to `../../pdf/`.

The figure describes the training and validation procedure:

- The validation block retains the original `n_train` notation.
- Initial training uses a learning rate of 1e-4 for all schemes.
- Full and partial fine-tuning use 1e-4; fertilizer-origin-embedding-only fine-tuning uses 2e-3.

Run `make clean` to remove compilation logs and auxiliary files.
