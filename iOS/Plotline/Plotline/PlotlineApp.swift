import SwiftUI
import SwiftData

@main
struct PlotlineApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([WatchedMarker.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Splash anim: line draw + node pops + bullseye + word fade ≈ 2.6s; dwell briefly after.
            try? await Task.sleep(for: .seconds(3.0))
            withAnimation(.easeInOut(duration: 0.45)) { showSplash = false }
        }
    }
}
