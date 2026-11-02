#!/usr/bin/env bash
# Used by: 2 file(s)
set -euo pipefail

if [[ $# -eq 0 ]]; then
  exec /usr/bin/tlp-stat -s
fi

case "$1" in
  eco|on)       exec pkexec /usr/bin/tlp power-saver ;;
  balanced|off) exec pkexec /usr/bin/tlp balanced ;;
  performance)  exec pkexec /usr/bin/tlp performance ;;
  charge-status)
    for start_file in /sys/class/power_supply/BAT*/charge_control_start_threshold; do
      [[ -r "$start_file" ]] || continue
      stop_file="${start_file%charge_control_start_threshold}charge_control_end_threshold"
      [[ -r "$stop_file" ]] || continue
      read -r start < "$start_file"
      read -r stop < "$stop_file"
      if [[ "$start" =~ ^[0-9]+$ && "$stop" =~ ^[0-9]+$ ]]; then
        printf '%s %s\n' "$start" "$stop"
        exit 0
      fi
    done
    printf 'TLP charge thresholds are not available in sysfs\n' >&2
    exit 1
    ;;
  charge)
    if [[ $# -ne 3 ]]; then
      printf 'Usage: %s charge <start 0-99> <stop 1-100>\n' "$0" >&2
      exit 2
    fi
    if [[ ! "$2" =~ ^(0|[1-9][0-9]{0,2})$ || ! "$3" =~ ^(0|[1-9][0-9]{0,2})$ ]]; then
      printf 'Charge thresholds must be whole-number percentages\n' >&2
      exit 2
    fi
    if (( $2 >= $3 || $3 > 100 )); then
      printf 'Charge thresholds must satisfy 0 <= start < stop <= 100\n' >&2
      exit 2
    fi
    exec pkexec /usr/bin/tlp setcharge "$2" "$3"
    ;;
  *)
    printf 'Usage: %s [eco|balanced|performance|on|off|charge <start> <stop>]\n' "$0" >&2
    exit 2
    ;;
esac