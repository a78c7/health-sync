import Foundation
import Testing

@testable import HealthSync

struct SmokeTests {
    @Test func testTargetLinksAgainstApp() {
        #expect(Bundle.main.bundleIdentifier == "com.a78c7.healthsync")
    }
}
