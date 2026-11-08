#!/usr/bin/env bash
set -euo pipefail

applications_dir="${XDG_DATA_HOME:-"$HOME/.local/share"}/applications"
mkdir -p "$applications_dir"
exec dolphin "$applications_dir"
