import Foundation

struct ExtractedTender: Codable {
    let id: String
    let title: String
    let buyer: String?
    let location: String?
    let deadlineISO8601: String?
    let budget: String?
    let summary: String?
}

final class TenderExtractor {
    private let openai: OpenAIClient

    init(openai: OpenAIClient = OpenAIClient()) {
        self.openai = openai
    }

    func extract(from plainText: String, sourceURL: URL) async throws -> Tender? {
        let system = """
        Du bist ein Assistent, der Ausschreibungstexte in strukturierte Felder extrahiert.
        Antworte NUR mit JSON, kein Fließtext. Felder: id, title, buyer, location, deadlineISO8601, budget, summary.
        Wenn es keine Ausschreibung ist, gib {"id": "", "title": "", ...} mit leerem id zurück.
        Das Datum im ISO-8601 Format (YYYY-MM-DD) ausgeben, wenn vorhanden.
        """
        let prompt = """
        TEXT:
        \(plainText.prefix(8000))

        QUELLE: \(sourceURL.absoluteString)
        Bitte extrahiere die Daten als JSON.
        """
        let output = try await openai.complete(systemPrompt: system, userPrompt: prompt, model: .gpt4oMini, temperature: 0.1)
        guard let data = output.data(using: .utf8) else { return nil }
        let json = Self.firstJSONObject(in: data) ?? data
        let decoded = try? JSONDecoder().decode(ExtractedTender.self, from: json)
        guard let ex = decoded, !ex.id.trimmingCharacters(in: .whitespaces).isEmpty || !ex.title.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        var deadlineDate: Date? = nil
        if let iso = ex.deadlineISO8601 {
            deadlineDate = ISO8601DateFormatter().date(from: iso) ?? Self.dateFromYYYYMMDD(iso)
        }
        return Tender(
            id: !ex.id.isEmpty ? ex.id : UUID().uuidString,
            title: ex.title,
            buyer: ex.buyer,
            location: ex.location,
            deadline: deadlineDate,
            budget: ex.budget,
            url: sourceURL,
            summary: ex.summary,
            source: sourceURL.host
        )
    }

    private static func dateFromYYYYMMDD(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }

    private static func firstJSONObject(in data: Data) -> Data? {
        let s = String(data: data, encoding: .utf8) ?? ""
        guard let start = s.firstIndex(of: "{"), let end = s.lastIndex(of: "}") else { return nil }
        let jsonStr = String(s[start...end])
        return jsonStr.data(using: .utf8)
    }
}