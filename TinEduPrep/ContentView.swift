import SwiftUI

struct ContentView: View {
    @Environment(StudyStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Trang chủ", systemImage: "house.fill")
                }

            StudyLibraryView()
                .tabItem {
                    Label("Ôn tập", systemImage: "book.fill")
                }

            MockExamView()
                .tabItem {
                    Label("Thi thử", systemImage: "timer")
                }

            ProgressDashboardView()
                .tabItem {
                    Label("Tiến độ", systemImage: "chart.bar.fill")
                }

            SavedContentView()
                .tabItem {
                    Label("Đã lưu", systemImage: "bookmark.fill")
                }
        }
        .tint(.indigo)
        .onAppear {
            store.refreshCatalog()
        }
        .task {
            await store.updateContentIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await store.updateContentIfNeeded()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(StudyStore())
}
