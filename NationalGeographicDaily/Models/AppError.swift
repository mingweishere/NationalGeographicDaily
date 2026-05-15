import Foundation

enum AppError: Error, LocalizedError, Equatable, Sendable {
    case networkUnavailable
    case invalidResponse
    case parsingFailed(String)
    case noData
    case aiExplainerFailed(String)

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
        case .aiExplainerFailed(let detail):
            return detail
        }
    }
}
