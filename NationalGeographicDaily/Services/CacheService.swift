import Foundation

actor CacheService {
    static let shared = CacheService()

    private let defaults: UserDefaults
    private let cacheKey = "com.natgeodaily.photo_entry"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    func save(_ entry: PhotoEntry) {
        guard let data = try? encoder.encode(entry) else { return }
        defaults.set(data, forKey: cacheKey)
    }

    func load() -> PhotoEntry? {
        guard let data = defaults.data(forKey: cacheKey),
              let entry = try? decoder.decode(PhotoEntry.self, from: data) else { return nil }
        return entry
    }

    func clear() {
        defaults.removeObject(forKey: cacheKey)
    }
}
