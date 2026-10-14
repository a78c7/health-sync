import HealthKit

/// A sleep analysis value. Raw values mirror `HKCategoryValueSleepAnalysis`.
enum SleepStage: Int, CaseIterable, Sendable {
    case inBed = 0
    case asleepUnspecified = 1
    case awake = 2
    case asleepCore = 3
    case asleepDeep = 4
    case asleepREM = 5

    /// The four stages the Health app charts, in its order, then the two it lists separately.
    static let displayOrder: [SleepStage] = [.awake, .asleepREM, .asleepCore, .asleepDeep, .asleepUnspecified, .inBed]

    init?(_ value: HKCategoryValueSleepAnalysis) {
        self.init(rawValue: value.rawValue)
    }

    /// Stable key; from P2 on it is the webhook `value` of a sleep sample.
    var key: String {
        switch self {
        case .inBed: "in_bed"
        case .asleepUnspecified: "asleep_unspecified"
        case .awake: "awake"
        case .asleepCore: "asleep_core"
        case .asleepDeep: "asleep_deep"
        case .asleepREM: "asleep_rem"
        }
    }

    /// The zh-Hans Health app's name for the stage.
    var title: String {
        switch self {
        case .inBed: "卧床"
        case .asleepUnspecified: "睡眠（未分期）"
        case .awake: "清醒"
        case .asleepCore: "核心"
        case .asleepDeep: "深度"
        case .asleepREM: "快速动眼"
        }
    }

    /// Whether the stage counts towards 睡眠时间. In-bed and awake time don't.
    var isAsleep: Bool {
        switch self {
        case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM: true
        case .inBed, .awake: false
        }
    }
}
