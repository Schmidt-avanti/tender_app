import Foundation

/// Offizielle TED-Endpoints (statisch, keine Initialisierung nötig)
public enum TedEndpoints {
    /// Basis (Host)
    public static let base = URL(string: "https://ted.europa.eu")!

    /// Search-POST (anonym nutzbar)
    public static var search: URL {
        base.appendingPathComponent("/api/v3/notices/search")
    }

    /// Direktlink (HTML) – Schema siehe README
    public static func html(lang: String, publicationNumber: String) -> URL? {
        URL(string: "https://ted.europa.eu/\(lang)/notice/\(publicationNumber)/html")
    }

    /// Direktlink (PDF) – Schema siehe README
    public static func pdf(lang: String, publicationNumber: String) -> URL? {
        URL(string: "https://ted.europa.eu/\(lang)/notice/\(publicationNumber)/pdf")
    }
}
