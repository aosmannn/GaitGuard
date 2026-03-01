import SwiftUI
import Charts

// MARK: - Insights View

struct AnalyticsView: View {
    @EnvironmentObject var cm: WatchConnectivityManager

    private var eventsToday: Int {
        let start = Calendar.current.startOfDay(for: Date())
        return cm.assistEvents.filter { Calendar.current.startOfDay(for: $0.timestamp) == start }.count
    }

    private var startEvents: Int { cm.assistEvents.filter { $0.type == "start" }.count }
    private var turnEvents: Int { cm.assistEvents.filter { $0.type == "turn" }.count }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: GGTheme.sectionSpacing) {
                    summaryCards
                    if cm.isWatchMonitoring { monitoringBanner }
                    liveMotionSection
                    if !cm.assistEvents.isEmpty { eventChartsSection }
                    if cm.assistEvents.isEmpty { emptyInsights }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insights")
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                InsightCard(value: "\(cm.assistEvents.count)", label: "Total Events", icon: "waveform.path", gradient: [.blue, .cyan])
                InsightCard(value: "\(eventsToday)", label: "Today", icon: "calendar", gradient: [.green, .mint])
            }
            HStack(spacing: 12) {
                InsightCard(value: "\(startEvents)", label: "Start Assists", icon: "figure.stand", gradient: [.indigo, .blue])
                InsightCard(value: "\(turnEvents)", label: "Turn Assists", icon: "arrow.triangle.turn.up.right.diamond", gradient: [.orange, .yellow])
            }
            if let steps = cm.latestStepData {
                HStack(spacing: 12) {
                    InsightCard(value: "\(steps.stepCount)", label: "Steps", icon: "figure.walk", gradient: [.purple, .pink])
                    if let cadence = steps.cadence, cadence > 0 {
                        InsightCard(
                            value: String(format: "%.0f", cadence * 60),
                            label: "Cadence/min",
                            icon: "metronome",
                            gradient: [.orange, .red]
                        )
                    } else {
                        let distVal = steps.distance.map { String(format: "%.0fm", $0) } ?? "--"
                        InsightCard(
                            value: distVal,
                            label: "Distance",
                            icon: "location",
                            gradient: [.teal, .cyan]
                        )
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Monitoring Banner

    private var monitoringBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.shield.fill")
                .font(.title3)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Watch is monitoring")
                    .font(.subheadline.weight(.semibold))
                Text("Real-time data streaming active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.cardRadius))
    }

    // MARK: - Live Motion

    private var liveMotionSection: some View {
        Group {
            if !cm.liveAccelerometerData.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Live Motion", subtitle: "\(cm.liveAccelerometerData.count) samples")
                    LiveAccelerometerChart(data: cm.liveAccelerometerData)
                        .frame(height: 220)
                    if let cal = cm.lastCalibrationResults {
                        CalibrationResultsCard(results: cal)
                    }
                }
            } else if cm.isWatchReachable {
                VStack(spacing: 10) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 36))
                        .foregroundStyle(.quaternary)
                    Text(cm.isWatchMonitoring ? "Receiving motion data..." : "Start monitoring on your watch")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(GGTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: GGTheme.cardRadius))
            }
        }
    }

    // MARK: - Event Charts

    private var eventChartsSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Event Breakdown", subtitle: nil)
            EventsByTypeChart(events: cm.assistEvents)
            EventsByHourChart(events: cm.assistEvents)
            SeverityChart(events: cm.assistEvents)
        }
    }

    // MARK: - Empty State

    private var emptyInsights: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("No insights yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Charts and trends appear after gait events are recorded during monitoring sessions.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        HStack {
            Text(title).font(.title3.bold())
            Spacer()
            if let sub = subtitle {
                Text(sub).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Insight Card (gradient)

struct InsightCard: View {
    let value: String
    let label: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold().monospacedDigit())
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(GGTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Stat Card (kept for compatibility)

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        InsightCard(value: value, label: title, icon: icon, gradient: [color, color.opacity(0.6)])
    }
}

// MARK: - Events by Type Chart

struct EventsByTypeChart: View {
    let events: [AssistEvent]

    var body: some View {
        let startCount = events.filter { $0.type == "start" }.count
        let turnCount = events.filter { $0.type == "turn" }.count

        VStack(alignment: .leading, spacing: 10) {
            Text("By Type").font(.subheadline.weight(.semibold))
            Chart {
                BarMark(x: .value("Type", "Gait Initiation"), y: .value("Count", startCount))
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(6)
                BarMark(x: .value("Type", "Turn Assist"), y: .value("Count", turnCount))
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(6)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 160)
        }
        .padding()
        .background(GGTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.cardRadius))
    }
}

// MARK: - Events by Hour Chart

struct EventsByHourChart: View {
    let events: [AssistEvent]

    var body: some View {
        let hourData = Dictionary(grouping: events) {
            Calendar.current.component(.hour, from: $0.timestamp)
        }.mapValues { $0.count }

        VStack(alignment: .leading, spacing: 10) {
            Text("By Time of Day").font(.subheadline.weight(.semibold))
            Chart {
                ForEach(Array(hourData.keys.sorted()), id: \.self) { hour in
                    BarMark(x: .value("Hour", hour), y: .value("Count", hourData[hour] ?? 0))
                        .foregroundStyle(Color.green.gradient)
                        .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 3)) { val in
                    AxisGridLine()
                    if let hr = val.as(Int.self) { AxisValueLabel("\(hr)h") }
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 160)
        }
        .padding()
        .background(GGTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.cardRadius))
    }
}

// MARK: - Severity Chart

struct SeverityChart: View {
    let events: [AssistEvent]

    var body: some View {
        let low = events.filter { $0.severity < 0.33 }.count
        let med = events.filter { $0.severity >= 0.33 && $0.severity < 0.66 }.count
        let high = events.filter { $0.severity >= 0.66 }.count

        VStack(alignment: .leading, spacing: 10) {
            Text("Severity").font(.subheadline.weight(.semibold))
            Chart {
                BarMark(x: .value("Level", "Low"), y: .value("Count", low))
                    .foregroundStyle(Color.green.gradient).cornerRadius(6)
                BarMark(x: .value("Level", "Medium"), y: .value("Count", med))
                    .foregroundStyle(Color.yellow.gradient).cornerRadius(6)
                BarMark(x: .value("Level", "High"), y: .value("Count", high))
                    .foregroundStyle(Color.red.gradient).cornerRadius(6)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 160)
        }
        .padding()
        .background(GGTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.cardRadius))
    }
}

// MARK: - Live Accelerometer Chart

struct LiveAccelerometerChart: View {
    let data: [AccelerometerData]

    var body: some View {
        let display = Array(data.suffix(100))
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(Array(display.enumerated()), id: \.offset) { idx, pt in
                    LineMark(x: .value("T", idx), y: .value("X", pt.x))
                        .foregroundStyle(.red).interpolationMethod(.catmullRom)
                    LineMark(x: .value("T", idx), y: .value("Y", pt.y))
                        .foregroundStyle(.green).interpolationMethod(.catmullRom)
                    LineMark(x: .value("T", idx), y: .value("Z", pt.z))
                        .foregroundStyle(.blue).interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .chartXAxis(.hidden)

            HStack(spacing: 16) {
                ForEach(["X": Color.red, "Y": Color.green, "Z": Color.blue].sorted(by: { $0.key < $1.key }), id: \.key) { axis, color in
                    HStack(spacing: 4) {
                        Circle().fill(color).frame(width: 7, height: 7)
                        Text(axis).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(GGTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.cardRadius))
    }
}

// MARK: - Calibration Results Card

struct CalibrationResultsCard: View {
    let results: CalibrationResults

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tuningfork")
                    .foregroundStyle(.blue)
                Text("Calibration").font(.subheadline.weight(.semibold))
                Spacer()
                Text(results.timestamp, style: .relative)
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            HStack(spacing: 16) {
                CalibrationStat(label: "Baseline", value: String(format: "%.3f", results.average))
                CalibrationStat(label: "Std Dev", value: String(format: "%.3f", results.standardDeviation))
                CalibrationStat(label: "Threshold", value: String(format: "%.3f", results.baselineThreshold), highlight: true)
                CalibrationStat(label: "Samples", value: "\(results.sampleCount)")
            }
        }
        .padding()
        .background(GGTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.cardRadius))
    }
}

struct CalibrationStat: View {
    let label: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(highlight ? .blue : .primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
