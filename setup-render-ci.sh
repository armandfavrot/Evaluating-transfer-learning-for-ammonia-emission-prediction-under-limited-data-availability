#!/usr/bin/env bash

set -e

# Convert precomputed PDF figures to SVG for the HTML manuscript.
sudo apt-get update
sudo apt-get install -y poppler-utils

printf '\nRunning the reproducibility example\n'
sh 02_scripts/04_reproducibility_example/run_all.sh

# Check that the example produced all expected non-empty outputs.
(
    cd 02_scripts/04_reproducibility_example

    for file in \
        results/df_res_1.csv \
        results/run_report.json \
        images/fig_1.pdf \
        images/fig_2.pdf \
        images/fig_3.pdf
    do
        if [ ! -s "$file" ]; then
            printf 'Missing or empty output: %s\n' "$file" >&2
            exit 1
        fi
    done
)

printf 'Reproducibility example completed successfully.\n'
