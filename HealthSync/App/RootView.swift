import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            PermissionsView()
                .tabItem { Label("数据类型", systemImage: "checklist") }
            DebugView()
                .tabItem { Label("调试", systemImage: "ladybug") }
        }
    }
}

#Preview {
    RootView()
        .environment(TypeSelection(defaults: .standard))
}
