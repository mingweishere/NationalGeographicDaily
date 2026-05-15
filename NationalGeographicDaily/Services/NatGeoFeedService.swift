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
            var request = URLRequest(url: feedURL, cachePolicy: .reloadIgnoringLocalCacheData)
            // Some media servers block the default CFNetwork User-Agent; a
            // browser-style string ensures the feed is served normally.
            request.setValue(
                "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) " +
                "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
                forHTTPHeaderField: "User-Agent"
            )
            request.setValue("application/rss+xml, application/xml, text/xml", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw AppError.parsingFailed("HTTP \(httpResponse.statusCode) from feed server")
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
