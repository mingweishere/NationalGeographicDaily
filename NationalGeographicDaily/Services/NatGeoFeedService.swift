import Foundation

actor NatGeoFeedService {
    static let shared = NatGeoFeedService()

    private let feedURL: URL

    private init() {
        guard let url = URL(string: "https://www.nationalgeographic.com/rss/photography/photo-of-the-day") else {
            fatalError("NatGeoFeedService: hardcoded feed URL is malformed — this should never happen")
        }
        feedURL = url
    }

    // Fetches the latest photo from the RSS feed, caches it, and returns it.
    // Throws AppError on network or parse failure.
    func fetchLatestPhoto() async throws -> PhotoEntry {
        do {
            let (data, response) = try await URLSession.shared.data(from: feedURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AppError.invalidResponse
            }

            let parser = RSSParser()
            guard let entry = parser.parse(data: data) else {
                throw AppError.parsingFailed("No photo entry found in feed")
            }

            await CacheService.shared.save(entry)
            return entry
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.networkUnavailable
        }
    }

    // Returns the most recent cached entry without hitting the network.
    func loadCached() async -> PhotoEntry? {
        await CacheService.shared.load()
    }
}
