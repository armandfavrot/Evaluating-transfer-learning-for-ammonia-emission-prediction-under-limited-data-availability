#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

printf '[1/4] Creating data splits\n'
python data_splits/create_data_splits.py

printf '\n[2/4] Running transfer_01.py\n'
python transfer_01.py

printf '\n[3/4] Running transfer_02.py\n'
python transfer_02.py

printf '\n[4/4] Running transfer_03.py\n'
python transfer_03.py
