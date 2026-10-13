import SwiftUI

@main
struct NotchIslandApp: App {
    @StateObject private var viewModel = NotchViewModel()
    @StateObject private var pipManager = PiPIslandManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(pipManager)
                .preferredColorScheme(.dark)
                .statusBar(hidden: true)
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                    pipManager.bind(to: viewModel)
                }
        }
    }
}
