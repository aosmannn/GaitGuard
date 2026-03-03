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

                        SummaryGrid()

                        if !cm.liveAccelerometerData.isEmpty {
                            MotionChart(data: cm.liveAccelerometerData)
                        }

                        if !cm.assistEvents.isEmpty {
                            TypeChart(events: cm.assistEvents)
                            TimeChart(events: cm.assistEvents)
                            SeverityDonut(events: cm.assistEvents)
                        }

                        if let cal = cm.lastCalibrationResults {
                            CalibrationCard(results: cal)
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
                .overlay(
                    Circle()
                        .stroke(GGTheme.accent.opacity(0.4), lineWidth: 4)
                )
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

// MARK: - Summary Grid

struct SummaryGrid: View {
    @EnvironmentObject var cm: WatchConnectivityManager

    private var todayCount: Int {
        cm.assistEvents.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }
    private var starts: Int { cm.assistEvents.filter { $0.type == "start" }.count }
    private var turns: Int { cm.assistEvents.filter { $0.type == "turn" }.count }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatCard(value: "\(cm.assistEvents.count)", label: "Total Events", icon: "waveform.path", color: .blue)
            StatCard(value: "\(todayCount)", label: "Today", icon: "calendar", color: GGTheme.accent)
            StatCard(value: "\(starts)", label: "Start Assists", icon: "figure.walk", color: .cyan)
            StatCard(value: "\(turns)", label: "Turn Assists", icon: "arrow.turn.up.right", color: .orange)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .padding(8)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(GGTheme.text1)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(GGTheme.text2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(GGTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.radius))
        .overlay(RoundedRectangle(cornerRadius: GGTheme.radius).stroke(GGTheme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Motion Chart

struct MotionChart: View {
    let data: [AccelerometerData]

    var body: some View {
        ChartCard(title: "Live Motion", icon: "waveform.path.ecg") {
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
            .frame(height: 200)

            HStack(spacing: 16) {
                LegendDot(color: .red, label: "X")
                LegendDot(color: .green, label: "Y")
                LegendDot(color: .blue, label: "Z")
            }
            .padding(.top, 8)
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

// MARK: - Type Chart

struct TypeChart: View {
    let events: [AssistEvent]

    var body: some View {
        ChartCard(title: "By Type", icon: "chart.bar.fill") {
            let starts = events.filter { $0.type == "start" }.count
            let turns = events.filter { $0.type == "turn" }.count

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
            .frame(height: 160)
        }
    }
}

// MARK: - Time Chart

struct TimeChart: View {
    let events: [AssistEvent]

    var body: some View {
        ChartCard(title: "Time of Day", icon: "clock.fill") {
            let hourData = Dictionary(grouping: events) {
                Calendar.current.component(.hour, from: $0.timestamp)
            }.mapValues { $0.count }

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
            .frame(height: 160)
        }
    }
}

// MARK: - Severity Donut

struct SeverityDonut: View {
    let events: [AssistEvent]

    var body: some View {
        let low = events.filter { $0.severity < 0.33 }.count
        let med = events.filter { $0.severity >= 0.33 && $0.severity < 0.66 }.count
        let high = events.filter { $0.severity >= 0.66 }.count

        ChartCard(title: "Severity", icon: "exclamationmark.triangle.fill") {
            Chart {
                BarMark(x: .value("Severity", "Low"), y: .value("Count", low))
                    .foregroundStyle(GGTheme.accent.gradient)
                    .cornerRadius(8)
                BarMark(x: .value("Severity", "Medium"), y: .value("Count", med))
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
            .frame(height: 160)
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

// MARK: - Chart Card Container

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

// MARK: - Empty Trends

struct EmptyTrends: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(GGTheme.text3)
            Text("No Trends Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(GGTheme.text1)
            Text("Start monitoring on your watch to see analytics and trends.")
                .font(.system(size: 14))
                .foregroundColor(GGTheme.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .padding(.vertical, 50)
    }
}
