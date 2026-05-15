import CoreTransferable
import Foundation

struct ShareablePhoto: Transferable {
    let title: String
    let pageURL: URL

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.pageURL)
    }
}
