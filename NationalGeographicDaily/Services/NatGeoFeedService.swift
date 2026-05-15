import Foundation

actor NatGeoFeedService {
    static let shared = NatGeoFeedService()

    private let pageURL: URL

    private init() {
        guard let url = URL(string: "https://www.nationalgeographic.com/photo-of-the-day/") else {
            fatalError("NatGeoFeedService: hardcoded page URL is malformed — this should never happen")
        }
        pageURL = url
    }

    // Fetches the Photo of the Day page, parses it, caches the result, and returns it.
    func fetchLatestPhoto() async throws -> PhotoEntry {
        do {
            var request = URLRequest(url: pageURL, cachePolicy: .reloadIgnoringLocalCacheData)
            request.setValue(
                "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) " +
                "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
                forHTTPHeaderField: "User-Agent"
            )
            request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw AppError.parsingFailed("HTTP \(httpResponse.statusCode) from NatGeo server")
            }

            // Try UTF-8 first, fall back to Latin-1 (common for HTML pages)
            guard let html = String(data: data, encoding: .utf8)
                          ?? String(data: data, encoding: .isoLatin1) else {
                throw AppError.parsingFailed("Could not decode server response as text")
            }

            let parser = NatGeoPageParser()
            guard let entry = parser.parse(html: html) else {
                // Log first 3000 chars so we can inspect the page structure
                print("[NatGeoFeedService] Parse failed. Page preview:\n\(html.prefix(3000))")
                throw AppError.parsingFailed("No photo data found on the page")
            }

            await CacheService.shared.save(entry)
            return entry
        } catch let error as AppError {
            throw error
        } catch {
            print("[NatGeoFeedService] Network error: \(error)")
            throw AppError.networkUnavailable
        }
    }

    // Returns the most recent cached entry without hitting the network.
    func loadCached() async -> PhotoEntry? {
        await CacheService.shared.load()
    }
}
