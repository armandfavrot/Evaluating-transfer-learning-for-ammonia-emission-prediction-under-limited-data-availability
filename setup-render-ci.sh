#!/usr/bin/env bash

set -e

# Convert precomputed PDF figures to SVG for the HTML manuscript.
sudo apt-get update
sudo apt-get install -y poppler-utils
