import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case summary, history, trends, settings
}

struct ContentView: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @State private var tab: AppTab = .summary
    @AppStorage("gg.onboarded") private var onboarded = false
    @ObservedObject private var chrome = GGChrome.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .summary: SummaryView(tab: $tab)
                case .history: HistoryView()
                case .trends: TrendsView()
                case .settings: SettingsView()
                }
            }
            .id(tab)
            .transition(.opacity)
            .contentMargins(.bottom, chrome.hidesTabBar ? 0 : 104, for: .scrollContent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !chrome.hidesTabBar {
                GGTabBar(tab: $tab)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background { GGBackdrop() }
        .tint(GGTheme.accent)
        .animation(.easeInOut(duration: 0.2), value: tab)
        .fullScreenCover(isPresented: Binding(get: { !onboarded }, set: { onboarded = !$0 })) {
            OnboardingView { onboarded = true }
        }
        .task {
            // Reachability callbacks are not always delivered promptly; refresh on a light cadence.
            while !Task.isCancelled {
                cm.updateConnectionStatus()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }
}
