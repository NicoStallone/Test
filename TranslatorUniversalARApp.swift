import SwiftUI

/// Entry point for the TranslatorUniversalARApp.
///
/// You should set the `@main` attribute on exactly one struct in your
/// application.  This file creates a simple SwiftUI application that
/// displays either a voice translator or camera translator, and can
/// present an AR scene when requested.
@main
struct TranslatorUniversalARApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}