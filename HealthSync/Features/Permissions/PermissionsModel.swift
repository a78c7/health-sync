import HealthKit
import Observation

@MainActor
@Observable
final class PermissionsModel {
    enum Status {
        case checking
        case needsRequest
        case alreadyRequested
        case nothingSelected
        case unavailable
    }

    private(set) var status = Status.checking
    private(set) var isRequesting = false
    private(set) var errorMessage: String?

    private let healthStore: HealthStore

    init(healthStore: HealthStore = .shared) {
        self.healthStore = healthStore
    }

    func refresh(for types: Set<HealthDataType>) async {
        guard HealthStore.isHealthDataAvailable else {
            status = .unavailable
            return
        }
        guard !types.isEmpty else {
            status = .nothingSelected
            return
        }
        do {
            switch try await healthStore.requestStatus(for: types) {
            case .unnecessary: status = .alreadyRequested
            case .shouldRequest, .unknown: status = .needsRequest
            @unknown default: status = .needsRequest
            }
        } catch {
            errorMessage = HealthStore.message(for: error)
        }
    }

    func request(for types: Set<HealthDataType>) async {
        isRequesting = true
        defer { isRequesting = false }
        do {
            try await healthStore.requestReadAuthorization(for: types)
            errorMessage = nil
        } catch {
            errorMessage = HealthStore.message(for: error)
        }
        await refresh(for: types)
    }
}
