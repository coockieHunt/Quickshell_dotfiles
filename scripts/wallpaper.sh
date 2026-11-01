#!/usr/bin/env bash
# Used by: 3 file(s)
set -euo pipefail

wallpaper_dir="${HOME}/Pictures/wallpapers"
current_file="${HOME}/.cache/qs-wallpaper"

apply_wallpaper() {
    local wallpaper=$1
    if [[ ! -f "$wallpaper" ]]; then
        printf 'Wallpaper not found: %s\n' "$wallpaper" >&2
        exit 1
    fi

    matugen image "$wallpaper" -m dark --source-color-index 0
    mkdir -p "${HOME}/.cache"
    printf '%s\n' "$wallpaper" > "$current_file"
}

case "${1:-}" in
    set)
        if [[ $# -ne 2 ]]; then
            printf 'Usage: %s set <wallpaper> | random\n' "$0" >&2
            exit 2
        fi
        apply_wallpaper "$2"
        ;;
    random)
        if [[ $# -ne 1 ]]; then
            printf 'Usage: %s set <wallpaper> | random\n' "$0" >&2
            exit 2
        fi

        current_wallpaper=""
        if [[ -f "$current_file" ]]; then
            IFS= read -r current_wallpaper < "$current_file" || true
        fi

        mapfile -d '' wallpapers < <(
            find "$wallpaper_dir" -maxdepth 1 -type f \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
                ! -path "$current_wallpaper" -print0
        )

        if [[ ${#wallpapers[@]} -eq 0 ]]; then
            printf 'No alternate wallpapers found in %s\n' "$wallpaper_dir" >&2
            exit 1
        fi

        apply_wallpaper "${wallpapers[RANDOM % ${#wallpapers[@]}]}"
        ;;
    *)
        printf 'Usage: %s set <wallpaper> | random\n' "$0" >&2
        exit 2
        ;;
esac
