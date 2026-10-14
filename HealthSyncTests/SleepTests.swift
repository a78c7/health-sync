import Foundation
import HealthKit
import Testing

@testable import HealthSync

struct SleepStageTests {
    @Test func mirrorsHealthKitValues() {
        #expect(SleepStage(HKCategoryValueSleepAnalysis.inBed) == .inBed)
        #expect(SleepStage(HKCategoryValueSleepAnalysis.asleepUnspecified) == .asleepUnspecified)
        #expect(SleepStage(HKCategoryValueSleepAnalysis.awake) == .awake)
        #expect(SleepStage(HKCategoryValueSleepAnalysis.asleepCore) == .asleepCore)
        #expect(SleepStage(HKCategoryValueSleepAnalysis.asleepDeep) == .asleepDeep)
        #expect(SleepStage(HKCategoryValueSleepAnalysis.asleepREM) == .asleepREM)
    }

    @Test func unknownValuesAreDropped() {
        #expect(SleepStage(rawValue: 99) == nil)
    }

    @Test func keysMatchThePlannedWebhookFormat() {
        #expect(SleepStage.asleepDeep.key == "asleep_deep")
        #expect(Set(SleepStage.allCases.map(\.key)).count == SleepStage.allCases.count)
    }

    @Test func onlyAsleepStagesCountAsSleep() {
        #expect(SleepStage.allCases.filter(\.isAsleep) == [.asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM])
    }

    @Test func displayOrderListsEveryStageOnce() {
        #expect(SleepStage.displayOrder.count == SleepStage.allCases.count)
        #expect(Set(SleepStage.displayOrder) == Set(SleepStage.allCases))
    }
}

struct SleepNightTests {
    private let watch = SampleSource(name: "Apple Watch", bundleIdentifier: "com.apple.health.watch")
    private let band = SampleSource(name: "小米运动健康", bundleIdentifier: "com.xiaomi.mihome")
    private let phone = SampleSource(name: "iPhone", bundleIdentifier: "com.apple.health.phone")

    @Test func nightRunsFromSixPMToSixPM() throws {
        let calendar = try Self.calendar("Asia/Shanghai")
        let interval = SleepNight.interval(endingOn: try Self.date("2026-10-15 07:30", calendar), calendar: calendar)
        #expect(interval.start == (try Self.date("2026-10-14 18:00", calendar)))
        #expect(interval.end == (try Self.date("2026-10-15 18:00", calendar)))
    }

    @Test func nightKeepsWallClockHoursAcrossDaylightSavingChange() throws {
        // Clocks go back on 2026-11-01 in New York, so that night is 25 hours long.
        let calendar = try Self.calendar("America/New_York")
        let interval = SleepNight.interval(endingOn: try Self.date("2026-11-01 09:00", calendar), calendar: calendar)
        #expect(calendar.component(.hour, from: interval.start) == 18)
        #expect(calendar.component(.hour, from: interval.end) == 18)
        #expect(interval.duration == 25 * 3600)
    }

    @Test func totalsArePerSourceAndNeverAddedTogether() throws {
        let calendar = try Self.calendar("Asia/Shanghai")
        func make(_ stage: SleepStage, _ start: String, _ end: String, _ source: SampleSource) throws -> SleepSegment {
            SleepSegment(
                stage: stage, start: try Self.date(start, calendar), end: try Self.date(end, calendar), source: source)
        }
        let segments = [
            try make(.asleepDeep, "2026-10-15 01:00", "2026-10-15 01:30", watch),
            try make(.asleepCore, "2026-10-14 23:00", "2026-10-15 01:00", watch),
            try make(.asleepREM, "2026-10-15 01:30", "2026-10-15 02:00", watch),
            try make(.awake, "2026-10-15 02:00", "2026-10-15 02:05", watch),
            try make(.asleepUnspecified, "2026-10-14 23:30", "2026-10-15 06:30", band),
            try make(.inBed, "2026-10-14 22:50", "2026-10-15 07:00", phone),
        ]
        let interval = SleepNight.interval(endingOn: try Self.date("2026-10-15 08:00", calendar), calendar: calendar)
        let night = SleepNight(interval: interval, segments: segments)

        #expect(night.sources.map(\.source) == [band, watch, phone])

        let watchNight = try #require(night.sources.first { $0.source == watch })
        #expect(watchNight.asleep == 3 * 3600)
        #expect(watchNight.total(of: .asleepCore) == 2 * 3600)
        #expect(watchNight.total(of: .asleepDeep) == 30 * 60)
        #expect(watchNight.total(of: .asleepREM) == 30 * 60)
        #expect(watchNight.total(of: .awake) == 5 * 60)
        #expect(watchNight.segments.map(\.stage) == [.asleepCore, .asleepDeep, .asleepREM, .awake])
        #expect(watchNight.start == (try Self.date("2026-10-14 23:00", calendar)))
        #expect(watchNight.end == (try Self.date("2026-10-15 02:05", calendar)))

        let bandNight = try #require(night.sources.first { $0.source == band })
        #expect(bandNight.asleep == 7 * 3600)

        let phoneNight = try #require(night.sources.first { $0.source == phone })
        #expect(phoneNight.asleep == 0)
        #expect(phoneNight.total(of: .inBed) == 8 * 3600 + 10 * 60)
    }

    @Test func emptyNightHasNoSources() {
        let night = SleepNight(interval: DateInterval(start: .now, duration: 3600), segments: [])
        #expect(night.sources.isEmpty)
    }

    private static func calendar(_ identifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: identifier))
        return calendar
    }

    private static func date(_ text: String, _ calendar: Calendar) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return try #require(formatter.date(from: text))
    }
}
