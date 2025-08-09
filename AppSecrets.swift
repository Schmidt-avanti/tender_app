import Foundation

enum AppSecrets {
    // Nur lokal befüllen; im CI kommen die Keys aus Info.plist (siehe codemagic.yaml)
    static let openAIKey: String = ""      // <- leer lassen; wir lesen Info.plist
    static let serpApiKey: String = "eed7bd4607b6533f91f12a91532c14eca751a6aad469142ecb573e6c3f8dd50b"     // optionaler Fallback
    static let bingApiKey: String = ""     // optionaler Fallback
}
