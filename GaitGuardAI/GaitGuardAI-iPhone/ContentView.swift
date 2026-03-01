import SwiftUI
import WatchConnectivity

enum GGTheme {
    static let background = Color.black
    static let cardBackground = Color(white: 0.11)
    static let cardRadius: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    
    static let textPrimary = Color.white
    static let textSecondary = Color.gray
    
    // Gradients for metrics
    static let blueGradient = LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let greenGradient = LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let orangeGradient = LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let redGradient = LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct ContentView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "rectangle.3.group.fill")
                }
                .tag(0)
            
            AnalyticsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.xaxis")
                }
                .tag(1)
            
            RemoteControlsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .preferredColorScheme(.dark)
    }
}

struct DashboardView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                GGTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GGTheme.sectionSpacing) {
                        ConnectionCard()
                        
                        if connectivityManager.isWatchMonitoring, let stepData = connectivityManager.latestStepData {
                            LiveMetricsRow(stepData: stepData)
                        }
                        
                        EventsSection()
                    }
                    .padding()
                }
            }
            .navigationTitle("GaitGuard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !connectivityManager.assistEvents.isEmpty {
                        Button("Clear") {
                            withAnimation {
                                connectivityManager.clearEvents()
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                connectivityManager.updateConnectionStatus()
                startConnectionMonitoring()
            }
            .onDisappear {
                stopConnectionMonitoring()
            }
        }
    }
    
    private func startConnectionMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            connectivityManager.updateConnectionStatus()
            _ = connectivityManager.wcSession?.isReachable
        }
    }
    
    private func stopConnectionMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}

struct ConnectionCard: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    private var statusColor: Color {
        if connectivityManager.isWatchReachable { return .green }
        if connectivityManager.isWatchConnected { return .orange }
        return .red
    }
    
    private var statusTitle: String {
        if connectivityManager.isWatchReachable { return "Connected" }
        if connectivityManager.isWatchConnected { return "Paired" }
        return "Not Paired"
    }
    
    private var statusSubtitle: String {
        if connectivityManager.isWatchReachable {
            if connectivityManager.isWatchMonitoring {
                return "Watch is monitoring"
            }
            return "Ready to monitor"
        }
        if connectivityManager.isWatchConnected {
            return "Open Watch app → tap START"
        }
        if connectivityManager.activationState == .notActivated {
            return "Initializing..."
        }
        return "Pair your Apple Watch"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 54, height: 54)
                
                Image(systemName: connectivityManager.isWatchReachable ? "applewatch.watchface" : "applewatch.slash")
                    .font(.title2)
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(statusTitle)
                        .font(.headline)
                        .foregroundColor(GGTheme.textPrimary)
                    Spacer()
                    Button(action: { connectivityManager.updateConnectionStatus() }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                            .foregroundColor(GGTheme.textSecondary)
                    }
                }
                
                Text(statusSubtitle)
                    .font(.subheadline)
                    .foregroundColor(GGTheme.textSecondary)
                
                if connectivityManager.isWatchReachable, let lastHeartbeat = connectivityManager.lastHeartbeatTime {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Updated \(lastHeartbeat, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(GGTheme.textSecondary)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(20)
        .background(GGTheme.cardBackground)
        .cornerRadius(GGTheme.cardRadius)
    }
}

struct LiveMetricsRow: View {
    let stepData: StepData
    
    var body: some View {
        HStack(spacing: 12) {
            CompactMetricCard(
                value: "\(stepData.stepCount)",
                label: "Steps",
                icon: "figure.walk",
                gradient: GGTheme.blueGradient
            )
            CompactMetricCard(
                value: stepData.cadence.map { String(format: "%.0f", $0) } ?? "—",
                label: "Cadence",
                icon: "metronome.fill",
                gradient: GGTheme.greenGradient
            )
            CompactMetricCard(
                value: stepData.distance.map { String(format: "%.1f", $0) } ?? "—",
                label: "Meters",
                icon: "ruler.fill",
                gradient: GGTheme.orangeGradient
            )
        }
    }
}

struct CompactMetricCard: View {
    let value: String
    let label: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(gradient)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(GGTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text(label)
                    .font(.caption)
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

struct EventsSection: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Events")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(GGTheme.textPrimary)
                Spacer()
                if !connectivityManager.assistEvents.isEmpty {
                    Text("\(connectivityManager.assistEvents.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(GGTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            if connectivityManager.assistEvents.isEmpty {
                EmptyEventsState()
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(connectivityManager.assistEvents.reversed().enumerated()), id: \.element.id) { index, event in
                        EventRow(event: event, isNewest: index == 0)
                    }
                }
            }
        }
    }
}

struct EmptyEventsState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path")
                .font(.system(size: 40))
                .foregroundStyle(GGTheme.textSecondary.opacity(0.5))
            Text("No Events Recorded")
                .font(.headline)
                .foregroundColor(GGTheme.textPrimary)
            Text("When the watch detects a gait freeze, it will appear here automatically.")
                .font(.subheadline)
                .foregroundColor(GGTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(GGTheme.cardBackground)
        .cornerRadius(GGTheme.cardRadius)
    }
}

struct EventRow: View {
    let event: AssistEvent
    let isNewest: Bool
    
    private var severityBadge: (text: String, color: Color) {
        if event.severity < 0.33 { return ("Low", .green) }
        if event.severity < 0.66 { return ("Med", .orange) }
        return ("High", .red)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(event.type == "start" ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: event.type == "start" ? "play.fill" : "arrow.turn.up.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(event.type == "start" ? .blue : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(event.type.capitalized) Assist")
                    .font(.headline)
                    .foregroundColor(GGTheme.textPrimary)
                
                HStack(spacing: 6) {
                    Text(event.timestamp, style: .time)
                    Text("•")
                    if let duration = event.duration {
                        Text(String(format: "%.1fs", duration))
                    } else {
                        Text(event.timestamp, style: .date)
                    }
                }
                .font(.caption)
                .foregroundColor(GGTheme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                if isNewest {
                    Text("LATEST")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green)
                        .clipShape(Capsule())
                }
                
                Text(severityBadge.text)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(severityBadge.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(severityBadge.color.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(GGTheme.cardBackground)
        .cornerRadius(GGTheme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: GGTheme.cardRadius)
                .stroke(isNewest ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}
