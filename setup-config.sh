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
    // Defines the main interface colors.
    "theme": {
        "bg": "#0f1417",
        "surface": "#1b2023",
        "text": "#dfe3e7",
        "accent": "#8ecff2",
        "textOnAccent": "#003548",
        "buttonHover": "#262b2e",
    },

    // Highlights the central island border while the Super key is held.
    // "var" must match superHighlightVar in ~/.config/hypr/keybinding.lua.
    "superHighlight": {
        "enabled": true,
        "var": "superHeld",
    },

    // Sets the Hyprland keybinding file shown in the macros panel.
    "keybindings": {
        "file": "~/.config/hypr/keybinding.lua",
    },

    // Defines the sounds played on USB, battery and charger events.
    "watchers": {
        "soundDir": "/usr/share/sounds/freedesktop/stereo",
        "soundExt": "oga",
        "sounds": {
            "plug": "power-plug",
            "unplug": "power-unplug",
            "batteryLow": "battery-low",
            "usbAdd": "device-added",
            "usbRemove": "device-removed"
        }
    },

    // Defines global fonts and sizes.
    "fonts": {
        "text": "sans-serif",
        "mono": "monospace",
        "icons": "Material Symbols Rounded",
        "brand": "JetBrainsMono Nerd Font",
        "logo": "\uf303",
        "textSize": 13,
        "iconSize": 16,
    },

    // Sets shared corner and border styles.
    "ui": {
        "cornerRadius": 2,
        "accentBorders": true,
    },

    // Chooses the default control panel view.
    "controlPanel": {
        "defaultMode": "both",
    },

    // Sets the web search URL; {query} is replaced with the encoded search text.
    "launcher": {
        "searchUrl": "https://duckduckgo.com/?q={query}",
    },

    // Sets the weather shown in the bar (Open-Meteo, no API key needed).
    "weather": {
        "enabled": true,
        "latitude": 48.8566,
        "longitude": 2.3522,
        "refreshMinutes": 30,
    },

    // Sets the applications used by the bar and file-opening actions.
    "apps": {
        "wifi": "nm-connection-editor",
        "bluetooth": "blueman-manager",
        "fileManager": "dolphin",
        "textEditor": "kate",
    },

    // Sets bar actions. Use "none" to disable a right-click action.
    "panel": {
        "wifi": {
            "rightClick": "toggle",
        },
        "bluetooth": {
            "rightClick": "toggle",
        },
    },

    // Sets system statistics refresh intervals, in seconds.
    "performance": {
        "statsRefreshSeconds": 3,
        "processRefreshSeconds": 15,
        "temperatureRefreshSeconds": 30,
    },

    // Configures low-battery power behavior and TLP charge limits.
    "powerProfile": {
        "batteryFallbackEnabled": true,
        "batteryFallbackThresholdPercent": 20,
        "batteryFallbackProfile": "balanced",
        "reduceBrightnessInEco": true,
        "tlpChargeModes": {
            "deplacement": {
                "start": 0,
                "stop": 95,
            },
            "safe": {
                "start": 75,
                "stop": 80,
            },
        },
    },

    // Sets the folder used by the wallpaper picker and wallpaper actions.
    "wallpaper": {
        "directory": "~/Pictures/wallpapers",
    },

    // Defines eco and normal sound and brightness levels.
    "eco": {
        "ecoVolume": 30,
        "ecoBrightness": 30,
        "normalVolume": 60,
        "normalBrightness": 100,
    },

    // Provides labels for wallpaper palette colors.
    "wallpaperPaletteLabels": {
        "background": "Fond",
        "surface": "Surface",
        "primary": "Primaire",
        "secondary": "Secondaire",
        "tertiary": "Tertiaire",
    },
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
