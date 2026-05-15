import Foundation

struct MetadataParser {

    static func extractPhotographer(from description: String) -> String {
        let patterns = [
            #"[Pp]hotograph(?:s|ed)? by ([A-Z][^,.\n]{2,40})"#,
            #"[Pp]hoto by ([A-Z][^,.\n]{2,40})"#,
            #"©\s?([A-Z][^,.\n]{2,40})"#,
            #"[Cc]redit:?\s+([A-Z][^,.\n]{2,40})"#,
        ]
        return firstCapture(in: description, patterns: patterns) ?? "—"
    }

    static func extractLocation(from description: String) -> String {
        let patterns = [
            #"in ([A-Z][a-z]+(?: [A-Z][a-z]+)*)(?:,\s[A-Z][a-z]+(?: [A-Z][a-z]+)*)?"#,
            #"near ([A-Z][a-z]+(?: [A-Z][a-z]+)*)"#,
            #"off (?:the coast of )?([A-Z][a-z]+(?: [A-Z][a-z]+)*)"#,
        ]
        return firstCapture(in: description, patterns: patterns) ?? "—"
    }

    static func extractCamera(from description: String) -> String {
        let patterns = [
            #"(Canon EOS[^,.\n]{0,20}|Nikon [A-Z][^,.\n]{0,20}|Sony [Aa][^,.\n]{0,20}|Fujifilm? [A-Z][^,.\n]{0,20}|Leica [A-Z][^,.\n]{0,20}|Hasselblad [A-Z][^,.\n]{0,20})"#,
            #"[Cc]amera:?\s+([A-Za-z0-9 \-]{4,30})"#,
            #"[Ss]hot (?:with|on) (?:a )?([A-Za-z0-9 \-]{4,30})"#,
        ]
        return firstCapture(in: description, patterns: patterns) ?? "—"
    }

    private static func firstCapture(in text: String, patterns: [String]) -> String? {
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            guard let match = regex.firstMatch(in: text, range: range),
                  match.numberOfRanges > 1,
                  let captureRange = Range(match.range(at: 1), in: text) else { continue }
            let result = String(text[captureRange]).trimmingCharacters(in: .whitespaces)
            if !result.isEmpty { return result }
        }
        return nil
    }
}
