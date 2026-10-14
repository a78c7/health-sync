import SwiftUI

/// One night of sleep per source, laid out so it can be checked against the Health app.
struct SleepNightSection: View {
    @Binding var day: Date
    var night: SleepNight?
    var errorMessage: String?

    var body: some View {
        Section {
            DatePicker("醒来那天", selection: $day, in: ...Date.now, displayedComponents: .date)
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            } else if let night {
                if night.sources.isEmpty {
                    Text("这一晚没有睡眠数据。如果「健康」里有，多半是没给读取权限。")
                        .foregroundStyle(.secondary)
                }
                ForEach(night.sources) { summary in
                    SourceRows(summary: summary)
                }
            }
        } header: {
            Text("睡眠分期")
        } footer: {
            if let night {
                let start = DebugFormat.dateTime(night.interval.start)
                let end = DebugFormat.dateTime(night.interval.end)
                Text("统计 \(start) 到 \(end) 之间开始的睡眠记录。每个来源分开算，和「健康」App 一样不会相加。")
            }
        }
    }
}

private struct SourceRows: View {
    var summary: SleepNight.SourceSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(summary.source.name).font(.headline)
            if let start = summary.start, let end = summary.end {
                Text("\(DebugFormat.time(start)) – \(DebugFormat.time(end))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        LabeledContent("睡眠时间", value: DebugFormat.duration(summary.asleep))
            .bold()
        ForEach(SleepStage.displayOrder, id: \.self) { stage in
            let total = summary.total(of: stage)
            if total > 0 {
                LabeledContent(stage.title, value: DebugFormat.duration(total))
            }
        }
        DisclosureGroup("全部 \(summary.segments.count) 段记录") {
            ForEach(Array(summary.segments.enumerated()), id: \.offset) { _, segment in
                LabeledContent(
                    "\(DebugFormat.time(segment.start)) – \(DebugFormat.time(segment.end))",
                    value: segment.stage.title)
            }
        }
        .font(.subheadline)
    }
}
