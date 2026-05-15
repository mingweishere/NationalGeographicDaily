import SwiftData
import Foundation

@Model
final class FavoritePhoto {
    @Attribute(.unique) var id: String
    var title: String
    var publicationDate: Date
    var imageURLString: String
    var photoDescription: String
    var savedDate: Date

    init(from entry: PhotoEntry) {
        self.id = entry.id
        self.title = entry.title
        self.publicationDate = entry.publicationDate
        self.imageURLString = entry.imageURL.absoluteString
        self.photoDescription = entry.description
        self.savedDate = Date()
    }

    var imageURL: URL? { URL(string: imageURLString) }
}
