#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

printf '[1/5] Creating data-description figures\n'
Rscript data_description.R

printf '\n[2/5] Creating full fine-tuning figures\n'
Rscript results_transfer_01.R

printf '\n[3/5] Creating partial fine-tuning figures\n'
Rscript results_transfer_02.R

printf '\n[4/5] Creating embedding-only fine-tuning figures\n'
Rscript results_transfer_03.R

printf '\n[5/5] Creating loss figure\n'
python loss_examples.py

printf '\nAll figures were saved to: pdf/\n'
