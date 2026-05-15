import Foundation
import Observation

@Observable
final class HomeViewModel {
    var photoEntry: PhotoEntry?
    var isLoading = false
    var error: AppError?

    func loadPhoto() async {
        // Serve cache immediately for offline-first experience
        if let cached = await NatGeoFeedService.shared.loadCached() {
            photoEntry = cached
        }

        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            photoEntry = try await NatGeoFeedService.shared.fetchLatestPhoto()
        } catch let appError as AppError {
            // Surface errors only when we have nothing cached to show
            if photoEntry == nil { error = appError }
        } catch {
            if photoEntry == nil { self.error = .networkUnavailable }
        }
    }
}
