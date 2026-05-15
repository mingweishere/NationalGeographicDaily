import Foundation

// RSSParser wraps Foundation's synchronous XMLParser. All stored state is
// nonisolated(unsafe) and all methods are nonisolated so the parser can be
// instantiated and called directly from any actor context. The synchronous
// nature of XMLParser.parse() guarantees single-threaded access to the state.
final class RSSParser: NSObject {

    nonisolated(unsafe) private var entries: [PhotoEntry] = []
    nonisolated(unsafe) private var insideItem = false
    nonisolated(unsafe) private var currentTitle = ""
    nonisolated(unsafe) private var currentDescription = ""
    nonisolated(unsafe) private var currentGUID = ""
    nonisolated(unsafe) private var currentPubDate = ""
    nonisolated(unsafe) private var currentImageURL: URL?
    nonisolated(unsafe) private var buffer = ""

    nonisolated override init() {
        super.init()
    }

    nonisolated func parse(data: Data) -> PhotoEntry? {
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.shouldProcessNamespaces = false
        xmlParser.parse()
        return entries.first
    }

    nonisolated private func buildEntry() -> PhotoEntry? {
        guard !currentTitle.isEmpty,
              !currentGUID.isEmpty,
              let imageURL = currentImageURL,
              let date = parseRFC2822Date(currentPubDate) else { return nil }

        return PhotoEntry(
            id: currentGUID,
            title: currentTitle,
            publicationDate: date,
            imageURL: imageURL,
            description: stripHTML(currentDescription)
        )
    }

    nonisolated private func parseRFC2822Date(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if let date = formatter.date(from: string) { return date }
        formatter.dateFormat = "dd MMM yyyy HH:mm:ss Z"
        return formatter.date(from: string)
    }

    nonisolated private func stripHTML(_ html: String) -> String {
        var result = ""
        var inTag = false
        for char in html {
            if char == "<" { inTag = true }
            else if char == ">" { inTag = false }
            else if !inTag { result.append(char) }
        }
        return result
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension RSSParser: XMLParserDelegate {

    nonisolated func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        buffer = ""

        if elementName == "item" {
            insideItem = true
            currentTitle = ""
            currentDescription = ""
            currentGUID = ""
            currentPubDate = ""
            currentImageURL = nil
        } else if insideItem && (elementName == "media:content" || elementName == "enclosure") {
            if let urlString = attributeDict["url"], let url = URL(string: urlString) {
                currentImageURL = currentImageURL ?? url
            }
        }
    }

    nonisolated func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideItem {
            buffer += string
        }
    }

    nonisolated func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if insideItem, let string = String(data: CDATABlock, encoding: .utf8) {
            buffer += string
        }
    }

    nonisolated func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard insideItem else { return }

        let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "title":
            if currentTitle.isEmpty { currentTitle = trimmed }
        case "description":
            currentDescription = trimmed
        case "guid":
            currentGUID = trimmed
        case "pubDate":
            currentPubDate = trimmed
        case "item":
            if let entry = buildEntry() { entries.append(entry) }
            insideItem = false
        default:
            break
        }

        buffer = ""
    }
}
