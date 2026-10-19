#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DATA_FILE="$SCRIPT_DIR/../00_data_preparation/data_without_caractair.csv"

if [ ! -f "$DATA_FILE" ]; then
    printf '%s\n' \
        'Missing data_without_caractair.csv.' \
        'Run data_preparation_without_caractair.R from 00_data_preparation first.' \
        >&2
    exit 1
fi

cd "$SCRIPT_DIR"

printf '[1/3] Creating data splits\n'
python3 data_splits/create_data_splits.py

printf '\n[2/3] Running transfer_01.py\n'
python3 transfer_01.py

printf '\n[3/3] Creating reproducibility figures\n'
Rscript results_transfer_01.R
