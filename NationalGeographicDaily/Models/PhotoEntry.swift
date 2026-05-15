import Foundation

struct PhotoEntry: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let publicationDate: Date
    let imageURL: URL
    let description: String
}
