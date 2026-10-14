import Foundation

/// The app or device that wrote a sample, e.g. an Apple Watch or 小米运动健康.
struct SampleSource: Hashable, Sendable {
    var name: String
    var bundleIdentifier: String
}

/// One sleep analysis sample, reduced to what the debug page needs.
struct SleepSegment: Equatable, Sendable {
    var stage: SleepStage
    var start: Date
    var end: Date
    var source: SampleSource

    var duration: TimeInterval { end.timeIntervalSince(start) }
}

/// One night of sleep, kept apart per source. Sources overlap (a Xiaomi band and an Apple Watch both record
/// the same night), so adding them together would double count.
struct SleepNight: Sendable {
    struct SourceSummary: Identifiable, Sendable {
        var source: SampleSource
        /// Sorted by start time.
        var segments: [SleepSegment]

        var id: SampleSource { source }

        var start: Date? { segments.first?.start }
        var end: Date? { segments.map(\.end).max() }

        /// Time asleep in any stage, which is what the Health app reports as 睡眠时间.
        var asleep: TimeInterval {
            segments.filter(\.stage.isAsleep).reduce(0) { $0 + $1.duration }
        }

        func total(of stage: SleepStage) -> TimeInterval {
            segments.filter { $0.stage == stage }.reduce(0) { $0 + $1.duration }
        }
    }

    var interval: DateInterval
    /// Most time asleep first.
    var sources: [SourceSummary]

    init(interval: DateInterval, segments: [SleepSegment]) {
        self.interval = interval
        sources = Dictionary(grouping: segments, by: \.source)
            .map { source, segments in
                SourceSummary(source: source, segments: segments.sorted { $0.start < $1.start })
            }
            .sorted { lhs, rhs in
                lhs.asleep != rhs.asleep ? lhs.asleep > rhs.asleep : lhs.source.name < rhs.source.name
            }
    }

    /// The window for the night that ends on `day`: from 18:00 the day before to 18:00 on `day`, local time.
    static func interval(endingOn day: Date, calendar: Calendar) -> DateInterval {
        let startOfDay = calendar.startOfDay(for: day)
        let end =
            calendar.date(bySettingHour: 18, minute: 0, second: 0, of: startOfDay)
            ?? startOfDay.addingTimeInterval(18 * 3600)
        let start = calendar.date(byAdding: .day, value: -1, to: end) ?? end.addingTimeInterval(-24 * 3600)
        return DateInterval(start: start, end: end)
    }
}
