import Foundation

/// Text formatting for the debug page.
enum DebugFormat {
    /// "7 小时 12 分钟", rounded to the nearest minute.
    static func duration(_ interval: TimeInterval) -> String {
        let minutes = Int((interval / 60).rounded())
        let hours = minutes / 60
        return hours > 0 ? "\(hours) 小时 \(minutes % 60) 分钟" : "\(minutes) 分钟"
    }

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func dateTime(_ date: Date) -> String {
        date.formatted(.dateTime.month().day().hour().minute())
    }

    static func latest(_ sample: LatestSample) -> String {
        switch sample {
        case .quantity(let metric, let value, let date):
            let shown = metric.isPercentage ? value * 100 : value
            let number = shown.formatted(.number.precision(.fractionLength(0...1)))
            return "最近 \(number) \(metric.unitSymbol) · \(dateTime(date))"
        case .sleep(let stage, let date):
            return "最近 \(stage.title) · 结束于 \(dateTime(date))"
        case .workout(let activityType, let duration, let date):
            return "最近 类型编号 \(activityType)，\(Self.duration(duration)) · \(dateTime(date))"
        }
    }
}
