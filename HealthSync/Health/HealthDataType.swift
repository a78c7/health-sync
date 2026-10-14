import HealthKit

/// One of the 20 data types the user can choose to sync in v1.
///
/// The raw value is the stable key used for storage.
enum HealthDataType: String, CaseIterable, Identifiable, Sendable {
    case sleep
    case heartRate = "heart_rate"
    case restingHeartRate = "resting_heart_rate"
    case walkingHeartRateAverage = "walking_heart_rate_average"
    case heartRateVariabilitySDNN = "heart_rate_variability_sdnn"
    case bloodPressure = "blood_pressure"
    case vo2Max = "vo2_max"
    case oxygenSaturation = "oxygen_saturation"
    case respiratoryRate = "respiratory_rate"
    case stepCount = "step_count"
    case distanceWalkingRunning = "distance_walking_running"
    case flightsClimbed = "flights_climbed"
    case activeEnergyBurned = "active_energy_burned"
    case basalEnergyBurned = "basal_energy_burned"
    case exerciseTime = "exercise_time"
    case standTime = "stand_time"
    case workout
    case bodyMass = "body_mass"
    case bodyFatPercentage = "body_fat_percentage"
    case sleepingWristTemperature = "sleeping_wrist_temperature"

    enum Category: CaseIterable, Identifiable, Sendable {
        case sleep
        case heart
        case respiratory
        case activity
        case body

        var id: Self { self }

        var title: String {
            switch self {
            case .sleep: "睡眠"
            case .heart: "心脏"
            case .respiratory: "呼吸"
            case .activity: "健身记录"
            case .body: "身体测量"
            }
        }

        var types: [HealthDataType] { HealthDataType.allCases.filter { $0.category == self } }
    }

    var id: Self { self }

    /// Names match the zh-Hans Health permission sheet, so users can match them up.
    var title: String {
        switch self {
        case .sleep: "睡眠（含分期）"
        case .heartRate: "心率"
        case .restingHeartRate: "静息心率"
        case .walkingHeartRateAverage: "步行平均心率"
        case .heartRateVariabilitySDNN: "心率变异性（SDNN）"
        case .bloodPressure: "血压"
        case .vo2Max: "有氧适能（最大摄氧量）"
        case .oxygenSaturation: "血氧"
        case .respiratoryRate: "呼吸频率"
        case .stepCount: "步数"
        case .distanceWalkingRunning: "步行+跑步距离"
        case .flightsClimbed: "已爬楼层"
        case .activeEnergyBurned: "活动能量"
        case .basalEnergyBurned: "静息能量"
        case .exerciseTime: "锻炼分钟数"
        case .standTime: "站立分钟数"
        case .workout: "体能训练（摘要，不含轨迹）"
        case .bodyMass: "体重"
        case .bodyFatPercentage: "体脂率"
        case .sleepingWristTemperature: "手腕温度（睡眠时）"
        }
    }

    var category: Category {
        switch self {
        case .sleep:
            .sleep
        case .heartRate, .restingHeartRate, .walkingHeartRateAverage, .heartRateVariabilitySDNN, .bloodPressure,
            .vo2Max:
            .heart
        case .oxygenSaturation, .respiratoryRate:
            .respiratory
        case .stepCount, .distanceWalkingRunning, .flightsClimbed, .activeEnergyBurned, .basalEnergyBurned,
            .exerciseTime, .standTime, .workout:
            .activity
        case .bodyMass, .bodyFatPercentage, .sleepingWristTemperature:
            .body
        }
    }

    /// The quantity types behind this data type. Blood pressure has two; sleep and workouts have none.
    var metrics: [QuantityMetric] {
        switch self {
        case .sleep, .workout: []
        case .heartRate: [.heartRate]
        case .restingHeartRate: [.restingHeartRate]
        case .walkingHeartRateAverage: [.walkingHeartRateAverage]
        case .heartRateVariabilitySDNN: [.heartRateVariabilitySDNN]
        case .bloodPressure: [.bloodPressureSystolic, .bloodPressureDiastolic]
        case .vo2Max: [.vo2Max]
        case .oxygenSaturation: [.oxygenSaturation]
        case .respiratoryRate: [.respiratoryRate]
        case .stepCount: [.stepCount]
        case .distanceWalkingRunning: [.distanceWalkingRunning]
        case .flightsClimbed: [.flightsClimbed]
        case .activeEnergyBurned: [.activeEnergyBurned]
        case .basalEnergyBurned: [.basalEnergyBurned]
        case .exerciseTime: [.exerciseTime]
        case .standTime: [.standTime]
        case .bodyMass: [.bodyMass]
        case .bodyFatPercentage: [.bodyFatPercentage]
        case .sleepingWristTemperature: [.sleepingWristTemperature]
        }
    }

    /// What to ask HealthKit for. Blood pressure is requested as its systolic and diastolic quantity
    /// types, never as the correlation type.
    var sampleTypes: [HKSampleType] {
        switch self {
        case .sleep: [HKCategoryType(.sleepAnalysis)]
        case .workout: [HKObjectType.workoutType()]
        default: metrics.map(\.quantityType)
        }
    }
}
