pragma Singleton

pragma ComponentBehavior

import QtQuick
import Quickshell
import "../Common/fuzzysort.js" as Fuzzy

Singleton {
    id: root

    property var applications: DesktopEntries.applications.values.filter(app => !app.noDisplay && !app.runInTerminal)

    property var preppedApps: applications.map(app => ({
                                                           "name": Fuzzy.prepare(app.name || ""),
                                                           "comment": Fuzzy.prepare(app.comment || ""),
                                                           "entry": app
                                                       }))

    function searchApplications(query) {
        if (!query || query.length === 0)
            return applications
        if (preppedApps.length === 0)
            return []

        var results = Fuzzy.go(query, preppedApps, {
                                   "all": false,
                                   "keys": ["name", "comment"],
                                   "scoreFn": r => {
                                       const nameScore = r[0]?.score || 0
                                       const commentScore = r[1]?.score || 0
                                       const appName = r.obj.entry.name || ""

                                       if (nameScore === 0) {
                                           return commentScore * 0.1
                                       }

                                       const queryLower = query.toLowerCase()
                                       const nameLower = appName.toLowerCase()

                                       if (nameLower === queryLower) {
                                           return nameScore * 100
                                       }
                                       if (nameLower.startsWith(queryLower)) {
                                           return nameScore * 50
                                       }
                                       if (nameLower.includes(" " + queryLower) || nameLower.includes(queryLower + " ") || nameLower.endsWith(" " + queryLower)) {
                                           return nameScore * 25
                                       }
                                       if (nameLower.includes(queryLower)) {
                                           return nameScore * 10
                                       }

                                       return nameScore * 2 + commentScore * 0.1
                                   },
                                   "limit": 50
                               })

        return results.map(r => r.obj.entry)
    }

    function getCategoriesForApp(app) {
        if (!app?.categories)
            return []

        const categoryMap = {
            "AudioVideo": "Media",
            "Audio": "Media",
            "Video": "Media",
            "Development": "Development",
            "TextEditor": "Development",
            "IDE": "Development",
            "Education": "Education",
            "Game": "Games",
            "Graphics": "Graphics",
            "Photography": "Graphics",
            "Network": "Internet",
            "WebBrowser": "Internet",
            "Email": "Internet",
            "Office": "Office",
            "WordProcessor": "Office",
            "Spreadsheet": "Office",
            "Presentation": "Office",
            "Science": "Science",
            "Settings": "Settings",
            "System": "System",
            "Utility": "Utilities",
            "Accessories": "Utilities",
            "FileManager": "Utilities",
            "TerminalEmulator": "Utilities"
        }

        const mappedCategories = new Set()

        for (const cat of app.categories) {
            if (categoryMap[cat])
                mappedCategories.add(categoryMap[cat])
        }

        return Array.from(mappedCategories)
    }

    property var categoryIcons: ({
                                     "All": "apps",
                                     "Media": "music_video",
                                     "Development": "code",
                                     "Games": "sports_esports",
                                     "Graphics": "photo_library",
                                     "Internet": "web",
                                     "Office": "content_paste",
                                     "Settings": "settings",
                                     "System": "host",
                                     "Utilities": "build"
                                 })

    function getCategoryIcon(category) {
        return categoryIcons[category] || "folder"
    }

    function getAllCategories() {
        const categories = new Set(["All"])

        for (const app of applications) {
            const appCategories = getCategoriesForApp(app)
            appCategories.forEach(cat => categories.add(cat))
        }

        return Array.from(categories).sort()
    }

    function getAppsInCategory(category) {
        if (category === "All") {
            return applications
        }

        return applications.filter(app => {
                                       const appCategories = getCategoriesForApp(app)
                                       return appCategories.includes(category)
                                   })
    }
}
