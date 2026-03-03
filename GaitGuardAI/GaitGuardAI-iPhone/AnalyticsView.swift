import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var cm: WatchConnectivityManager

    var body: some View {
        NavigationStack {
            ZStack {
                GGTheme.bg.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        if cm.isWatchMonitoring {
                            LiveBanner()
                        }

                        if !cm.assistEvents.isEmpty {
                            OverviewStrip(events: cm.assistEvents)
                            EventBreakdownSection(events: cm.assistEvents)
                            TimePatternSection(events: cm.assistEvents)
                            SeveritySection(events: cm.assistEvents)
                        }

                        if !cm.liveAccelerometerData.isEmpty {
                            MotionSection(data: cm.liveAccelerometerData)
                        }

                        if let cal = cm.lastCalibrationResults {
                            CalibrationCard(results: cal)
                        }
                        
                        if !cm.dailyNotes.isEmpty {
                            NotesSection(notes: cm.dailyNotes)
                        }

                        if cm.assistEvents.isEmpty && cm.liveAccelerometerData.isEmpty {
                            EmptyTrends()
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Trends")
        }
    }
}

// MARK: - Live Banner

struct LiveBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(GGTheme.accent)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(GGTheme.accent.opacity(0.4), lineWidth: 4))
            Text("Live monitoring active")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(GGTheme.accent)
            Spacer()
        }
        .padding(16)
        .background(GGTheme.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(GGTheme.accent.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Overview Strip (replaces static number grid)

struct OverviewStrip: View {
    let events: [AssistEvent]

    private var todayCount: Int {
        events.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }
    private var weekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return events.filter { $0.timestamp > weekAgo }.count
    }
    private var avgSeverity: Double {
        guard !events.isEmpty else { return 0 }
        return events.map(\.severity).reduce(0, +) / Double(events.count)
    }

    var body: some View {
        HStack(spacing: 0) {
            OverviewItem(value: "\(events.count)", label: "Total", color: .blue)
            OverviewItem(value: "\(todayCount)", label: "Today", color: GGTheme.accent)
            OverviewItem(value: "\(weekCount)", label: "7 Days", color: .cyan)
            OverviewItem(
                value: String(format: "%.0f%%", avgSeverity * 100),
                label: "Avg Severity",
                color: avgSeverity < 0.33 ? GGTheme.accent : (avgSeverity < 0.66 ? .orange : GGTheme.danger)
            )
        }
        .padding(.vertical, 18)
        .background(GGTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.radius))
        .overlay(RoundedRectangle(cornerRadius: GGTheme.radius).stroke(GGTheme.cardBorder, lineWidth: 1))
    }
}

struct OverviewItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(GGTheme.text2)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Event Breakdown (expandable)

struct EventBreakdownSection: View {
    let events: [AssistEvent]
    @State private var expanded = true

    private var starts: Int { events.filter { $0.type == "start" }.count }
    private var turns: Int { events.filter { $0.type == "turn" }.count }

    var body: some View {
        ExpandableCard(title: "What types of events happened?", icon: "chart.bar.fill", expanded: $expanded) {
            HStack(spacing: 16) {
                BreakdownBar(label: "Start", count: starts, total: events.count, color: .blue)
                BreakdownBar(label: "Turn", count: turns, total: events.count, color: .orange)
            }
            .padding(.top, 4)

            Chart {
                BarMark(x: .value("Type", "Start"), y: .value("Count", starts))
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(8)
                BarMark(x: .value("Type", "Turn"), y: .value("Count", turns))
                    .foregroundStyle(.orange.gradient)
                    .cornerRadius(8)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(GGTheme.text3.opacity(0.4))
                    AxisValueLabel().foregroundStyle(GGTheme.text3)
                }
            }
            .frame(height: 140)
        }
    }
}

struct BreakdownBar: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color

    private var pct: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(GGTheme.text1)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * pct, height: 6)
                        .animation(.easeOut(duration: 0.6), value: pct)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Time Pattern (expandable)

struct TimePatternSection: View {
    let events: [AssistEvent]
    @State private var expanded = false

    var body: some View {
        ExpandableCard(title: "When do events occur most?", icon: "clock.fill", expanded: $expanded) {
            let hourData = Dictionary(grouping: events) {
                Calendar.current.component(.hour, from: $0.timestamp)
            }.mapValues { $0.count }

            if let peakHour = hourData.max(by: { $0.value < $1.value }) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(GGTheme.warn)
                    Text("Peak activity at \(peakHour.key):00 (\(peakHour.value) events)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(GGTheme.text2)
                    Spacer()
                }
                .padding(.bottom, 4)
            }

            Chart {
                ForEach(Array(hourData.keys.sorted()), id: \.self) { hour in
                    BarMark(x: .value("Hour", hour), y: .value("Count", hourData[hour] ?? 0))
                        .foregroundStyle(GGTheme.accent.gradient)
                        .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 4)) { v in
                    if let h = v.as(Int.self) {
                        AxisValueLabel("\(h):00").foregroundStyle(GGTheme.text3)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(GGTheme.text3.opacity(0.4))
                    AxisValueLabel().foregroundStyle(GGTheme.text3)
                }
            }
            .frame(height: 140)
        }
    }
}

// MARK: - Severity (expandable)

struct SeveritySection: View {
    let events: [AssistEvent]
    @State private var expanded = false

    private var low: Int { events.filter { $0.severity < 0.33 }.count }
    private var med: Int { events.filter { $0.severity >= 0.33 && $0.severity < 0.66 }.count }
    private var high: Int { events.filter { $0.severity >= 0.66 }.count }

    var body: some View {
        ExpandableCard(title: "How severe are the events?", icon: "exclamationmark.triangle.fill", expanded: $expanded) {
            HStack(spacing: 12) {
                SeverityPill(label: "Low", count: low, color: GGTheme.accent)
                SeverityPill(label: "Med", count: med, color: .orange)
                SeverityPill(label: "High", count: high, color: GGTheme.danger)
            }

            Chart {
                BarMark(x: .value("Severity", "Low"), y: .value("Count", low))
                    .foregroundStyle(GGTheme.accent.gradient)
                    .cornerRadius(8)
                BarMark(x: .value("Severity", "Med"), y: .value("Count", med))
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(8)
                BarMark(x: .value("Severity", "High"), y: .value("Count", high))
                    .foregroundStyle(GGTheme.danger.gradient)
                    .cornerRadius(8)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(GGTheme.text3.opacity(0.4))
                    AxisValueLabel().foregroundStyle(GGTheme.text3)
                }
            }
            .frame(height: 140)
        }
    }
}

struct SeverityPill: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) \(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Motion Section (expandable)

struct MotionSection: View {
    let data: [AccelerometerData]
    @State private var expanded = true

    var body: some View {
        ExpandableCard(title: "What is my current motion?", icon: "waveform.path.ecg", expanded: $expanded) {
            let display = Array(data.suffix(100))
            Chart {
                ForEach(Array(display.enumerated()), id: \.offset) { i, pt in
                    LineMark(x: .value("T", i), y: .value("X", pt.x))
                        .foregroundStyle(.red.opacity(0.8))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("T", i), y: .value("Y", pt.y))
                        .foregroundStyle(.green.opacity(0.8))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("T", i), y: .value("Z", pt.z))
                        .foregroundStyle(.blue.opacity(0.8))
                        .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(GGTheme.text3.opacity(0.4))
                    AxisValueLabel().foregroundStyle(GGTheme.text3)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 180)

            HStack(spacing: 16) {
                LegendDot(color: .red, label: "X")
                LegendDot(color: .green, label: "Y")
                LegendDot(color: .blue, label: "Z")
            }
            .padding(.top, 6)
        }
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 11)).foregroundColor(GGTheme.text2)
        }
    }
}

// MARK: - Calibration Card

struct CalibrationCard: View {
    let results: CalibrationResults

    var body: some View {
        ChartCard(title: "Calibration", icon: "tuningfork") {
            HStack(spacing: 0) {
                CalStat(label: "Baseline", value: String(format: "%.3f", results.average))
                CalStat(label: "Std Dev", value: String(format: "%.3f", results.standardDeviation))
                CalStat(label: "Threshold", value: String(format: "%.3f", results.baselineThreshold))
                CalStat(label: "Samples", value: "\(results.sampleCount)")
            }
            Divider().background(GGTheme.text3.opacity(0.3))
            Text("Calibrated \(results.timestamp, style: .relative) ago")
                .font(.system(size: 12))
                .foregroundColor(GGTheme.text2)
        }
    }
}

struct CalStat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(GGTheme.text1)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(GGTheme.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Expandable Card

struct ExpandableCard<Content: View>: View {
    let title: String
    let icon: String
    @Binding var expanded: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: expanded ? 14 : 0) {
            Button(action: { withAnimation(.spring(response: 0.35)) { expanded.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(GGTheme.text2)
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(GGTheme.text1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(GGTheme.text3)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if expanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(GGTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.radius))
        .overlay(RoundedRectangle(cornerRadius: GGTheme.radius).stroke(GGTheme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Chart Card Container (for non-expandable cards)

struct ChartCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(GGTheme.text2)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(GGTheme.text1)
            }
            content
        }
        .padding(20)
        .background(GGTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.radius))
        .overlay(RoundedRectangle(cornerRadius: GGTheme.radius).stroke(GGTheme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Notes Section

struct NotesSection: View {
    let notes: [String: String]
    @State private var expanded = false

    var body: some View {
        ExpandableCard(title: "Journal & Notes", icon: "note.text", expanded: $expanded) {
            let sortedNotes = notes.sorted { $0.key > $1.key }
            
            VStack(spacing: 12) {
                ForEach(Array(sortedNotes.prefix(5)), id: \.key) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        if let date = DateFormatter.yyyyMMdd.date(from: note.key) {
                            Text(date, style: .date)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(GGTheme.accent)
                        } else {
                            Text(note.key)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(GGTheme.accent)
                        }
                        
                        Text(note.value)
                            .font(.system(size: 14))
                            .foregroundColor(GGTheme.text1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(GGTheme.cardBorder.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Empty Trends

struct EmptyTrends: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 52))
                .foregroundColor(GGTheme.accent.opacity(0.3))

            VStack(spacing: 8) {
                Text("No Trends Yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(GGTheme.text1)
                Text("Start monitoring on your watch to see trends, charts, and patterns over time.")
                    .font(.system(size: 14))
                    .foregroundColor(GGTheme.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            VStack(alignment: .leading, spacing: 10) {
                TrendPreviewRow(icon: "chart.bar.fill", text: "Event breakdown by type")
                TrendPreviewRow(icon: "clock.fill", text: "Time-of-day patterns")
                TrendPreviewRow(icon: "exclamationmark.triangle.fill", text: "Severity distribution")
                TrendPreviewRow(icon: "waveform.path.ecg", text: "Live motion visualization")
            }
            .padding(16)
            .background(GGTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.vertical, 30)
    }
}

struct TrendPreviewRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(GGTheme.accent)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(GGTheme.text2)
        }
    }
}
