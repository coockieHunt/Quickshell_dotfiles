#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_file="$script_dir/config.jsonc"

if [[ -e "$config_file" ]]; then
    printf 'Keeping existing %s\n' "$config_file"
    exit 0
fi

if ! (set -o noclobber; cat > "$config_file" <<'EOF'
{
  "theme": {
    "bg": "#0f1417",
    "surface": "#1b2023",
    "text": "#dfe3e7",
    "accent": "#8ecff2",
    "textOnAccent": "#003548",
    "buttonHover": "#262b2e"
  },
  "ui": {
    "cornerRadius": 2,
    "accentBorders": true
  },
  "controlPanel": {
    "defaultMode": "both"
  },
  "updates": {
    "applicationCommand": ["octopi"]
  },
  "performance": {
    "statsRefreshSeconds": 3,
    "processRefreshSeconds": 15,
    "temperatureRefreshSeconds": 30
  },
  "powerProfile": {
    "batteryFallbackEnabled": true,
    "batteryFallbackThresholdPercent": 20,
    "batteryFallbackProfile": "balanced",
    "reduceBrightnessInEco": true,
    "tlpChargeModes": {
      "deplacement": {
        "start": 0,
        "stop": 95
      },
      "safe": {
        "start": 75,
        "stop": 80
      }
    }
  },
  "desktopWidgets": {
    "position": "top-left",
    "margin": 5,
    "weather": {
      "location": "Paris",
      "latitude": 48.8566,
      "longitude": 2.3522,
      "refreshMinutes": 30
    },
    "statsRefreshSeconds": 2,
    "networkRefreshSeconds": 20
  },
  "eco": {
    "ecoVolume": 30,
    "ecoBrightness": 30,
    "normalVolume": 60,
    "normalBrightness": 100
  },
  "wallpaperPaletteLabels": {
    "background": "Fond",
    "surface": "Surface",
    "primary": "Primaire",
    "secondary": "Secondaire",
    "tertiary": "Tertiaire"
  }
}
EOF
); then
    if [[ -e "$config_file" ]]; then
        printf 'Keeping existing %s\n' "$config_file"
        exit 0
    fi
    printf 'Could not create %s\n' "$config_file" >&2
    exit 1
fi

printf 'Created %s\n' "$config_file"
