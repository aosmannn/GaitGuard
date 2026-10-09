import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @State private var range: TrendRange = .week

    enum TrendRange: String, CaseIterable, Identifiable {
        case week = "Week", month = "Month", quarter = "3 Months"
        var id: String { rawValue }
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
        var noun: String {
            switch self {
            case .week: return "week"
            case .month: return "month"
            case .quarter: return "3 months"
            }
        }
    }

    private var calendar: Calendar { .current }

    private var periodStart: Date {
        calendar.date(byAdding: .day, value: -(range.days - 1), to: calendar.startOfDay(for: Date())) ?? Date()
    }

    private var events: [AssistEvent] {
        cm.assistEvents.filter { $0.timestamp >= periodStart }
    }

    private var previousEvents: [AssistEvent] {
        let prevStart = calendar.date(byAdding: .day, value: -range.days, to: periodStart) ?? periodStart
        return cm.assistEvents.filter { $0.timestamp >= prevStart && $0.timestamp < periodStart }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "Patterns", title: "Trends") { EmptyView() }

                if cm.assistEvents.isEmpty {
                    EmptyState(title: "No trends yet",
                               message: "After a few walks with GaitGuard, you'll see how often cues happen and when.")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            GGSegmented(options: TrendRange.allCases.map { ($0, $0.rawValue) }, selection: $range)
                                .padding(.horizontal, 22)

                            DailyAverage(events: events, previous: previousEvents, start: periodStart, days: range.days, noun: range.noun)
                                .padding(.horizontal, 22)
                                .padding(.top, 26)

                            Highlight(current: events, previous: previousEvents, noun: range.noun)
                                .padding(.horizontal, 22)
                                .padding(.top, 28)

                            TimeOfDay(events: events)
                                .padding(.horizontal, 22)
                                .padding(.top, 28)

                            Strength(events: events)
                                .padding(.horizontal, 22)
                                .padding(.top, 28)

                            if let cal = cm.lastCalibrationResults {
                                CalibrationDetailCard(results: cal)
                                    .padding(.horizontal, 22)
                                    .padding(.top, 28)
                            }
                        }
                        .padding(.bottom, 24)
                        .animation(.snappy, value: range)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .background { GGBackdrop() }
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Daily average + chart

private struct DailyAverage: View {
    let events: [AssistEvent]
    let previous: [AssistEvent]
    let start: Date
    let days: Int
    let noun: String

    private struct Point: Identifiable {
        let day: Date
        let type: String
        let count: Int
        var id: String { "\(day.timeIntervalSince1970)-\(type)" }
    }

    private var points: [Point] {
        let cal = Calendar.current
        return (0..<days).flatMap { offset -> [Point] in
            let day = cal.date(byAdding: .day, value: offset, to: start)!
            let dayEvents = events.on(day)
            return [
                Point(day: day, type: "Start", count: dayEvents.filter { $0.type != "turn" }.count),
                Point(day: day, type: "Turn", count: dayEvents.filter { $0.type == "turn" }.count),
            ]
        }
    }

    private var average: Double { Double(events.count) / Double(days) }

    private var comparison: (String, Color)? {
        guard !previous.isEmpty else { return nil }
        let diff = events.count - previous.count
        if diff < 0 { return ("\(-diff) fewer than last \(noun)", GGTheme.good) }
        if diff > 0 { return ("\(diff) more than last \(noun)", GGTheme.cue) }
        return ("Same as last \(noun)", GGTheme.text2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GGLabel("Daily average")
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(format: average < 10 ? "%.1f" : "%.0f", average))
                    .font(.system(size: 68, weight: .regular, design: .serif))
                    .tracking(-2.5)
                    .foregroundStyle(GGTheme.text1)
                    .contentTransition(.numericText())
                Text("cues a day")
                    .font(.system(size: 24, design: .serif))
                    .italic()
                    .foregroundStyle(GGTheme.text2)
            }
            if let comparison {
                Text(comparison.0)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(comparison.1)
            }
            Text("\(start.formatted(.dateTime.month(.abbreviated).day())) – \(Date().formatted(.dateTime.month(.abbreviated).day().year()))")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(GGTheme.text3)

            Chart {
                ForEach(points) { p in
                    BarMark(x: .value("Day", p.day, unit: .day), y: .value("Cues", p.count), width: days > 30 ? .automatic : .fixed(days > 7 ? 7 : 18))
                        .foregroundStyle(by: .value("Type", p.type))
                        .cornerRadius(days > 30 ? 1 : 9)
                }
                if average > 0 {
                    RuleMark(y: .value("Average", average))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .foregroundStyle(GGTheme.text1.opacity(0.28))
                }
            }
            .chartForegroundStyleScale(["Start": GGTheme.cue, "Turn": GGTheme.accentSecondary])
            .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
            .chartYAxis(.hidden)
            .chartXAxis {
                if days <= 7 {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                            .foregroundStyle(GGTheme.text3)
                    }
                } else {
                    AxisMarks(values: .stride(by: .day, count: days > 30 ? 30 : 7)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(GGTheme.text3)
                    }
                }
            }
            .frame(height: 190)
            .padding(.top, 14)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily average \(String(format: "%.1f", average)) cues")
    }
}

// MARK: - Highlight

private struct Highlight: View {
    let current: [AssistEvent]
    let previous: [AssistEvent]
    let noun: String

    private var comparison: (color: Color, text: String, rotation: Double) {
        let diff = current.count - previous.count
        if previous.isEmpty && current.isEmpty {
            return (GGTheme.text2, "No cues this \(noun).", 0)
        }
        if previous.isEmpty {
            return (GGTheme.accent, "\(current.count) \(current.count == 1 ? "cue" : "cues") this \(noun). Keep walking to see how it compares.", 0)
        }
        if diff < 0 {
            return (GGTheme.good, "You needed \(-diff) fewer \(-diff == 1 ? "cue" : "cues") this \(noun) than the one before.", 90)
        }
        if diff > 0 {
            return (GGTheme.cue, "You had \(diff) more \(diff == 1 ? "cue" : "cues") this \(noun) than the one before.", 0)
        }
        return (GGTheme.text2, "Cues held steady compared with the previous \(noun).", 45)
    }

    private var averageFreeze: Double? {
        let durations = current.compactMap(\.duration)
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GGRule()
            GGLabel("Highlight")
            HStack(alignment: .top, spacing: 12) {
                ArrowGlyph()
                    .stroke(comparison.color, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(comparison.rotation))
                    .padding(.top, 8)
                Text(comparison.text)
                    .font(.system(size: 24, design: .serif))
                    .italic()
                    .foregroundStyle(GGTheme.text1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let averageFreeze {
                Text(String(format: "Freezes lasted %.1f seconds on average before a cue helped.", averageFreeze))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(GGTheme.text2)
            }
        }
    }
}

// MARK: - Time of day

private struct TimeOfDay: View {
    let events: [AssistEvent]

    private static let buckets: [(name: String, hours: Range<Int>)] = [
        ("Morning", 5..<12), ("Afternoon", 12..<17), ("Evening", 17..<22), ("Night", 0..<5),
    ]

    private var counts: [(name: String, count: Int)] {
        let cal = Calendar.current
        return Self.buckets.map { bucket in
            let n = events.filter { e in
                let h = cal.component(.hour, from: e.timestamp)
                return bucket.name == "Night" ? (h >= 22 || h < 5) : bucket.hours.contains(h)
            }.count
            return (bucket.name, n)
        }
    }

    private var peak: String? {
        guard let top = counts.max(by: { $0.count < $1.count }), top.count > 0 else { return nil }
        return top.name.lowercased()
    }

    var body: some View {
        let mx = max(1, counts.map(\.count).max() ?? 1)
        VStack(alignment: .leading, spacing: 14) {
            GGRule()
            GGLabel("Time of day")
            if let peak {
                Text("Most cues happen in the \(peak).")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(GGTheme.text2)
            }
            VStack(spacing: 14) {
                ForEach(counts, id: \.name) { item in
                    HStack(spacing: 12) {
                        Text(item.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(GGTheme.text1)
                            .frame(width: 78, alignment: .leading)
                        HStack(spacing: 3) {
                            ForEach(0..<24, id: \.self) { i in
                                Capsule()
                                    .fill(Double(i) < Double(item.count) / Double(mx) * 24 ? GGTheme.cue : GGTheme.separator)
                                    .frame(width: 3, height: i % 5 == 0 ? 18 : 12)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(item.count)")
                            .font(.system(size: 18, design: .serif))
                            .foregroundStyle(GGTheme.text1)
                            .frame(width: 24, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

// MARK: - Strength

private struct Strength: View {
    let events: [AssistEvent]

    private var parts: [(label: String, count: Int, color: Color)] {
        [
            ("Mild", events.filter { $0.severity < 0.33 }.count, GGTheme.good),
            ("Moderate", events.filter { $0.severity >= 0.33 && $0.severity < 0.66 }.count, GGTheme.cue),
            ("Strong", events.filter { $0.severity >= 0.66 }.count, GGTheme.danger),
        ]
    }

    var body: some View {
        let total = max(1, parts.map(\.count).reduce(0, +))
        VStack(alignment: .leading, spacing: 12) {
            GGRule()
            GGLabel("Freeze strength")
            GeometryReader { geo in
                HStack(spacing: 3) {
                    ForEach(parts, id: \.label) { part in
                        if part.count > 0 {
                            Capsule()
                                .fill(part.color)
                                .frame(width: max(8, (geo.size.width - 6) * CGFloat(part.count) / CGFloat(total)))
                        }
                    }
                }
            }
            .frame(height: 12)
            HStack(spacing: 18) {
                ForEach(parts, id: \.label) { part in
                    Text("\(part.label) \(part.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(GGTheme.text2)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Calibration

struct CalibrationDetailCard: View {
    let results: CalibrationResults

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GGRule()
            HStack {
                GGLabel("Your baseline")
                Spacer()
                Text(results.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(GGTheme.text3)
            }
            if let cadence = results.cadence {
                HStack(spacing: 16) {
                    stat("Pace", String(format: "%.0f", cadence), "spm")
                    Rectangle().fill(GGTheme.separator).frame(width: 1, height: 38)
                    stat("Steps", "\(results.steps ?? 0)", "")
                    Rectangle().fill(GGTheme.separator).frame(width: 1, height: 38)
                    stat("Quality", results.qualityLabel ?? "–", "")
                }
                Text("Measured on your calibration walk. Detection and the suggested cue tempo follow this.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(GGTheme.text2)
            } else {
                Text("Calibrated with an earlier version. Calibrate again to use the improved detection.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(GGTheme.text2)
            }
        }
    }

    private func stat(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            GGLabel(label)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(.system(size: 26, design: .serif)).foregroundStyle(GGTheme.text1)
                if !unit.isEmpty { Text(unit).font(.system(size: 12, weight: .medium)).foregroundStyle(GGTheme.text2) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
