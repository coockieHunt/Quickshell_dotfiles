import QtQuick

QtObject {
    function stripComments(s) {
        let out = ""
        let inString = false
        let escaped = false

        for (let i = 0; i < s.length; i++) {
            const c = s[i]
            const n = s[i + 1]

            if (inString) {
                out += c
                if (escaped) escaped = false
                else if (c === "\\") escaped = true
                else if (c === '"') inString = false
                continue
            }

            if (c === '"') {
                inString = true
                out += c
                continue
            }

            if (c === "/" && n === "/") {
                while (i < s.length && s[i] !== "\n") i++
                out += "\n"
                continue
            }

            if (c === "/" && n === "*") {
                i += 2
                while (i < s.length && !(s[i] === "*" && s[i + 1] === "/")) i++
                i++
                continue
            }

            out += c
        }
        return out
    }

    function removeTrailingCommas(s) {
        let out = ""
        let inString = false
        let escaped = false

        for (let i = 0; i < s.length; i++) {
            const c = s[i]

            if (inString) {
                out += c
                if (escaped) escaped = false
                else if (c === "\\") escaped = true
                else if (c === '"') inString = false
                continue
            }

            if (c === '"') {
                inString = true
                out += c
                continue
            }

            if (c === ",") {
                let j = i + 1
                while (j < s.length && /\s/.test(s[j])) j++
                if (s[j] === "}" || s[j] === "]")
                    continue
            }

            out += c
        }
        return out
    }

    function parse(source) {
        return JSON.parse(removeTrailingCommas(stripComments(source)))
    }
}
