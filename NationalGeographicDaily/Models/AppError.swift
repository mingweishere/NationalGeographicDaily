import Foundation

enum AppError: Error, LocalizedError, Sendable {
    case networkUnavailable
    case invalidResponse
    case parsingFailed(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Showing cached content."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .parsingFailed(let detail):
            return "Could not read the photo feed: \(detail)"
        case .noData:
            return "No photo is available yet. Please try again later."
        }
    }
}
