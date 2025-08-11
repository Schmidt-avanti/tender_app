import Foundation

/// Centralized TED endpoints + direct-link helpers.
enum TedEndpoints {
    static let base = URL(string: "https://ted.europa.eu")!
    static let apiBase = URL(string: "https://ted.europa.eu/api")!

    /// Search API v3
    static var search: URL { apiBase.appendingPathComponent("v3/notices/search") }

    /// Build official direct links per TED schema:
    /// https://ted.europa.eu/{lang}/notice/{publication-number}/{format}
    static func htmlLink(publicationNumber: String, lang: String = Locale.current.language.languageCode?.identifier ?? "de") -> URL {
        base.appendingPathComponent("\(lang)/notice/\(publicationNumber)/html")
    }
    static func pdfLink(publicationNumber: String, lang: String = Locale.current.language.languageCode?.identifier ?? "de", signed: Bool = false) -> URL {
        base.appendingPathComponent("\(lang)/notice/\(publicationNumber)/" + (signed ? "pdfs" : "pdf"))
    }
}
