import Testing
import Foundation
@testable import NationalGeographicDaily

// MARK: - Mock RSS XML

private let validRSSXML = """
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
  <channel>
    <title>National Geographic Photo of the Day</title>
    <item>
      <title>Starlings in Flight</title>
      <guid isPermaLink="true">https://www.nationalgeographic.com/photography/photo-of-the-day/2026/05/starlings-flight</guid>
      <pubDate>Thu, 15 May 2026 00:00:00 +0000</pubDate>
      <description><![CDATA[<p>Thousands of starlings perform a <strong>murmuration</strong> over the Po Valley in Italy.</p>]]></description>
      <media:content url="https://i.natgeofe.com/n/abc123/starlings.jpg" medium="image" width="2048" height="1365"/>
    </item>
  </channel>
</rss>
"""

private let emptyFeedXML = """
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel></channel></rss>
"""

private let missingImageXML = """
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>No Image Photo</title>
      <guid>https://example.com/no-image</guid>
      <pubDate>Thu, 15 May 2026 00:00:00 +0000</pubDate>
      <description>A photo without a media:content element.</description>
    </item>
  </channel>
</rss>
"""

// MARK: - Tests

@Suite("RSSParser")
struct RSSParserTests {

    @Test("Parses a valid RSS item into a PhotoEntry")
    func parsesValidXML() throws {
        let data = try #require(validRSSXML.data(using: .utf8))
        let entry = RSSParser().parse(data: data)

        #expect(entry != nil)
        #expect(entry?.title == "Starlings in Flight")
        #expect(entry?.id == "https://www.nationalgeographic.com/photography/photo-of-the-day/2026/05/starlings-flight")
        #expect(entry?.imageURL.absoluteString == "https://i.natgeofe.com/n/abc123/starlings.jpg")
        #expect(entry?.publicationDate != nil)
    }

    @Test("Returns nil for an empty feed")
    func returnsNilForEmptyFeed() throws {
        let data = try #require(emptyFeedXML.data(using: .utf8))
        let entry = RSSParser().parse(data: data)
        #expect(entry == nil)
    }

    @Test("Returns nil when media:content URL is absent")
    func returnsNilWhenImageMissing() throws {
        let data = try #require(missingImageXML.data(using: .utf8))
        let entry = RSSParser().parse(data: data)
        #expect(entry == nil)
    }

    @Test("Strips HTML tags from description")
    func stripsHTMLFromDescription() throws {
        let data = try #require(validRSSXML.data(using: .utf8))
        let entry = try #require(RSSParser().parse(data: data))
        #expect(!entry.description.contains("<"))
        #expect(!entry.description.contains(">"))
        #expect(entry.description.contains("murmuration"))
    }

    @Test("Decodes HTML entities in description")
    func decodesHTMLEntities() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
          <channel><item>
            <title>Entity Test</title>
            <guid>https://example.com/entity-test</guid>
            <pubDate>Thu, 15 May 2026 00:00:00 +0000</pubDate>
            <description>Rock &amp; Roll</description>
            <media:content url="https://example.com/img.jpg" medium="image"/>
          </item></channel>
        </rss>
        """
        let data = try #require(xml.data(using: .utf8))
        let entry = try #require(RSSParser().parse(data: data))
        #expect(entry.description.contains("Rock & Roll"))
    }
}

@Suite("CacheService")
struct CacheServiceTests {

    private func makeSut() -> CacheService {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return CacheService(defaults: defaults)
    }

    private func makeSampleEntry() -> PhotoEntry {
        PhotoEntry(
            id: "test-id-001",
            title: "Test Photo",
            publicationDate: Date(timeIntervalSince1970: 1_747_353_600),
            imageURL: URL(string: "https://example.com/photo.jpg")!,
            description: "A beautiful test photo."
        )
    }

    @Test("Round-trips a PhotoEntry through UserDefaults")
    func cacheRoundTrip() async throws {
        let sut = makeSut()
        let original = makeSampleEntry()

        await sut.save(original)
        let loaded = await sut.load()

        let unwrapped = try #require(loaded)
        #expect(unwrapped.id == original.id)
        #expect(unwrapped.title == original.title)
        #expect(unwrapped.imageURL == original.imageURL)
        #expect(unwrapped.description == original.description)
        // Date comparison with ISO8601 loses sub-second precision — compare to nearest second
        #expect(abs(unwrapped.publicationDate.timeIntervalSince(original.publicationDate)) < 1)
    }

    @Test("Returns nil when nothing is cached")
    func returnsNilWhenEmpty() async {
        let sut = makeSut()
        let entry = await sut.load()
        #expect(entry == nil)
    }

    @Test("Clear removes cached entry")
    func clearRemovesCachedEntry() async throws {
        let sut = makeSut()
        await sut.save(makeSampleEntry())
        await sut.clear()
        let entry = await sut.load()
        #expect(entry == nil)
    }
}
