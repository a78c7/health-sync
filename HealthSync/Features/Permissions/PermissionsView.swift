import SwiftUI

/// Lets the user tick the data types to sync and ask HealthKit for read access to them.
struct PermissionsView: View {
    @Environment(TypeSelection.self) private var selection
    @State private var model = PermissionsModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statusRow
                    Button {
                        Task { await model.request(for: selection.selected) }
                    } label: {
                        Text("请求读取权限（已选 \(selection.selected.count) 种）")
                    }
                    .disabled(!canRequest)
                    if let message = model.errorMessage {
                        Text(message).foregroundStyle(.red)
                    }
                } footer: {
                    Text(
                        "「健康」不会告诉 App 你允许了哪些类型，所以这里看不出授权结果，去「调试」页看有没有数据。"
                            + "要改权限：设置 → 隐私与安全性 → 健康 → 健康同步。")
                }

                ForEach(HealthDataType.Category.allCases) { category in
                    Section(category.title) {
                        ForEach(category.types) { type in
                            Toggle(type.title, isOn: binding(for: type))
                        }
                    }
                }
            }
            .navigationTitle("数据类型")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("选择") {
                        Button("全选") { selection.selectAll() }
                        Button("全不选") { selection.deselectAll() }
                    }
                }
            }
            .task(id: selection.selected) {
                await model.refresh(for: selection.selected)
            }
        }
    }

    private var canRequest: Bool {
        !model.isRequesting && model.status != .unavailable && !selection.selected.isEmpty
    }

    @ViewBuilder
    private var statusRow: some View {
        switch model.status {
        case .checking:
            Label("正在检查…", systemImage: "hourglass")
        case .needsRequest:
            Label("有勾选的类型还没请求过权限，点下面的按钮会弹出「健康」授权页。", systemImage: "exclamationmark.circle")
                .foregroundStyle(.orange)
        case .alreadyRequested:
            Label("勾选的类型都已经请求过权限。", systemImage: "checkmark.circle")
                .foregroundStyle(.green)
        case .nothingSelected:
            Label("至少勾选一种数据类型。", systemImage: "info.circle")
        case .unavailable:
            Label("这台设备不支持「健康」数据。", systemImage: "xmark.circle")
                .foregroundStyle(.red)
        }
    }

    private func binding(for type: HealthDataType) -> Binding<Bool> {
        Binding(
            get: { selection.contains(type) },
            set: { selection.set(type, isSelected: $0) })
    }
}
