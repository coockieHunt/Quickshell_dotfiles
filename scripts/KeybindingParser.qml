import QtQuick

Item {
    visible: false

    function parseKeybindings(contents) {
        const lines = contents.split("\n")
        const bindings = []
        let description = ""
        let ignoreNext = false

        for (let rawLine of lines) {
            const line = rawLine.trim()

            const titleMatch = line.match(/^--\s*@title(?:\s*:\s*|\s+)(.*)$/)
            if (titleMatch) {
                const title = titleMatch[1].trim()
                if (title !== "")
                    bindings.push({ type: "title", title: title })
                description = ""
                ignoreNext = false
                continue
            }

            if (line.startsWith("-- @ignore")) {
                ignoreNext = true
                continue
            }

            if (line.startsWith("-- @desc:")) {
                description = line.substring(9).trim()
                continue
            }

            if (line.startsWith("--") || line === "")
                continue

            const match = line.match(/hl\.bind\(\s*(.*?),\s*hl\.dsp\./)
            if (match) {
                const skip = ignoreNext || match[1].includes("XF86")
                const desc = description

                ignoreNext = false
                description = ""

                if (skip)
                    continue

                const shortcut = match[1].includes("keyCode")
                    ? (match[1].includes("SHIFT") ? "SUPER + MAJ + chiffre" : "SUPER + chiffre")
                    : match[1]
                        .replace(/\bmainMod\b/g, "SUPER")
                        .replace(/"\s*\.\.\s*/g, "")
                        .replace(/\s*\.\.\s*/g, "")
                        .replace(/"/g, "")
                        .trim()

                bindings.push({
                    type: "binding",
                    shortcut: shortcut,
                    description: desc || "Raccourci clavier"
                })
                continue
            }

            if (!line.startsWith("hl.bind(") && !line.startsWith("local closeWindowBind = hl.bind(")) {
                description = ""
                ignoreNext = false
            }
        }

        return bindings
    }
}
