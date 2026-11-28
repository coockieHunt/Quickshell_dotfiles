import QtQuick

QtObject {
    function parse(source) {
        let uncommented = ""
        let inString = false
        let escaped = false

        for (let i = 0; i < source.length; i++) {
            const char = source[i]
            const next = source[i + 1]

            if (inString) {
                uncommented += char
                if (escaped)
                    escaped = false
                else if (char === "\\")
                    escaped = true
                else if (char === '"')
                    inString = false
            } else {
                if (char === '"')
                    inString = true
                else if (char === "/" && next === "/")
                    break
                else if (char === "/" && next === "*") {
                    const end = source.indexOf("*/", i + 2)
                    if (end === -1)
                        break
                    i = end + 1
                } else
                    uncommented += char
            }
        }

        return JSON.parse(normalizeTrailingCommas(uncommented))
    }

    function normalizeTrailingCommas(source) {
        let normalized = ""
        let inString = false
        let escaped = false

        for (let i = 0; i < source.length; i++) {
            const char = source[i]

            if (inString) {
                normalized += char
                if (escaped)
                    escaped = false
                else if (char === "\\")
                    escaped = true
                else if (char === '"')
                    inString = false
            } else {
                if (char === '"')
                    inString = true

                if (char === "," || char === "{" || char === "[") {
                    normalized += char
                } else {
                    const trimmed = normalizedTrimEnd(normalized)
                    const last = trimmed[trimmed.length - 1]
                    if (char === "}" || char === "]") {
                        if (last === ",")
                            normalized = trimmed
                        normalized += char
                    } else {
                        normalized += char
                    }
                }
            }
        }

        return normalized
    }

    function normalizedTrimEnd(str) {
        let end = str.length
        while (end > 0 && /\s/.test(str[end - 1]))
            end--
        return str.slice(0, end)
    }
}
