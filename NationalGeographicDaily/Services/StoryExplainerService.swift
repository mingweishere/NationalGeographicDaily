import Foundation

// Add your Gemini API key to Config.plist — never commit this file
actor StoryExplainerService {
    static let shared = StoryExplainerService()

    func explain(story: String, title: String, level: ReadingLevel) async throws -> String {
        let apiKey = try GeminiConfig.apiKey()

        guard let url = URL(string:
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        ) else {
            throw AppError.aiExplainerFailed("Invalid API endpoint URL")
        }

        let prompt = """
        Here is the National Geographic photo of the day background story:

        Title: \(title)

        Story: \(story)

        \(level.promptInstruction)
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": prompt]]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 1024,
                "temperature": 0.7
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.aiExplainerFailed("Invalid server response")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AppError.aiExplainerFailed("API error (HTTP \(httpResponse.statusCode))")
        }

        do {
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            guard let text = geminiResponse.candidates.first?.content.parts.first?.text,
                  !text.isEmpty else {
                throw AppError.aiExplainerFailed("Unexpected response from Gemini")
            }
            return text
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.aiExplainerFailed("Unexpected response from Gemini")
        }
    }
}

// MARK: - Config reader

struct GeminiConfig {
    static func apiKey() throws -> String {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url),
              let key = dict["GEMINI_API_KEY"] as? String,
              !key.isEmpty else {
            throw AppError.aiExplainerFailed(
                "Missing API key — add GEMINI_API_KEY to Config.plist"
            )
        }
        return key
    }
}
