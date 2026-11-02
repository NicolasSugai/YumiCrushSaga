# Running locally

1. Open YumiCrushSaga.xcodeproj on a Mac with Xcode.
2. Select the YumiCrushSaga scheme and an iPhone 11 or newer simulator.
3. Build and run. The app has no network or backend dependency.
4. Run the YumiCrushSagaTests scheme tests from Xcode.

The game engine and session orchestration are local Swift package modules. From macOS with Swift 5.9 or later, run swift test from the repository root to exercise the engine and application flow tests. Linux runs the engine-only suite because Combine is unavailable there.

The current Linux environment does not include Swift or Xcode, so neither the package tests nor an iOS build have been executed here.
