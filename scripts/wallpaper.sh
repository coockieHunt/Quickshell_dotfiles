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

delete_wallpaper() {
    local wallpaper=$1
    local wallpaper_root resolved_wallpaper current_wallpaper=""

    if [[ ! -d "$wallpaper_dir" ]]; then
        printf 'Wallpaper directory not found: %s\n' "$wallpaper_dir" >&2
        return 1
    fi

    wallpaper_root=$(realpath -e -- "$wallpaper_dir")
    if ! resolved_wallpaper=$(realpath -e -- "$wallpaper"); then
        printf 'Wallpaper not found: %s\n' "$wallpaper" >&2
        return 1
    fi

    if [[ -L "$wallpaper" ||
          "$(dirname -- "$resolved_wallpaper")" != "$wallpaper_root" ||
          ! -f "$resolved_wallpaper" ]]; then
        printf 'Wallpaper must be a file directly inside %s\n' "$wallpaper_root" >&2
        return 1
    fi

    if [[ -f "$current_file" ]]; then
        IFS= read -r current_wallpaper < "$current_file" || true
        if [[ -n "$current_wallpaper" ]]; then
            current_wallpaper=$(realpath -m -- "$current_wallpaper")
        fi
    fi

    rm -- "$resolved_wallpaper"
    if [[ "$current_wallpaper" == "$resolved_wallpaper" ]]; then
        mkdir -p "${HOME}/.cache"
        : > "$current_file"
    fi
}

case "${1:-}" in
    set)
        if [[ $# -ne 2 ]]; then
            printf 'Usage: %s set <wallpaper> | delete <wallpaper> | random\n' "$0" >&2
            exit 2
        fi
        apply_wallpaper "$2"
        ;;
    delete)
        if [[ $# -ne 2 ]]; then
            printf 'Usage: %s set <wallpaper> | delete <wallpaper> | delete-current | random\n' "$0" >&2
            exit 2
        fi
        delete_wallpaper "$2"
        ;;
    delete-current)
        if [[ $# -ne 1 ]]; then
            printf 'Usage: %s set <wallpaper> | delete <wallpaper> | delete-current | random\n' "$0" >&2
            exit 2
        fi

        current_wallpaper=""
        if [[ -f "$current_file" ]]; then
            IFS= read -r current_wallpaper < "$current_file" || true
        fi
        if [[ -z "$current_wallpaper" ]]; then
            printf 'No current wallpaper is set\n' >&2
            exit 1
        fi

        delete_wallpaper "$current_wallpaper"
        "$0" random
        ;;
    random)
        if [[ $# -ne 1 ]]; then
            printf 'Usage: %s set <wallpaper> | delete <wallpaper> | delete-current | random\n' "$0" >&2
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
        printf 'Usage: %s set <wallpaper> | delete <wallpaper> | delete-current | random\n' "$0" >&2
        exit 2
        ;;
esac
