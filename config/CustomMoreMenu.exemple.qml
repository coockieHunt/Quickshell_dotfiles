import QtQuick

QtObject {
    // Entry appears in the "Custom" category of the menu.
    // - label   : text displayed in the menu
    // - action  : unique identifier, must start with "custom:"
    // - command : shell command executed on click
    // - confirm : (optional) message shown in a confirm dialog before running
    readonly property var items: [
        { label: "Captures", action: "custom:capture", command: "hyprshot -m region" },
        { label: "Lock", action: "custom:lock", command: "hyprlock" },
        { label: "Terminal", action: "custom:terminal", command: "kitty" },
        { label: "Screen off", action: "custom:screenoff", command: "hyprctl dispatch dpms off" },
        { label: "Notes", action: "custom:notes", command: "kate $HOME/notes.md" },
        {
            label: "Test confirm",
            action: "custom:testconfirm",
            command: "notify-send 'Test' 'Test action executed'",
            confirm: "Run the useless test action?"
        }
    ]

    // Do not edit
    function find(action) {
        return items.find(i => i.action === action) ?? null
    }
}
