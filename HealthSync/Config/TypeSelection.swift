import Foundation
import Observation

/// Which data types the user has ticked. Everything is ticked until the user changes it.
@MainActor
@Observable
final class TypeSelection {
    static let storageKey = "selectedDataTypes"

    private(set) var selected: Set<HealthDataType>
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
        if let stored = defaults.stringArray(forKey: Self.storageKey) {
            selected = Set(stored.compactMap(HealthDataType.init(rawValue:)))
        } else {
            selected = Set(HealthDataType.allCases)
        }
    }

    func contains(_ type: HealthDataType) -> Bool {
        selected.contains(type)
    }

    func set(_ type: HealthDataType, isSelected: Bool) {
        if isSelected {
            selected.insert(type)
        } else {
            selected.remove(type)
        }
        save()
    }

    func selectAll() {
        selected = Set(HealthDataType.allCases)
        save()
    }

    func deselectAll() {
        selected = []
        save()
    }

    private func save() {
        let ordered = HealthDataType.allCases.filter(selected.contains).map(\.rawValue)
        defaults.set(ordered, forKey: Self.storageKey)
    }
}
