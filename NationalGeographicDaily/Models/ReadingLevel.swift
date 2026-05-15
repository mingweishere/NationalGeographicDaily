import Foundation

enum ReadingLevel: String, CaseIterable, Identifiable {
    case simple
    case standard
    case expert

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simple:   return "Simple"
        case .standard: return "Standard"
        case .expert:   return "Expert"
        }
    }

    var promptInstruction: String {
        switch self {
        case .simple:
            return "Explain this as if talking to a curious 10-year-old. Use short sentences, simple words, one vivid analogy, and end with a fun fact."
        case .standard:
            return "Expand this story for a general adult reader. Add geographic context, ecological or historical significance, and one surprising detail not in the original."
        case .expert:
            return "Write a detailed explanation for an enthusiast. Include scientific names where relevant, conservation status, specific geographic region, and explain what makes this photo scientifically or culturally significant."
        }
    }
}
