import QtQuick

Item {
    visible: false

    function filterApplications(applications, query) {
        const normalizedQuery = query.trim().toLowerCase()
        return applications
            .filter(entry => entry.name.toLowerCase().includes(normalizedQuery))
            .sort((a, b) => a.name.localeCompare(b.name))
    }

    function detailsFor(entry) {
        return [
            { label: "Description", value: entry.comment },
            { label: "Identifiant .desktop", value: entry.id },
            { label: "Commande", value: entry.execString },
            { label: "Dossier de travail", value: entry.workingDirectory },
            { label: "Catégories", value: entry.categories.join(", ") },
            { label: "Mots-clés", value: entry.keywords.join(", ") },
            { label: "Terminal", value: entry.runInTerminal ? "Oui" : "Non" },
            { label: "Masqué du lanceur", value: entry.noDisplay ? "Oui" : "Non" }
        ].filter(item => item.value !== "" && item.value !== null)
    }
}
