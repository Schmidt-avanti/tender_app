import Foundation

enum AppSecrets {
    static var openAIKey: String {
        if let fromEnv = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !fromEnv.isEmpty {
            return fromEnv
        }
        return "YOUR_OPENAI_API_KEY"
    }
    static var serpApiKey: String {
        if let fromEnv = ProcessInfo.processInfo.environment["SERP_API_KEY"], !fromEnv.isEmpty {
            return fromEnv
        }
        return "" // optional
    }
    static var bingApiKey: String {
        if let fromEnv = ProcessInfo.processInfo.environment["BING_API_KEY"], !fromEnv.isEmpty {
            return fromEnv
        }
        return "" // optional
    }
}