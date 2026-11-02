#!/usr/bin/env bash
set -euo pipefail

# Append max_parallel_downloads setting to dnf.conf
sudo sh -c 'echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf'

# Run system upgrade
sudo dnf upgrade
