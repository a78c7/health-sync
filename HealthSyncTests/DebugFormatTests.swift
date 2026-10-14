import Testing

@testable import HealthSync

struct DebugFormatTests {
    static let durations: [(seconds: Double, text: String)] = [
        (0, "0 分钟"),
        (29, "0 分钟"),
        (31, "1 分钟"),
        (3_540, "59 分钟"),
        (3_600, "1 小时 0 分钟"),
        (25_940, "7 小时 12 分钟"),
    ]

    @Test(arguments: durations)
    func durationRoundsToMinutes(seconds: Double, expected: String) {
        #expect(DebugFormat.duration(seconds) == expected)
    }

    @Test func percentagesAreShownOutOfAHundred() {
        let text = DebugFormat.latest(.quantity(.oxygenSaturation, value: 0.97, date: .now))
        #expect(text.hasPrefix("最近 97 %"))
    }
}
