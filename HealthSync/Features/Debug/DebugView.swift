import SwiftUI

/// Shows what HealthKit returns: last night's sleep stages and per-type counts for the last 24 hours.
struct DebugView: View {
    @Environment(TypeSelection.self) private var selection
    @State private var model = DebugModel()

    var body: some View {
        NavigationStack {
            List {
                SleepNightSection(day: $model.sleepDay, night: model.sleepNight, errorMessage: model.sleepError)
                countsSection
            }
            .navigationTitle("调试")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("刷新", systemImage: "arrow.clockwise") {
                        Task { await reloadAll() }
                    }
                    .disabled(model.isLoadingCounts)
                }
            }
            .refreshable { await reloadAll() }
            .task { await model.reloadCounts() }
            .task(id: model.sleepDay) { await model.reloadSleep() }
        }
    }

    private var countsSection: some View {
        Section {
            ForEach(model.rows) { row in
                CountRow(row: row, isSelected: selection.contains(row.type))
            }
        } header: {
            Text("最近 24 小时条数")
        } footer: {
            if let window = model.window {
                Text("统计 \(DebugFormat.dateTime(window.start)) 到 \(DebugFormat.dateTime(window.end)) 之间开始的记录。")
            }
        }
    }

    private func reloadAll() async {
        async let counts: Void = model.reloadCounts()
        async let sleep: Void = model.reloadSleep()
        _ = await (counts, sleep)
    }
}

private struct CountRow: View {
    var row: DebugModel.Row
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(row.type.title)
                if !isSelected {
                    Text("未勾选").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if case .success(let snapshots) = row.result, snapshots.count == 1 {
                    Text("\(snapshots[0].count) 条").monospacedDigit()
                }
            }
            switch row.result {
            case nil:
                ProgressView()
            case .failure(let error):
                Text(HealthStore.message(for: error)).font(.caption).foregroundStyle(.red)
            case .success(let snapshots):
                ForEach(Array(snapshots.enumerated()), id: \.offset) { _, snapshot in
                    SnapshotLines(snapshot: snapshot)
                }
            }
        }
    }
}

private struct SnapshotLines: View {
    var snapshot: SampleSnapshot

    var body: some View {
        if let title = snapshot.title {
            Text("\(title) \(snapshot.count) 条").font(.subheadline).monospacedDigit()
        }
        if let latest = snapshot.latest {
            Text(DebugFormat.latest(latest)).font(.caption).foregroundStyle(.secondary)
        }
    }
}
