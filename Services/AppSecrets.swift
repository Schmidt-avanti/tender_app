import Foundation

enum AppSecrets {
    static let openAIKey  = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    static let serpApiKey = ProcessInfo.processInfo.environment["SERP_API_KEY"] ?? ""
    static let bingApiKey = ProcessInfo.processInfo.environment["BING_API_KEY"] ?? ""
}
