# NatGeo Daily

An iOS app that delivers the National Geographic Photo of the Day with an immersive viewing experience, AI-powered story explanations, and a personal favorites collection.

## Features

- **Photo of the Day** — fetches the latest NatGeo photo via RSS feed with automatic offline caching
- **Immersive Viewer** — full-screen photo viewer with pinch-to-zoom (1×–5×), double-tap zoom, swipe-to-dismiss, and a metadata panel showing photographer, location, and camera info
- **AI Story Explainer** — powered by Gemini 2.5 Flash; explains the story behind each photo at Simple, Standard, or Expert reading levels
- **Favorites** — save photos to a local SwiftData collection; browse in a 2-column grid with quick access to the immersive viewer
- **Daily Notifications** — optional local notification at a user-configured time each day
- **Background Refresh** — `BGAppRefreshTask` keeps the cached photo up to date

## Requirements

- iOS 17+
- Xcode 16+
- A [Gemini API key](https://aistudio.google.com/app/apikey) for the AI explainer feature

## Setup

1. Clone the repo and open `NationalGeographicDaily.xcodeproj`
2. Create `NationalGeographicDaily/Resources/Config.plist` (this file is gitignored):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GEMINI_API_KEY</key>
    <string>YOUR_KEY_HERE</string>
</dict>
</plist>
```

3. Build and run on a simulator or device (⌘R)

The AI explainer gracefully shows an error if the key is missing or empty — the rest of the app works without it.

## Architecture

```
NationalGeographicDaily/
├── Models/
│   ├── PhotoEntry.swift          # Core data struct (Identifiable, Codable, Sendable)
│   ├── FavoritePhoto.swift       # SwiftData @Model for persisted favorites
│   ├── AppError.swift            # Typed error enum (LocalizedError)
│   ├── ReadingLevel.swift        # Enum driving Gemini prompt style
│   └── GeminiResponse.swift      # Decodable response models for Gemini API
├── Services/
│   ├── NatGeoFeedService.swift   # Fetches RSS, falls back to cached entry
│   ├── RSSParser.swift           # XMLParser-based RSS → PhotoEntry
│   ├── NatGeoPageParser.swift    # JSON-LD / OpenGraph / body-paragraph scraper
│   ├── CacheService.swift        # UserDefaults-backed PhotoEntry cache
│   ├── StoryExplainerService.swift # Gemini 2.5 Flash REST client (actor)
│   ├── MetadataParser.swift      # Regex extraction of photographer/location/camera
│   ├── NotificationService.swift # UNUserNotificationCenter wrapper (actor)
│   └── BackgroundRefreshService.swift # BGAppRefreshTask registration & scheduling
├── ViewModels/
│   └── HomeViewModel.swift       # @Observable; drives HomeView state
└── Views/
    ├── HomeView.swift            # Today tab — hero image + story card
    ├── ImmersiveViewerView.swift # Full-screen photo viewer with gestures
    ├── StoryExplainerView.swift  # Gemini AI story sheet (reading level picker)
    ├── FavoritesView.swift       # Saved photos grid
    ├── PhotoDetailView.swift     # Full detail view for a saved favorite
    ├── SettingsView.swift        # Notification toggle + time picker
    └── ContentView.swift         # Root TabView
```

**Patterns used:**
- `@Observable` view models (iOS 17 macro)
- `actor` for all network/IO services (`Sendable`-safe)
- SwiftData (`@Model`, `@Query`) for favorites persistence
- `async/await` throughout — no Combine, no callbacks
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` project setting

## Tests

```
NationalGeographicDailyTests/
├── FeedServiceTests.swift    # RSSParser + CacheService (round-trip, edge cases)
└── MetadataParserTests.swift # Photographer / location / camera extraction
```

Run with ⌘U in Xcode. Uses the Swift Testing framework (`@Suite`, `@Test`, `#expect`).

## Dependencies

| Package | Use |
|---|---|
| [Kingfisher](https://github.com/onevcat/Kingfisher) | Async image loading and disk caching |

Added via Swift Package Manager — no other external dependencies.

## Privacy

- No user data is sent to any server except the photo story text sent to the Gemini API when "Tell me more" is tapped
- The Gemini API key is stored in a local `Config.plist` that is gitignored and never leaves the device
- Favorites are stored on-device using SwiftData
