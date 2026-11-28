import QtQuick

QtObject {
    function isValidTheme(theme) {
        const keys = [
            "bg", "surface", "text",
            "accent", "textOnAccent", "buttonHover"
        ]

        return theme
            && keys.every(key =>
                typeof theme[key] === "string"
                && /^#?[0-9a-fA-F]{6}$/.test(theme[key])
            )
    }
}
