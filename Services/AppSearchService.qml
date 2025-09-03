pragma Singleton

pragma ComponentBehavior

import QtQuick
import Quickshell
import "../Common/fzf.js" as Fzf

Singleton {
    id: root

    property var applications: DesktopEntries.applications.values.filter(app => !app.noDisplay && !app.runInTerminal)

    function searchApplications(query) {
        if (!query || query.length === 0)
            return applications
        if (applications.length === 0)
            return []

        const queryLower = query.toLowerCase()
        const scoredApps = []
        
        for (const app of applications) {
            const name = (app.name || "").toLowerCase()
            const genericName = (app.genericName || "").toLowerCase()
            const comment = (app.comment || "").toLowerCase()
            const keywords = app.keywords ? app.keywords.map(k => k.toLowerCase()) : []
            
            let score = 0
            let matched = false
            
            // Exact name match - highest priority
            if (name === queryLower) {
                score = 1000
                matched = true
            }
            // Name starts with query
            else if (name.startsWith(queryLower)) {
                score = 900 - name.length
                matched = true
            }
            // Name contains query as a word
            else if (name.includes(" " + queryLower) || name.includes(queryLower + " ")) {
                score = 800 - name.length
                matched = true
            }
            // Name contains query substring
            else if (name.includes(queryLower)) {
                score = 700 - name.length
                matched = true
            }
            // Check individual keywords
            else if (keywords.length > 0) {
                for (const keyword of keywords) {
                    if (keyword === queryLower) {
                        score = 650  // Exact keyword match
                        matched = true
                        break
                    } else if (keyword.startsWith(queryLower)) {
                        score = 620  // Keyword starts with query
                        matched = true
                        break
                    } else if (keyword.includes(queryLower)) {
                        score = 600  // Keyword contains query
                        matched = true
                        break
                    }
                }
            }
            // Generic name matches
            if (!matched && genericName.includes(queryLower)) {
                score = 500
                matched = true
            }
            // Comment contains query
            else if (!matched && comment.includes(queryLower)) {
                score = 400
                matched = true
            }
            // Fuzzy match on name only (not on all fields)
            else {
                const nameFinder = new Fzf.Finder([app], {
                    "selector": a => a.name || "",
                    "casing": "case-insensitive",
                    "fuzzy": "v2"
                })
                const fuzzyResults = nameFinder.find(query)
                if (fuzzyResults.length > 0 && fuzzyResults[0].score > 0) {
                    score = fuzzyResults[0].score
                    matched = true
                }
            }
            
            if (matched) {
                scoredApps.push({ app, score })
            }
        }
        
        // Sort by score descending
        scoredApps.sort((a, b) => b.score - a.score)
        
        // Return top results
        return scoredApps.slice(0, 50).map(item => item.app)
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
