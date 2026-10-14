import HealthKit
import Testing

@testable import HealthSync

struct HealthDataTypeTests {
    @Test func thereAreTwentyTypes() {
        #expect(HealthDataType.allCases.count == 20)
    }

    @Test func storageKeysAreUniqueSnakeCase() {
        let keys = HealthDataType.allCases.map(\.rawValue) + QuantityMetric.allCases.map(\.rawValue)
        #expect(Set(HealthDataType.allCases.map(\.rawValue)).count == HealthDataType.allCases.count)
        #expect(Set(QuantityMetric.allCases.map(\.rawValue)).count == QuantityMetric.allCases.count)
        for key in keys {
            #expect(key.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "_" }, "\(key)")
        }
    }

    @Test func categoriesCoverEveryTypeOnce() {
        let listed = HealthDataType.Category.allCases.flatMap(\.types)
        #expect(listed.count == HealthDataType.allCases.count)
        #expect(Set(listed) == Set(HealthDataType.allCases))
    }

    @Test func everyMetricBelongsToExactlyOneType() {
        let used = HealthDataType.allCases.flatMap(\.metrics)
        #expect(used.count == QuantityMetric.allCases.count)
        #expect(Set(used) == Set(QuantityMetric.allCases))
    }

    @Test(arguments: QuantityMetric.allCases)
    func unitFitsQuantityType(metric: QuantityMetric) {
        #expect(metric.quantityType.is(compatibleWith: metric.unit))
    }

    @Test func heartRateIsReportedPerMinute() {
        let oneBeatPerSecond = HKQuantity(unit: .count().unitDivided(by: .second()), doubleValue: 1)
        #expect(QuantityMetric.heartRate.unitSymbol == "count/min")
        #expect(oneBeatPerSecond.doubleValue(for: QuantityMetric.heartRate.unit) == 60)
    }

    @Test func onlyPercentMetricsAreScaled() {
        let scaled = QuantityMetric.allCases.filter(\.isPercentage)
        #expect(Set(scaled) == [.oxygenSaturation, .bodyFatPercentage])
    }

    @Test func readTypesAskForBloodPressurePartsNotTheCorrelation() {
        let readTypes = HealthStore.readTypes(for: Set(HealthDataType.allCases))
        // 18 single quantity types + systolic + diastolic + sleep + workouts.
        #expect(readTypes.count == 21)
        #expect(readTypes.contains(HKQuantityType(.bloodPressureSystolic)))
        #expect(readTypes.contains(HKQuantityType(.bloodPressureDiastolic)))
        #expect(!readTypes.contains(HKCorrelationType(.bloodPressure)))
        #expect(readTypes.contains(HKCategoryType(.sleepAnalysis)))
        #expect(readTypes.contains(HKObjectType.workoutType()))
    }

    @Test func readTypesFollowTheSelection() {
        let readTypes = HealthStore.readTypes(for: [.sleep, .bloodPressure])
        #expect(readTypes.count == 3)
    }
}
