import Foundation
import Observation

@MainActor
@Observable
final class DebugModel {
    struct Row: Identifiable {
        var type: HealthDataType
        var result: Result<[SampleSnapshot], any Error>?

        var id: HealthDataType { type }
    }

    private(set) var rows = HealthDataType.allCases.map { Row(type: $0) }
    private(set) var window: DateInterval?
    private(set) var isLoadingCounts = false

    /// The day the night of sleep ended on. Defaults to today, i.e. last night.
    var sleepDay = Date.now
    private(set) var sleepNight: SleepNight?
    private(set) var sleepError: String?

    private let healthStore: HealthStore

    init(healthStore: HealthStore = .shared) {
        self.healthStore = healthStore
    }

    func reloadCounts() async {
        isLoadingCounts = true
        defer { isLoadingCounts = false }

        let now = Date.now
        let window = DateInterval(start: now.addingTimeInterval(-24 * 3600), end: now)
        let healthStore = healthStore
        let results = await withTaskGroup(of: (HealthDataType, Result<[SampleSnapshot], any Error>).self) { group in
            for type in HealthDataType.allCases {
                group.addTask {
                    do {
                        return (type, .success(try await healthStore.snapshots(of: type, in: window)))
                    } catch {
                        return (type, .failure(error))
                    }
                }
            }
            var results: [HealthDataType: Result<[SampleSnapshot], any Error>] = [:]
            for await (type, result) in group {
                results[type] = result
            }
            return results
        }
        self.window = window
        rows = HealthDataType.allCases.map { Row(type: $0, result: results[$0]) }
    }

    func reloadSleep() async {
        let interval = SleepNight.interval(endingOn: sleepDay, calendar: .current)
        do {
            let segments = try await healthStore.sleepSegments(in: interval)
            sleepNight = SleepNight(interval: interval, segments: segments)
            sleepError = nil
        } catch {
            sleepNight = nil
            sleepError = HealthStore.message(for: error)
        }
    }
}
