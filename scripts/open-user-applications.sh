#!/usr/bin/env bash
set -euo pipefail

applications_dir="${XDG_DATA_HOME:-"$HOME/.local/share"}/applications"
file_manager="${1:-dolphin}"
mkdir -p "$applications_dir"
exec "$file_manager" "$applications_dir"
