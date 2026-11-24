import SwiftUI

@main
struct MyApp: App {
    @State private var store = StudyStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
