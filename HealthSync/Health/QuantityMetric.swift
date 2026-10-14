import HealthKit

/// A HealthKit quantity type plus the unit HealthHook reports it in: metric, with heart rate in count/min.
///
/// The raw value is the stable key for the type; from P2 on it is the webhook JSON `type` field.
enum QuantityMetric: String, CaseIterable, Sendable {
    case heartRate = "heart_rate"
    case restingHeartRate = "resting_heart_rate"
    case walkingHeartRateAverage = "walking_heart_rate_average"
    case heartRateVariabilitySDNN = "heart_rate_variability_sdnn"
    case bloodPressureSystolic = "blood_pressure_systolic"
    case bloodPressureDiastolic = "blood_pressure_diastolic"
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
    case bodyMass = "body_mass"
    case bodyFatPercentage = "body_fat_percentage"
    case sleepingWristTemperature = "sleeping_wrist_temperature"

    var identifier: HKQuantityTypeIdentifier {
        switch self {
        case .heartRate: .heartRate
        case .restingHeartRate: .restingHeartRate
        case .walkingHeartRateAverage: .walkingHeartRateAverage
        case .heartRateVariabilitySDNN: .heartRateVariabilitySDNN
        case .bloodPressureSystolic: .bloodPressureSystolic
        case .bloodPressureDiastolic: .bloodPressureDiastolic
        case .vo2Max: .vo2Max
        case .oxygenSaturation: .oxygenSaturation
        case .respiratoryRate: .respiratoryRate
        case .stepCount: .stepCount
        case .distanceWalkingRunning: .distanceWalkingRunning
        case .flightsClimbed: .flightsClimbed
        case .activeEnergyBurned: .activeEnergyBurned
        case .basalEnergyBurned: .basalEnergyBurned
        case .exerciseTime: .appleExerciseTime
        case .standTime: .appleStandTime
        case .bodyMass: .bodyMass
        case .bodyFatPercentage: .bodyFatPercentage
        case .sleepingWristTemperature: .appleSleepingWristTemperature
        }
    }

    var quantityType: HKQuantityType { HKQuantityType(identifier) }

    var unit: HKUnit {
        switch self {
        case .heartRate, .restingHeartRate, .walkingHeartRateAverage, .respiratoryRate:
            .count().unitDivided(by: .minute())
        case .heartRateVariabilitySDNN: .secondUnit(with: .milli)
        case .bloodPressureSystolic, .bloodPressureDiastolic: .millimeterOfMercury()
        case .vo2Max: .literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo).unitMultiplied(by: .minute()))
        case .oxygenSaturation, .bodyFatPercentage: .percent()
        case .stepCount, .flightsClimbed: .count()
        case .distanceWalkingRunning: .meter()
        case .activeEnergyBurned, .basalEnergyBurned: .kilocalorie()
        case .exerciseTime, .standTime: .minute()
        case .bodyMass: .gramUnit(with: .kilo)
        case .sleepingWristTemperature: .degreeCelsius()
        }
    }

    /// How the unit is written out, following the notation in HealthKit's own headers.
    var unitSymbol: String {
        switch self {
        case .heartRate, .restingHeartRate, .walkingHeartRateAverage, .respiratoryRate: "count/min"
        case .heartRateVariabilitySDNN: "ms"
        case .bloodPressureSystolic, .bloodPressureDiastolic: "mmHg"
        case .vo2Max: "ml/(kg*min)"
        case .oxygenSaturation, .bodyFatPercentage: "%"
        case .stepCount, .flightsClimbed: "count"
        case .distanceWalkingRunning: "m"
        case .activeEnergyBurned, .basalEnergyBurned: "kcal"
        case .exerciseTime, .standTime: "min"
        case .bodyMass: "kg"
        case .sleepingWristTemperature: "degC"
        }
    }

    /// HealthKit's percent unit yields fractions (0.97 for 97 %).
    var isPercentage: Bool { unit == .percent() }

    /// Label for a metric that is one part of a combined data type (blood pressure).
    var componentTitle: String? {
        switch self {
        case .bloodPressureSystolic: "收缩压"
        case .bloodPressureDiastolic: "舒张压"
        default: nil
        }
    }
}
