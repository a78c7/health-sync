import HealthKit

/// The most recent sample of a type, already converted out of HealthKit's classes.
enum LatestSample: Sendable {
    case quantity(QuantityMetric, value: Double, date: Date)
    case sleep(SleepStage, date: Date)
    case workout(activityType: UInt, duration: TimeInterval, date: Date)
}

/// Count and latest sample for one HealthKit type within a time window.
struct SampleSnapshot: Sendable {
    /// Set when a data type has several parts, e.g. 收缩压 and 舒张压 for blood pressure.
    var title: String?
    var count: Int
    var latest: LatestSample?
}

/// HealthKit access: authorization and the read-only queries behind the debug page.
///
/// Inputs and outputs are plain values so callers on the main actor never hold HealthKit objects,
/// which aren't Sendable.
final class HealthStore: Sendable {
    static let shared = HealthStore()

    private let store = HKHealthStore()

    static var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    static func readTypes(for types: Set<HealthDataType>) -> Set<HKObjectType> {
        Set(types.flatMap(\.sampleTypes).map { $0 as HKObjectType })
    }

    // MARK: - Authorization

    /// Whether requesting `types` would show the Health permission sheet.
    func requestStatus(for types: Set<HealthDataType>) async throws -> HKAuthorizationRequestStatus {
        try await store.statusForAuthorizationRequest(toShare: [], read: Self.readTypes(for: types))
    }

    /// Shows the Health permission sheet for any of `types` the user hasn't decided on yet.
    ///
    /// Returning normally does not mean access was granted: HealthKit never tells an app whether
    /// the user allowed reading. Denied types simply look empty.
    func requestReadAuthorization(for types: Set<HealthDataType>) async throws {
        try await store.requestAuthorization(toShare: [], read: Self.readTypes(for: types))
    }

    // MARK: - Queries

    /// Count and latest sample for every HealthKit type behind `type`, for samples starting inside `interval`.
    func snapshots(of type: HealthDataType, in interval: DateInterval) async throws -> [SampleSnapshot] {
        let predicate = Self.predicate(startingIn: interval)
        switch type {
        case .sleep:
            let segments = try await sleepSegments(in: interval)
            let latest = segments.max { $0.end < $1.end }.map { LatestSample.sleep($0.stage, date: $0.end) }
            return [SampleSnapshot(count: segments.count, latest: latest)]
        case .workout:
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.workout(predicate)],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)])
            let workouts = try await descriptor.result(for: store)
            let latest = workouts.first.map {
                LatestSample.workout(
                    activityType: $0.workoutActivityType.rawValue, duration: $0.duration, date: $0.endDate)
            }
            return [SampleSnapshot(count: workouts.count, latest: latest)]
        default:
            var snapshots: [SampleSnapshot] = []
            for metric in type.metrics {
                let descriptor = HKSampleQueryDescriptor(
                    predicates: [.quantitySample(type: metric.quantityType, predicate: predicate)],
                    sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)])
                let samples = try await descriptor.result(for: store)
                let latest = samples.first.map {
                    LatestSample.quantity(metric, value: $0.quantity.doubleValue(for: metric.unit), date: $0.endDate)
                }
                snapshots.append(SampleSnapshot(title: metric.componentTitle, count: samples.count, latest: latest))
            }
            return snapshots
        }
    }

    /// Sleep analysis samples starting inside `interval`, oldest first.
    func sleepSegments(in interval: DateInterval) async throws -> [SleepSegment] {
        let descriptor = HKSampleQueryDescriptor(
            predicates: [
                .categorySample(type: HKCategoryType(.sleepAnalysis), predicate: Self.predicate(startingIn: interval))
            ],
            sortDescriptors: [SortDescriptor(\.startDate)])
        return try await descriptor.result(for: store).compactMap { sample in
            guard let stage = SleepStage(rawValue: sample.value) else { return nil }
            let source = sample.sourceRevision.source
            return SleepSegment(
                stage: stage, start: sample.startDate, end: sample.endDate,
                source: SampleSource(name: source.name, bundleIdentifier: source.bundleIdentifier))
        }
    }

    private static func predicate(startingIn interval: DateInterval) -> NSPredicate {
        HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: .strictStartDate)
    }
}

extension HealthStore {
    /// A short Chinese explanation for errors the user can do something about.
    static func message(for error: any Error) -> String {
        if let error = error as? HKError {
            switch error.code {
            case .errorAuthorizationNotDetermined: return "还没请求过这个类型的读取权限"
            case .errorDatabaseInaccessible: return "手机锁着时读不到健康数据，解锁后再刷新"
            case .errorHealthDataUnavailable: return "这台设备不支持「健康」数据"
            default: break
            }
        }
        return error.localizedDescription
    }
}
