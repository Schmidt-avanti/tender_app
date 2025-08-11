import Foundation

final class DetailViewModel: ObservableObject {
    @Published var notice: Notice

    init(notice: Notice) {
        self.notice = notice
    }

    /// Bevorzugt Systemsprache (de/en), fällt auf "en" zurück
    private var lang: String {
        let code = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        return (code == "de") ? "de" : "en"
    }

    /// Direktlink HTML gem. TED-Schema
    var htmlURL: URL {
        if let url = TedEndpoints.html(lang: lang, publicationNumber: notice.publicationNumber) {
            return url
        }
        // Fallback (sollte eigentlich nie passieren)
        return URL(string: "https://ted.europa.eu/en/notice/\(notice.publicationNumber)/html")!
    }

    /// Direktlink PDF gem. TED-Schema
    var pdfURL: URL {
        if let url = TedEndpoints.pdf(lang: lang, publicationNumber: notice.publicationNumber) {
            return url
        }
        // Fallback
        return URL(string: "https://ted.europa.eu/en/notice/\(notice.publicationNumber)/pdf")!
    }
}
