import SwiftUI

@main
struct WeatherGlassApp: App {
    var body: some Scene {
        WindowGroup {
            WeatherHomeView()
                .preferredColorScheme(.dark)
        }
    }
}
