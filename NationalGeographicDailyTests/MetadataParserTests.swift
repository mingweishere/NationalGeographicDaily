import Testing
import Foundation
@testable import NationalGeographicDaily

@Suite("MetadataParser")
struct MetadataParserTests {

    // MARK: - Photographer

    @Suite("extractPhotographer")
    struct PhotographerTests {

        @Test("extracts 'Photograph by' pattern")
        func photographByPattern() {
            let result = MetadataParser.extractPhotographer(
                from: "Photograph by Jane Smith near the Amazon River."
            )
            #expect(result == "Jane Smith near the Amazon River")
        }

        @Test("extracts 'Photo by' pattern")
        func photoByPattern() {
            let result = MetadataParser.extractPhotographer(
                from: "Photo by John Doe, National Geographic."
            )
            #expect(result == "John Doe")
        }

        @Test("returns dash when no photographer found")
        func noMatch() {
            let result = MetadataParser.extractPhotographer(
                from: "A beautiful landscape with mountains and rivers."
            )
            #expect(result == "—")
        }
    }

    // MARK: - Location

    @Suite("extractLocation")
    struct LocationTests {

        @Test("extracts 'in' location pattern")
        func inPattern() {
            let result = MetadataParser.extractLocation(
                from: "Dragonflies spotted in Puerto Rico near the coast."
            )
            #expect(result == "Puerto Rico")
        }

        @Test("extracts 'near' location pattern")
        func nearPattern() {
            let result = MetadataParser.extractLocation(
                from: "This photo was taken near Mount Everest."
            )
            #expect(result == "Mount Everest")
        }

        @Test("returns dash when no location found")
        func noMatch() {
            let result = MetadataParser.extractLocation(
                from: "A stunning photograph of a red dragonfly at dusk."
            )
            #expect(result == "—")
        }
    }

    // MARK: - Camera

    @Suite("extractCamera")
    struct CameraTests {

        @Test("extracts Canon EOS camera")
        func canonCamera() {
            let result = MetadataParser.extractCamera(
                from: "The image was captured using a Canon EOS R5 in the field."
            )
            #expect(result.contains("Canon"))
        }

        @Test("extracts 'shot with' camera pattern")
        func shotWithPattern() {
            let result = MetadataParser.extractCamera(
                from: "Shot with a Nikon Z9 mirrorless camera in low light."
            )
            #expect(result.contains("Nikon"))
        }

        @Test("returns dash when no camera found")
        func noMatch() {
            let result = MetadataParser.extractCamera(
                from: "A wildlife photograph taken at dawn in the savanna."
            )
            #expect(result == "—")
        }
    }
}
