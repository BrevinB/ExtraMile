//
//  ContentView.swift
//  ExtraMile
//
//  Created by Brevin Blalock on 1/3/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ContentView: View {
    @Environment(FirebaseManager.self) private var fbManager
    @AppStorage("loginStatus") private var loginStatus: Bool = false
    @AppStorage("mileageGoal") private var mileageGoal: Int = 365
    @AppStorage("weeklyGoal") private var weeklyGoal: Double = 15.0
    @AppStorage("showMotivation") private var showMotivation: Bool = true
    @State private var showNewEntry = false

    private var currentMiles: Double {
        return fbManager.runs.reduce(0.00) { $0 + $1.miles}
    }

    private var percentComplete: Double {
        guard mileageGoal > 0 else { return 0 }
        return currentMiles / Double(mileageGoal)
    }

    private static let motivationalQuotes = [
        "The miracle isn't that I finished. The miracle is that I had the courage to start.",
        "Run when you can, walk if you have to, crawl if you must; just never give up.",
        "Every mile is a gift. Remember that.",
        "You don't have to go fast. You just have to go.",
        "The real purpose of running isn't to win a race. It's to test the limits of the human heart.",
        "Running is nothing more than a series of arguments between the part of your brain that wants to stop and the part that wants to keep going.",
        "One run can change your day, many runs can change your life.",
        "I run because long after my footprints fade, the training will still be working.",
        "The body achieves what the mind believes.",
        "Strength does not come from physical capacity. It comes from an indomitable will.",
        "Today I will do what others won't, so tomorrow I can accomplish what others can't.",
        "Don't dream of winning, train for it!",
    ]

    private var dailyQuote: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return Self.motivationalQuotes[dayOfYear % Self.motivationalQuotes.count]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Motivational quote
                if showMotivation {
                    Text("\"\(dailyQuote)\"")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }

                // Hero: Runner on track toward goal
                runnerTrackSection

                // Streak & weekly summary
                quickStatsRow

                // Weekly goal progress
                weeklyGoalSection

                // Recent runs
                recentRunsSection
            }
            .padding(.bottom, 20)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewEntry.toggle()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow)
                }
                .sheet(isPresented: $showNewEntry) {
                    AddNewEntry()
                }
            }
        }
        .task {
            await fbManager.fetchData(profileId: Auth.auth().currentUser?.uid ?? "")
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("ExtraMile")
    }

    // MARK: - Runner Track (Hero Element)

    @ViewBuilder
    private var runnerTrackSection: some View {
        VStack(spacing: 16) {
            // Percentage headline
            Text("\(String(format: "%.1f", min(percentComplete * 100, 100)))%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.yellow)
                .contentTransition(.numericText())
                .animation(.default, value: percentComplete)

            Text("\(String(format: "%.1f", currentMiles)) mi of \(mileageGoal) mi")
                .font(.title3)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())

            // The signature runner track
            GeometryReader { geo in
                let trackInset: CGFloat = 24
                let trackWidth = geo.size.width - trackInset * 2
                let clampedProgress = min(max(CGFloat(percentComplete), 0), 1.0)
                let runnerX = clampedProgress * trackWidth
                let dashCount = max(1, Int(trackWidth / 24))

                ZStack(alignment: .leading) {
                    // Road background
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: trackWidth, height: 10)
                        .offset(x: trackInset)

                    // Road dashes (center line markings)
                    HStack(spacing: 12) {
                        ForEach(0..<dashCount, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.yellow.opacity(0.15))
                                .frame(width: 12, height: 2)
                        }
                    }
                    .frame(width: trackWidth)
                    .clipped()
                    .offset(x: trackInset)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.yellow.gradient)
                        .frame(width: max(0, runnerX), height: 10)
                        .offset(x: trackInset)
                        .animation(.easeInOut(duration: 0.8), value: percentComplete)

                    // Mile markers
                    ForEach([0.25, 0.5, 0.75], id: \.self) { marker in
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.yellow.opacity(0.3))
                                .frame(width: 2, height: 8)
                            Text("\(Int(Double(mileageGoal) * marker))")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                        .offset(x: trackInset + CGFloat(marker) * trackWidth - 1, y: 12)
                    }

                    // Runner figure
                    Image(systemName: "figure.run")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.yellow)
                        .offset(x: trackInset + runnerX - 8, y: -24)
                        .animation(.easeInOut(duration: 0.8), value: percentComplete)

                    // Checkered flag at finish
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 22))
                        .foregroundStyle(.yellow)
                        .offset(x: trackInset + trackWidth - 11, y: -20)
                }
            }
            .frame(height: 60)
            .padding(.vertical, 8)

            // Start / Finish labels
            HStack {
                Text("Start")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("\(mileageGoal) mi")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 24)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Quick Stats Row

    @ViewBuilder
    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            MiniStatCard(
                icon: "flame.fill",
                value: "\(fbManager.currentStreak)",
                label: "Streak",
                color: .orange
            )

            MiniStatCard(
                icon: "figure.run",
                value: "\(fbManager.totalRunCount)",
                label: "Total Runs",
                color: .blue
            )

            MiniStatCard(
                icon: "speedometer",
                value: fbManager.averagePaceFormatted,
                label: "Avg Pace",
                color: .green
            )

            MiniStatCard(
                icon: "calendar",
                value: String(format: "%.1f", fbManager.milesThisWeek()),
                label: "This Week",
                color: .purple
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Weekly Goal

    @ViewBuilder
    private var weeklyGoalSection: some View {
        let weekMiles = fbManager.milesThisWeek()
        let weekProgress = weeklyGoal > 0 ? weekMiles / weeklyGoal : 0

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Weekly Goal")
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.1f", weekMiles)) / \(String(format: "%.0f", weeklyGoal)) mi")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Mini runner track for weekly goal
            GeometryReader { geo in
                let trackWidth = geo.size.width
                let clampedProgress = min(max(CGFloat(weekProgress), 0), 1.0)
                let runnerX = clampedProgress * trackWidth

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.yellow.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.yellow.gradient)
                        .frame(width: max(0, runnerX), height: 8)
                        .animation(.easeInOut, value: weekProgress)

                    Image(systemName: "figure.run")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.yellow)
                        .offset(x: max(0, runnerX - 6), y: -14)
                        .animation(.easeInOut, value: weekProgress)

                    Image(systemName: "flag.checkered")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow.opacity(0.6))
                        .offset(x: trackWidth - 10, y: -12)
                }
            }
            .frame(height: 28)

            if weekProgress >= 1.0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Weekly goal reached!")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Recent Runs

    @ViewBuilder
    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Runs")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            if fbManager.runs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No runs yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Tap + to log your first run!")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(fbManager.runs.prefix(5)) { run in
                    RecentRunCard(run: run)
                }
                .padding(.horizontal)
            }
        }
    }

}

// MARK: - Subviews

struct MiniStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct RecentRunCard: View {
    let run: RunModel

    private var paceFormatted: String {
        guard run.miles > 0 && run.totalSeconds > 0 else { return "--:--" }
        return FirebaseManager.formatPace(seconds: Int(run.paceSecondsPerMile))
    }

    private var speedFormatted: String {
        guard run.totalSeconds > 0 else { return "0.00" }
        return String(format: "%.2f", run.speedMPH)
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            // Date circle
            VStack {
                Text(dateFormatter.string(from: run.date))
                    .font(.caption2)
                    .bold()
            }
            .frame(width: 48, height: 48)
            .background(Color.yellow.opacity(0.15), in: Circle())

            // Run info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(String(format: "%.2f", run.miles)) mi")
                    .font(.subheadline)
                    .bold()

                HStack(spacing: 8) {
                    Label("\(paceFormatted) /mi", systemImage: "speedometer")
                    Label("\(run.time.value(for: .hour) ?? 0)h \(run.time.value(for: .minute) ?? 0)m", systemImage: "clock")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                if !run.notes.isEmpty {
                    Text(run.notes)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text("\(speedFormatted) mph")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Add New Entry

struct AddNewEntry: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FirebaseManager.self) private var fbManager
    @Environment(PurchaseManager.self) private var purchaseManager
    @State private var miles = ""
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var isShowingAlert = false
    @State private var showPaywall = false
    @FocusState private var focusedField: Field?

    private enum Field { case miles, notes }

    private var totalSeconds: Int {
        hours * 3600 + minutes * 60 + seconds
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Distance
                    inputSection("Distance") {
                        HStack(spacing: 4) {
                            TextField("0.00", text: $miles)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .miles)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                            Text("mi")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Duration
                    inputSection("Duration") {
                        HStack(spacing: 0) {
                            durationWheel(value: $hours, label: "h", count: 24)
                            Text(":")
                                .font(.title2.bold())
                                .foregroundStyle(.secondary)
                            durationWheel(value: $minutes, label: "m", count: 60)
                            Text(":")
                                .font(.title2.bold())
                                .foregroundStyle(.secondary)
                            durationWheel(value: $seconds, label: "s", count: 60)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                    }

                    // Date & Time
                    inputSection("Date & Time") {
                        DatePicker("", selection: $date)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Notes
                    if purchaseManager.isPremium {
                        inputSection("Notes (optional)") {
                            TextField("How was your run?", text: $notes, axis: .vertical)
                                .focused($focusedField, equals: .notes)
                                .lineLimit(3...5)
                        }
                    } else {
                        inputSection("Notes") {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                    Text("Upgrade to Premium to add notes")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }

                    // Live preview
                    if let milesVal = Double(miles), milesVal > 0, totalSeconds > 0 {
                        HStack(spacing: 0) {
                            previewStat("Pace", value: "\(FirebaseManager.formatPace(seconds: Int(Double(totalSeconds) / milesVal))) /mi")
                            previewStat("Speed", value: "\(String(format: "%.1f", milesVal / (Double(totalSeconds) / 3600.0))) mph")
                            previewStat("Cal (est)", value: "~\(Int(milesVal * 100))")
                        }
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }

                    // Add Run button
                    Button {
                        if miles.isEmpty || miles == "0" || miles == "0.0" {
                            isShowingAlert = true
                        } else {
                            fbManager.addData(
                                miles: Double(miles) ?? 0.0,
                                time: totalSeconds,
                                date: date,
                                profileId: Auth.auth().currentUser?.uid ?? "",
                                notes: notes
                            )
                            Task {
                                await fbManager.fetchData(profileId: Auth.auth().currentUser?.uid ?? "")
                            }
                            dismiss()
                        }
                    } label: {
                        Text("Add Run")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .background(Color.yellow, in: Capsule())
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.yellow)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
            .alert("Please enter miles", isPresented: $isShowingAlert) {
                Button("OK", role: .cancel) { isShowingAlert = false }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Components

    private func inputSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            content()
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }

    private func durationWheel(value: Binding<Int>, label: String, count: Int) -> some View {
        HStack(spacing: 2) {
            Picker("", selection: value) {
                ForEach(0..<count, id: \.self) { n in
                    Text("\(n)").tag(n)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60)

            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 12)
        }
    }

    private func previewStat(_ title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
}
