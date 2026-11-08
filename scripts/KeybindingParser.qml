import QtQuick

Item {
    visible: false

    function parseKeybindings(contents) {
        const lines = contents.split("\n")
        const bindings = []
        let description = ""

        for (let line of lines) {
            line = line.trim()

            if (line.startsWith("-- @desc:")) {
                description = line.substring(9).trim()
                continue
            }

            if (line.startsWith("--") || line === "") {
                if (!line.startsWith("-- @desc:"))
                    description = ""
                continue
            }

            const match = line.match(/hl\.bind\(\s*(.*?),\s*hl\.dsp\./)
            if (match) {
                const shortcut = match[1].includes("keyCode")
                    ? (match[1].includes("SHIFT") ? "SUPER + MAJ + chiffre" : "SUPER + chiffre")
                    : match[1]
                        .replace(/\bmainMod\b/g, "SUPER")
                        .replace(/"\s*\.\.\s*/g, "")
                        .replace(/\s*\.\.\s*/g, "")
                        .replace(/"/g, "")
                        .trim()

                bindings.push({
                    shortcut: shortcut,
                    description: description || "Raccourci clavier"
                })
            }

            if (!line.startsWith("hl.bind(") && !line.startsWith("local closeWindowBind = hl.bind("))
                description = ""
        }

        return bindings
    }
}
