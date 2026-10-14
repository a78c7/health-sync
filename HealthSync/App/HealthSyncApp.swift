import SwiftUI

@main
struct HealthSyncApp: App {
    @State private var selection = TypeSelection(defaults: AppGroup.defaults)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(selection)
        }
    }
}
