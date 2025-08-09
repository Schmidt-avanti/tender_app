import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

struct ChatChoice: Codable {
    let index: Int
    let message: ChatMessage
}

struct ChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let choices: [ChatChoice]
}

enum OpenAIModel: String {
    // Kosteneffizientes, multimodales Modell (Text)
    case gpt4oMini = "gpt-4o-mini"
    // Fallback
    case gpt35Turbo = "gpt-3.5-turbo"
}

final class OpenAIClient {
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String = AppSecrets.openAIKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func complete(
        systemPrompt: String,
        userPrompt: String,
        model: OpenAIModel = .gpt4oMini,
        temperature: Double = 0.2
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "OpenAI", code: -10, userInfo: [NSLocalizedDescriptionKey: "OpenAI API Key fehlt."])
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatRequest(
            model: model.rawValue,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            temperature: temperature
        )

        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let txt = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "OpenAI", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI-Fehler: \(txt)"])
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }
}