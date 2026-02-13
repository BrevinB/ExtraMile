//
//  HistoryView.swift
//  ExtraMile
//
//  Created by Brevin Blalock on 2/21/24.
//

import SwiftUI
import FirebaseAuth

struct HistoryView: View {
    @Environment(FirebaseManager.self) private var fbManager
    @Environment(PurchaseManager.self) private var purchaseManager
    @AppStorage("loginStatus") private var loginStatus: Bool = false
    @State private var searchText: String = ""
    @State private var sortOrder: SortOrder = .newest
    @State private var editingNoteRun: RunModel?
    @State private var editedNotes: String = ""
    @State private var showPaywall = false

    var profileId: String = ""

    enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case longest = "Longest"
        case fastest = "Fastest"
    }

    private var sortedRuns: [RunModel] {
        // Free users only see last 30 days
        let baseRuns: [RunModel]
        if purchaseManager.isPremium {
            baseRuns = fbManager.runs
        } else {
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            baseRuns = fbManager.runs.filter { $0.date >= thirtyDaysAgo }
        }

        let filtered: [RunModel]
        if searchText.isEmpty {
            filtered = baseRuns
        } else {
            filtered = baseRuns.filter { run in
                let milesStr = String(format: "%.2f", run.miles)
                return milesStr.contains(searchText) ||
                    run.notes.localizedCaseInsensitiveContains(searchText) ||
                    dateFormatter.string(from: run.date).localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .newest:
            return filtered.sorted { $0.date > $1.date }
        case .oldest:
            return filtered.sorted { $0.date < $1.date }
        case .longest:
            return filtered.sorted { $0.miles > $1.miles }
        case .fastest:
            return filtered.filter { $0.miles > 0 && $0.totalSeconds > 0 }
                .sorted { $0.paceSecondsPerMile < $1.paceSecondsPerMile }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // Group runs by month
    private var groupedRuns: [(month: String, runs: [RunModel])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var groups = [(month: String, runs: [RunModel])]()
        var currentMonth = ""
        var currentRuns = [RunModel]()

        for run in sortedRuns {
            let month = formatter.string(from: run.date)
            if month != currentMonth {
                if !currentRuns.isEmpty {
                    groups.append((month: currentMonth, runs: currentRuns))
                }
                currentMonth = month
                currentRuns = [run]
            } else {
                currentRuns.append(run)
            }
        }
        if !currentRuns.isEmpty {
            groups.append((month: currentMonth, runs: currentRuns))
        }
        return groups
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary bar
                HStack(spacing: 16) {
                    VStack {
                        Text("\(fbManager.totalRunCount)")
                            .font(.headline)
                            .bold()
                        Text("Runs")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Divider().frame(height: 30)
                    VStack {
                        Text(String(format: "%.1f", fbManager.totalMiles))
                            .font(.headline)
                            .bold()
                        Text("Miles")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Divider().frame(height: 30)
                    VStack {
                        Text(fbManager.averagePaceFormatted)
                            .font(.headline)
                            .bold()
                        Text("Avg Pace")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)

                // Sort picker
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Run list grouped by month
                List {
                    ForEach(groupedRuns, id: \.month) { group in
                        Section {
                            ForEach(group.runs) { run in
                                HistoryRunRow(run: run, onEditNotes: {
                                    editingNoteRun = run
                                    editedNotes = run.notes
                                })
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await fbManager.deleteRuns(documentId: run.documentId)
                                            await fbManager.fetchData(profileId: profileId)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        if purchaseManager.isPremium {
                                            editingNoteRun = run
                                            editedNotes = run.notes
                                        } else {
                                            showPaywall = true
                                        }
                                    } label: {
                                        Label("Note", systemImage: "pencil")
                                    }
                                    .tint(.yellow)
                                }
                            }
                        } header: {
                            HStack {
                                Text(group.month)
                                Spacer()
                                let monthMiles = group.runs.reduce(0.0) { $0 + $1.miles }
                                Text("\(String(format: "%.1f", monthMiles)) mi")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Upsell banner for free users
                    if !purchaseManager.isPremium {
                        Section {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.title3)
                                        .foregroundStyle(.yellow)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Unlock Full History")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.primary)
                                        Text("You're viewing the last 30 days. Go Premium to see all your runs.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.yellow)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .searchable(text: $searchText, prompt: "Search runs...")
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(item: $editingNoteRun) { run in
                EditNotesSheet(
                    notes: $editedNotes,
                    onSave: {
                        fbManager.updateNotes(documentId: run.documentId, notes: editedNotes)
                        Task {
                            await fbManager.fetchData(profileId: profileId)
                        }
                        editingNoteRun = nil
                    },
                    onCancel: {
                        editingNoteRun = nil
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - History Run Row

struct HistoryRunRow: View {
    let run: RunModel
    let onEditNotes: () -> Void

    private var paceFormatted: String {
        guard run.miles > 0 && run.totalSeconds > 0 else { return "--:--" }
        return FirebaseManager.formatPace(seconds: Int(run.paceSecondsPerMile))
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(String(format: "%.2f", run.miles)) mi")
                    .font(.headline)
                    .bold()

                Spacer()

                Text(dateFormatter.string(from: run.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label("\(paceFormatted) /mi", systemImage: "speedometer")
                Label("\(run.time.value(for: .hour) ?? 0)h \(run.time.value(for: .minute) ?? 0)m \(run.time.value(for: .second) ?? 0)s", systemImage: "clock")
                Label(String(format: "%.2f mph", run.speedMPH), systemImage: "hare")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !run.notes.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .font(.caption2)
                    Text(run.notes)
                        .font(.caption)
                        .lineLimit(2)
                }
                .foregroundStyle(.tertiary)
                .onTapGesture { onEditNotes() }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Notes Sheet

struct EditNotesSheet: View {
    @Binding var notes: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Run Notes")
                    .font(.headline)

                TextEditor(text: $notes)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                        .foregroundStyle(.yellow)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { onSave() }
                        .foregroundStyle(.yellow)
                        .bold()
                }
            }
        }
    }
}

// Make RunModel work with sheet item binding
extension RunModel: Hashable {
    static func == (lhs: RunModel, rhs: RunModel) -> Bool {
        lhs.documentId == rhs.documentId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(documentId)
    }
}
