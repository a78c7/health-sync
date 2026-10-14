import Foundation

/// The App Group shared by the app and any future extensions.
enum AppGroup {
    static let identifier = "group.com.a78c7.healthsync"

    /// Defaults in the group container, or the app's own defaults if the container is unavailable.
    static var defaults: UserDefaults { UserDefaults(suiteName: identifier) ?? .standard }
}
