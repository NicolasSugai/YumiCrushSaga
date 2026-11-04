# Architecture

YumiCrushSaga keeps game rules in the local Swift package YumiEngine. That package depends only on Foundation. YumiApplication is a second package module for session orchestration and can be tested with an in-memory persistence adapter.

- **Domain:** GameBoard, GamePiece, Position, ingredient and special-piece types, level rules, match detection, move resolution and seeded random generation.
- **Application:** the YumiApplication module's GameSession owns a single play session and serializes player commands. A move is accepted and resolved synchronously, so two board resolutions cannot overlap.
- **Infrastructure:** versioned, atomic local file persistence and deterministic random generation for tests.
- **Presentation:** SwiftUI navigation, HUD, settings, screens and the Paraense palette.
- **GameRendering:** SpriteKit renders the 8×8 board, draws original vector ingredient pieces, animates updates, and maps taps/swipes into application commands. It does not implement match rules.
- **Tests:** SwiftPM/XCTest unit suites target YumiEngine; application flow tests target YumiApplication on Apple platforms.

## Special pieces

- A four-piece straight run creates a Correnteza that clears its row.
- A five-piece run creates an Uru-Uru that clears all pieces of its ingredient.
- A T/L junction creates an Explosão da Floresta that clears a 3×3 area.

Generated levels rotate between score, ingredient collection and special-piece creation objectives. A collection objective always includes its target ingredient in that level's generated piece palette. Collection targets grow gradually, with a ceiling informed by the number of moves and the size of the ingredient palette so later levels do not demand the same collection count from a smaller target share.

The engine resolves resulting matches through gravity and refill, with a 32-wave cascade ceiling. If the ceiling is reached while a match remains, the final board is reshuffled into a stable playable state. New boards are generated without existing matches and are reshuffled when they have no legal move. Randomness is seeded and injectable through the engine initializer.

## Persistence

Progress is encoded as a versioned JSON value and atomically replaced in the app's Application Support directory. Invalid/corrupt data is ignored during load and protected from overwrite. Save failures are surfaced in the app instead of being silently discarded. A successful level advances the unlocked level and records its best score.

## Mascot and artwork

YumiMascot is a replaceable SwiftUI vector cartoon informed by the private portrait at Design/References/WhatsApp Image 2026-11-02 at 12.31.04(1).jpeg and the separate concept PNG. The face uses a light skin palette, dark wavy hair, and separate expressions for play feedback. Both references are ignored by Git and neither is bundled. Eight food pieces have original SpriteKit vector drawings. Yumi's vector art remains a simplified interpretation; visual comparison in the iOS simulator and a production illustration pass are still needed.

## Validation boundary

On a compatible Swift toolchain, `swift test` validates the package targets available on that platform. On macOS with Xcode, `xcodebuild test -project YumiCrushSaga.xcodeproj -scheme YumiCrushSaga -destination 'platform=iOS Simulator,name=iPhone 11'` runs the app-hosted XCTest suite; the simulator runtime must be installed. Opening/building the app, checking VoiceOver and touch behavior, and measuring frame rate require macOS with Xcode and an iPhone-class simulator/device. These commands were not executable in the current Linux environment because Swift, Xcode, and iOS simulators are unavailable.
