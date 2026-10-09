import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @State private var filter: CueFilter = .all
    @State private var showClearConfirm = false
    @State private var editingNote: NoteDay?

    enum CueFilter: String, CaseIterable, Identifiable {
        case all = "All", start = "Start", turn = "Turn"
        var id: String { rawValue }

        func includes(_ e: AssistEvent) -> Bool {
            switch self {
            case .all: return true
            case .start: return e.type != "turn"
            case .turn: return e.type == "turn"
            }
        }
    }

    private var days: [(day: Date, events: [AssistEvent])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: cm.assistEvents.filter(filter.includes)) { cal.startOfDay(for: $0.timestamp) }
        return grouped
            .map { ($0.key, $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.0 > $1.0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "Every cue", title: "History") { optionsMenu }

                if cm.assistEvents.isEmpty {
                    EmptyState(title: "No cues yet",
                               message: "When your Watch delivers a cue, it appears here right away.")
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 8) {
                                ForEach(CueFilter.allCases) { f in
                                    GGChip(title: f.rawValue, on: filter == f) { withAnimation(.snappy) { filter = f } }
                                }
                            }
                            .padding(.horizontal, 22)

                            if days.isEmpty {
                                Text("No \(filter.rawValue.lowercased()) cues yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(GGTheme.text2)
                                    .padding(22)
                            }

                            ForEach(days, id: \.day) { group in
                                DaySection(day: group.day, title: dayTitle(group.day), events: group.events,
                                           note: cm.dailyNotes[noteKey(group.day)]) {
                                    editingNote = NoteDay(date: group.day)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                        .animation(.snappy, value: cm.assistEvents.count)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .background { GGBackdrop() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .confirmationDialog("Clear all cue history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear History", role: .destructive) {
                    withAnimation { cm.clearEvents() }
                }
            } message: {
                Text("This removes every cue from this iPhone and resets today's count on your Watch.")
            }
            .sheet(item: $editingNote) { day in
                NoteEditor(day: day.date)
            }
        }
    }

    private var optionsMenu: some View {
        Menu {
            Picker("Show", selection: $filter) {
                ForEach(CueFilter.allCases) { Text($0.rawValue).tag($0) }
            }
            Divider()
            ShareLink(item: CSVExport(events: cm.assistEvents),
                      preview: SharePreview("GaitGuard history")) {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }
            .disabled(cm.assistEvents.isEmpty)
            Button("Clear History", systemImage: "trash", role: .destructive) {
                showClearConfirm = true
            }
            .disabled(cm.assistEvents.isEmpty)
        } label: {
            Canvas { gc, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                var p = Path()
                for (i, w) in [14.0, 8.0, 3.0].enumerated() {
                    let y = c.y - 4 + Double(i) * 4
                    p.move(to: CGPoint(x: c.x - w / 2, y: y)); p.addLine(to: CGPoint(x: c.x + w / 2, y: y))
                }
                gc.stroke(p, with: .color(GGTheme.text1), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            .frame(width: 38, height: 38)
            .background(GGTheme.card, in: Circle())
        }
        .accessibilityLabel("Filter and options")
    }

    private func dayTitle(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}

/// Calm empty state: a resting dial and one honest sentence.
struct EmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            TickDial(monitoring: false, score: nil, tempo: 100, color: GGTheme.text3, size: 150) {
                Circle().fill(GGTheme.accent).frame(width: 10, height: 10)
            }
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 26, weight: .medium, design: .serif))
                    .foregroundStyle(GGTheme.text1)
                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(GGTheme.text2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DaySection: View {
    let day: Date
    let title: String
    let events: [AssistEvent]
    let note: String?
    let onEditNote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 26, weight: .medium, design: .serif))
                    .tracking(-0.5)
                    .foregroundStyle(GGTheme.text1)
                Spacer()
                Text("\(events.count) \(events.count == 1 ? "CUE" : "CUES")")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(GGTheme.cue)
            }

            Button(action: onEditNote) {
                if let note {
                    Text("\u{201C}\(note)\u{201D}")
                        .font(.system(size: 15, design: .serif))
                        .italic()
                        .foregroundStyle(GGTheme.text2)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                } else {
                    Text("+ Add a note about this day")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GGTheme.accent)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(note.map { "Note: \($0). Edit" } ?? "Add a note")

            VStack(spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { idx, event in
                    TimelineRow(event: event, isLast: idx == events.count - 1)
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
    }
}

private struct TimelineRow: View {
    let event: AssistEvent
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(event.timestamp, style: .time)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GGTheme.text2)
                .monospacedDigit()
                .frame(width: 58, alignment: .leading)
                .padding(.top, 11)

            VStack(spacing: 4) {
                CueGlyph(turn: event.type == "turn", color: GGTheme.assistColor(event.type))
                    .frame(width: 38, height: 38)
                    .background(GGTheme.cardRaised, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                if !isLast {
                    Rectangle().fill(GGTheme.separator).frame(width: 2).frame(maxHeight: .infinity)
                }
            }
            .frame(width: 38)

            VStack(alignment: .leading, spacing: 6) {
                Text(event.type == "turn" ? "Turn cue" : "Start cue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GGTheme.text1)
                HStack(spacing: 8) {
                    SeverityChip(severity: event.severity)
                    if let d = event.duration {
                        Text(String(format: "froze %.1fs", d))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(GGTheme.text2)
                    }
                    if let helpful = event.helpful {
                        Text(helpful ? "helped" : "not needed")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(helpful ? GGTheme.good : GGTheme.text3)
                    }
                }
            }
            .padding(.top, 5)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 64)
        .accessibilityElement(children: .combine)
    }
}

struct NoteDay: Identifiable {
    let date: Date
    var id: Date { date }
}

func noteKey(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}

struct NoteEditor: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss
    let day: Date
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("How did walking feel? Medication timing, sleep, stress…", text: $text, axis: .vertical)
                        .lineLimit(5...12)
                        .focused($focused)
                } footer: {
                    Text("Notes help you and your care team spot patterns.")
                }
            }
            .scrollContentBackground(.hidden)
            .background { GGBackdrop() }
            .navigationTitle(day.formatted(.dateTime.weekday(.wide).month().day()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        cm.saveNote(for: day, text: text.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
            }
            .onAppear {
                text = cm.dailyNotes[noteKey(day)] ?? ""
                focused = true
            }
        }
        .presentationDetents([.medium, .large])
    }
}
