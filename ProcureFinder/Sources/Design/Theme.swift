import SwiftUI

enum Theme {
    static let accent = Color.blue
    static let background = Color(UIColor.systemBackground)
    static let secondaryBG = Color(UIColor.secondarySystemBackground)
    static let text = Color.primary
}

struct L10n {
    static func t(_ key: Key) -> String {
        let lang = Locale.current.language.languageCode?.identifier ?? "de"
        switch (key, lang) {
        case (.searchTitle, "en"): return "Search"
        case (.searchTitle, _): return "Suche"
        case (.filters, "en"): return "Filters"
        case (.filters, _): return "Filter"
        case (.apply, "en"): return "Apply"
        case (.apply, _): return "Übernehmen"
        case (.results, "en"): return "Results"
        case (.results, _): return "Ergebnisse"
        case (.openPDF, "en"): return "Open PDF"
        case (.openPDF, _): return "PDF öffnen"
        case (.openHTML, "en"): return "Open HTML"
        case (.openHTML, _): return "HTML öffnen"
        case (.favorite, "en"): return "Favorite"
        case (.favorite, _): return "Favorisieren"
        case (.share, "en"): return "Share"
        case (.share, _): return "Teilen"
        case (.empty, "en"): return "No results"
        case (.empty, _): return "Keine Ergebnisse"
        case (.error, "en"): return "Error loading"
        case (.error, _): return "Fehler beim Laden"
        case (.cpvPicker, "en"): return "CPV Codes"
        case (.cpvPicker, _): return "CPV-Codes"
        }
    }
    enum Key { case searchTitle, filters, apply, results, openPDF, openHTML, favorite, share, empty, error, cpvPicker }
}
