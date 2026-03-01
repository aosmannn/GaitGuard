import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                GGTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GGTheme.sectionSpacing) {
                        if connectivityManager.isWatchMonitoring {
                            MonitoringBanner()
                        }
                        
                        SummaryCardsSection()
                        
                        if !connectivityManager.liveAccelerometerData.isEmpty {
                            LiveMotionSection(data: connectivityManager.liveAccelerometerData)
                        }
                        
                        if !connectivityManager.assistEvents.isEmpty {
                            EventChartsSection(events: connectivityManager.assistEvents)
                        }
                        
                        if let calibration = connectivityManager.lastCalibrationResults {
                            CalibrationCard(results: calibration)
                        }
                        
                        if connectivityManager.assistEvents.isEmpty && connectivityManager.liveAccelerometerData.isEmpty {
                            EmptyAnalyticsState()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
        }
    }
}

struct SummaryCardsSection: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    private var eventsToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return connectivityManager.assistEvents.filter {
            calendar.startOfDay(for: $0.timestamp) == today
        }.count
    }
    
    private var startAssists: Int {
        connectivityManager.assistEvents.filter { $0.type == "start" }.count
    }
    
    private var turnAssists: Int {
        connectivityManager.assistEvents.filter { $0.type == "turn" }.count
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetricTile(value: "\(connectivityManager.assistEvents.count)", label: "Total Events", icon: "waveform.path", gradient: GGTheme.blueGradient)
            MetricTile(value: "\(eventsToday)", label: "Today", icon: "calendar", gradient: GGTheme.greenGradient)
            MetricTile(value: "\(startAssists)", label: "Start Assists", icon: "play.fill", gradient: GGTheme.blueGradient)
            MetricTile(value: "\(turnAssists)", label: "Turn Assists", icon: "arrow.turn.up.right", gradient: GGTheme.orangeGradient)
        }
    }
}

struct MetricTile: View {
    let value: String
    let label: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(gradient)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(GGTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(GGTheme.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(GGTheme.cardBackground)
        .cornerRadius(GGTheme.cardRadius)
    }
}

struct MonitoringBanner: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Watch is Monitoring")
                    .font(.headline)
                    .foregroundColor(GGTheme.textPrimary)
                Text("Real-time data streaming is active")
                    .font(.subheadline)
                    .foregroundColor(GGTheme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.green.opacity(0.15))
        .cornerRadius(GGTheme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: GGTheme.cardRadius)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct LiveMotionSection: View {
    let data: [AccelerometerData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Live Motion", icon: "waveform.path.ecg")
            
            let displayData = Array(data.suffix(100))
            
            Chart {
                ForEach(Array(displayData.enumerated()), id: \.offset) { index, point in
                    LineMark(x: .value("Time", index), y: .value("X", point.x))
                        .foregroundStyle(GGTheme.redGradient)
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Time", index), y: .value("Y", point.y))
                        .foregroundStyle(GGTheme.greenGradient)
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Time", index), y: .value("Z", point.z))
                        .foregroundStyle(GGTheme.blueGradient)
                        .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis { 
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5])).foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel().foregroundStyle(Color.gray)
                }
            }
            .chartXAxis { AxisMarks(values: .automatic) { _ in } }
            .frame(height: 220)
            
            HStack(spacing: 20) {
                LegendItem(color: .red, label: "X-Axis")
                LegendItem(color: .green, label: "Y-Axis")
                LegendItem(color: .blue, label: "Z-Axis")
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(GGTheme.cardBackground)
        .cornerRadius(GGTheme.cardRadius)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundColor(GGTheme.textSecondary)
        }
    }
}

struct EventChartsSection: View {
    let events: [AssistEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: GGTheme.sectionSpacing) {
            EventsByTypeChart(events: events)
            EventsByTimeChart(events: events)
            SeverityChart(events: events)
        }
    }
}

struct EventsByTypeChart: View {
    let events: [AssistEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Event Type", icon: "chart.bar.fill")
            
            let startCount = events.filter { $0.type == "start" }.count
            let turnCount = events.filter { $0.type == "turn" }.count
            
            Chart {
                BarMark(x: .value("Type", "Start"), y: .value("Count", startCount))
                    .foregroundStyle(GGTheme.blueGradient)
                    .cornerRadius(8)
                BarMark(x: .value("Type", "Turn"), y: .value("Count", turnCount))
                    .foregroundStyle(GGTheme.orangeGradient)
                    .cornerRadius(8)
            }
            .chartYAxis { 
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5])).foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel().foregroundStyle(Color.gray)
                }
            }
            .frame(height: 180)
        }
        .padding(20)
        .background(GGTheme.cardBackground)
        .cornerRadius(GGTheme.cardRadius)
    }
}

struct EventsByTimeChart: View {
    let events: [AssistEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Time of Day", icon: "clock.fill")
            
            let hourData = Dictionary(grouping: events) {
                Calendar.current.component(.hour, from: $0.timestamp)
            }.mapValues { $0.count }
            
            Chart {
                ForEach(Array(hourData.keys.sorted()), id: \.self) { hour in
                    BarMark(x: .value("Hour", hour), y: .value("Count", hourData[hour] ?? 0))
                        .foregroundStyle(GGTheme.greenGradient)
                        .cornerRadius(6)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 4)) { value in
                    if let intValue = value.as(Int.self) {
                        AxisValueLabel("\(intValue):00").foregroundStyle(Color.gray)
                    }
                }
            }
            .chartYAxis { 
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5])).foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel().foregroundStyle(Color.gray)
                }
            }
            .frame(height: 180)
        }
        .padding(20)
        .background(GGTheme.cardBackground)
        .cornerRadius(GGTheme.cardRadius)
    }
}

struct SeverityChart: View {
    let events: [AssistEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Severity Distribution", icon: "exclamationmark.triangle.fill")
            
            let low = events.filter { $0.severity < 0.33 }.count
            let medium = events.filter { $0.severity >= 0.33 && $0.severity < 0.66 }.count
            let high = events.filter { $0.severity >= 0.66 }.count
            
            Chart {
                BarMark(x: .value("Severity", "Low"), y: .value("Count", low))
                    .foregroundStyle(GGTheme.greenGradient)
                    .cornerRadius(8)
                BarMark(x: .value("Severity", "Medium"), y: .value("Count", medium))
                    .foregroundStyle(GGTheme.orangeGradient)
                    .cornerRadius(8)
                BarMark(x: .value("Severity", "High"), y: .value("Count", high))
                    .foregroundStyle(GGTheme.redGradient)
                    .cornerRadius(8)
            }
            .chartYAxis { 
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5])).foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel().foregroundStyle(Color.gray)
                }
            }
            .frame(height: 180)
        }
        .padding(20)
        .background(GGTheme.cardBackground)
        .cornerRadius(GGTheme.cardRadius)
    }
}

struct CalibrationCard: View {
    let results: CalibrationResults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Calibration", icon: "tuningfork")
            
            HStack(spacing: 20) {
                CalibrationStat(label: "Baseline", value: String(format: "%.3f", results.average))
                CalibrationStat(label: "Std Dev", value: String(format: "%.3f", results.standardDeviation))
                CalibrationStat(label: "Threshold", value: String(format: "%.3f", results.baselineThreshold))
                CalibrationStat(label: "Samples", value: "\(results.sampleCount)")
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            Text("Calibrated \(results.timestamp, style: .relative) ago")
                .font(.footnote)
                .foregroundColor(GGTheme.textSecondary)
        }
        .padding(20)
        .background(GGTheme.cardBackground)
        .cornerRadius(GGTheme.cardRadius)
    }
}

struct CalibrationStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(GGTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(GGTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.gray)
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(GGTheme.textPrimary)
        }
    }
}

struct EmptyAnalyticsState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundStyle(GGTheme.textSecondary.opacity(0.5))
            Text("No Insights Yet")
                .font(.headline)
                .foregroundColor(GGTheme.textPrimary)
            Text("Once your watch begins recording data, beautiful charts and analytics will appear here.")
                .font(.subheadline)
                .foregroundColor(GGTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}
