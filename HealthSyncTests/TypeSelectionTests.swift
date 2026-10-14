import Foundation
import Testing

@testable import HealthSync

@MainActor
struct TypeSelectionTests {
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "TypeSelectionTests.\(UUID().uuidString)"))
    }

    @Test func startsWithEverythingSelected() {
        #expect(TypeSelection(defaults: defaults).selected == Set(HealthDataType.allCases))
    }

    @Test func remembersChanges() {
        let selection = TypeSelection(defaults: defaults)
        selection.set(.heartRate, isSelected: false)

        let reloaded = TypeSelection(defaults: defaults)
        #expect(!reloaded.contains(.heartRate))
        #expect(reloaded.selected.count == 19)
    }

    @Test func remembersAnEmptySelection() {
        TypeSelection(defaults: defaults).deselectAll()
        #expect(TypeSelection(defaults: defaults).selected.isEmpty)
    }

    @Test func ignoresUnknownStoredKeys() {
        defaults.set(["sleep", "no_such_type"], forKey: TypeSelection.storageKey)
        #expect(TypeSelection(defaults: defaults).selected == [.sleep])
    }
}
