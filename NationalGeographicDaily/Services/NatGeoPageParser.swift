import Foundation

// Parses the NatGeo Photo of the Day web page to extract a PhotoEntry.
// Strategy 1: JSON-LD <script type="application/ld+json"> blocks (structured data).
// Strategy 2: OpenGraph <meta property="og:..."> tags (universal fallback).
// All methods are nonisolated so this class can be called directly from actor
// contexts under SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor.
final class NatGeoPageParser {

    nonisolated func parse(html: String) -> PhotoEntry? {
        let base = parseJSONLD(html) ?? parseOpenGraph(html)
        guard let base else { return nil }

        // Meta descriptions are typically 1-2 sentences; try to get the full body.
        guard base.description.count < 200 else { return base }
        let body = extractBodyParagraphs(html)
        guard !body.isEmpty else { return base }

        return PhotoEntry(
            id: base.id,
            title: base.title,
            publicationDate: base.publicationDate,
            imageURL: base.imageURL,
            description: body
        )
    }

    // MARK: - JSON-LD

    nonisolated private func parseJSONLD(_ html: String) -> PhotoEntry? {
        let pattern = #"<script[^>]+type=["']application/ld\+json["'][^>]*>([\s\S]*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }

        let ns = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))

        for match in matches {
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: html) else { continue }
            if let entry = entryFromJSONString(String(html[range])) { return entry }
        }
        return nil
    }

    nonisolated private func entryFromJSONString(_ jsonString: String) -> PhotoEntry? {
        guard let data = jsonString.data(using: .utf8) else { return nil }

        let candidates: [[String: Any]]
        if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            candidates = arr
        } else if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            candidates = [obj]
        } else {
            return nil
        }

        for obj in candidates {
            if let entry = entryFromJSONObject(obj) { return entry }
            // Some pages wrap the article in a @graph array
            if let graph = obj["@graph"] as? [[String: Any]] {
                for node in graph {
                    if let entry = entryFromJSONObject(node) { return entry }
                }
            }
        }
        return nil
    }

    nonisolated private func entryFromJSONObject(_ obj: [String: Any]) -> PhotoEntry? {
        let type = obj["@type"] as? String ?? ""
        guard ["NewsArticle", "Article", "ImageObject", "Photograph", "WebPage"].contains(type) else { return nil }

        let title = (obj["headline"] as? String) ?? (obj["name"] as? String)
        let desc  = (obj["description"] as? String) ?? ""
        let id    = (obj["url"] as? String) ?? (obj["@id"] as? String) ?? UUID().uuidString

        var imageURL: URL?
        if let imgObj = obj["image"] as? [String: Any], let s = imgObj["url"] as? String {
            imageURL = URL(string: s)
        } else if let s = obj["image"] as? String {
            imageURL = URL(string: s)
        } else if let arr = obj["image"] as? [[String: Any]], let s = arr.first?["url"] as? String {
            imageURL = URL(string: s)
        }

        guard let title, let imageURL else { return nil }

        let dateStr = (obj["datePublished"] as? String) ?? (obj["dateCreated"] as? String)
        let date = dateStr.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()

        return PhotoEntry(id: id, title: title, publicationDate: date, imageURL: imageURL, description: desc)
    }

    // MARK: - OpenGraph fallback

    nonisolated private func parseOpenGraph(_ html: String) -> PhotoEntry? {
        let title      = metaContent("og:title",               in: html)
        let imageStr   = metaContent("og:image",               in: html)
        let desc       = metaContent("og:description",         in: html) ?? ""
        let dateStr    = metaContent("article:published_time", in: html)
        let urlStr     = metaContent("og:url",                 in: html)

        guard let title,
              let imageStr,
              let imageURL = URL(string: imageStr) else { return nil }

        let id   = urlStr ?? "natgeo-pod-\(Int(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970))"
        let date = dateStr.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()

        return PhotoEntry(
            id: id,
            title: decodeEntities(title),
            publicationDate: date,
            imageURL: imageURL,
            description: decodeEntities(desc)
        )
    }

    // MARK: - Helpers

    // Matches <meta property="PROP" content="VALUE"> in both attribute orderings.
    nonisolated private func metaContent(_ property: String, in html: String) -> String? {
        let esc = NSRegularExpression.escapedPattern(for: property)
        let patterns = [
            #"<meta[^>]+property=["']\#(esc)["'][^>]+content=["']([^"'<>]+)["']"#,
            #"<meta[^>]+content=["']([^"'<>]+)["'][^>]+property=["']\#(esc)["']"#,
            #"<meta[^>]+name=["']\#(esc)["'][^>]+content=["']([^"'<>]+)["']"#,
            #"<meta[^>]+content=["']([^"'<>]+)["'][^>]+name=["']\#(esc)["']"#,
        ]
        let ns = html as NSString
        for pattern in patterns {
            guard let rx = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
                  let m = rx.firstMatch(in: html, range: NSRange(location: 0, length: ns.length)),
                  m.numberOfRanges > 1,
                  let range = Range(m.range(at: 1), in: html) else { continue }
            return String(html[range])
        }
        return nil
    }

    // MARK: - Body paragraph extraction (Strategy 3)

    // Collects substantive <p> tags from the page body.
    // Short strings (<80 chars) are nav links / captions and are skipped.
    nonisolated private func extractBodyParagraphs(_ html: String) -> String {
        let pattern = #"<p(?:\s[^>]*)?>(.+?)</p>"#
        guard let rx = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return "" }

        let ns = html as NSString
        let matches = rx.matches(in: html, range: NSRange(location: 0, length: ns.length))

        var paragraphs: [String] = []
        for match in matches {
            guard match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: html) else { continue }

            let text = decodeEntities(
                stripHTML(String(html[r]))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            )
            guard text.count > 80 else { continue }
            paragraphs.append(text)
            if paragraphs.count == 6 { break }
        }
        return paragraphs.joined(separator: "\n\n")
    }

    nonisolated private func stripHTML(_ s: String) -> String {
        guard let rx = try? NSRegularExpression(pattern: #"<[^>]+>"#) else { return s }
        let result = rx.stringByReplacingMatches(
            in: s,
            range: NSRange(location: 0, length: (s as NSString).length),
            withTemplate: " "
        )
        return result.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
    }

    nonisolated private func decodeEntities(_ s: String) -> String {
        s
            .replacingOccurrences(of: "&amp;",  with: "&")
            .replacingOccurrences(of: "&lt;",   with: "<")
            .replacingOccurrences(of: "&gt;",   with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;",  with: "'")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
