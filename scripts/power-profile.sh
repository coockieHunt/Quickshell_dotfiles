#!/usr/bin/env bash
# Used by: 2 file(s)
set -euo pipefail

if [[ $# -eq 0 ]]; then
  sudo -n /usr/bin/tlp-stat -s | grep -i "TLP profile"
  exit
fi

case "$1" in
  eco|on)       exec sudo -n /usr/bin/tlp power-saver ;;
  balanced|off) exec sudo -n /usr/bin/tlp balanced ;;
  performance)  exec sudo -n /usr/bin/tlp performance ;;
  *)
    printf 'Usage: %s [eco|balanced|performance|on|off]\n' "$0" >&2
    exit 2
    ;;
esac