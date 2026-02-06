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

                // Main progress ring
                progressRingSection

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

    // MARK: - Progress Ring

    @ViewBuilder
    private var progressRingSection: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.yellow.opacity(0.15), lineWidth: 14)
                    .frame(width: 180, height: 180)

                // Progress ring
                Circle()
                    .trim(from: 0, to: min(percentComplete, 1.0))
                    .stroke(
                        Color.yellow.gradient,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: percentComplete)

                // Center content
                VStack(spacing: 4) {
                    Text("\(String(format: "%.1f", min(percentComplete * 100, 100)))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.default, value: percentComplete)

                    Text("\(String(format: "%.1f", currentMiles)) mi")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }

            Text("of \(mileageGoal) mi goal")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Text-based progress bar
            HStack(spacing: 0) {
                Text(String(repeating: ".", count: calcDistance(currentMiles, mileageGoal)))
                    .foregroundStyle(.yellow)
                Image(systemName: "figure.run")
                    .foregroundStyle(.yellow)
                Text(String(repeating: ".", count: max(0, 50 - calcDistance(currentMiles, mileageGoal))))
                    .foregroundStyle(.yellow.opacity(0.3))
                Image(systemName: "flag.checkered")
                    .foregroundStyle(.yellow)
            }
            .font(.caption2)
        }
        .padding(.top, 8)
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

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.yellow.opacity(0.15))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.yellow.gradient)
                        .frame(width: min(CGFloat(weekProgress) * geo.size.width, geo.size.width), height: 10)
                        .animation(.easeInOut, value: weekProgress)
                }
            }
            .frame(height: 10)

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

    // MARK: - Helpers

    func calcDistance(_ currentMiles: Double, _ goalAmount: Int) -> Int {
        let percent = Double(currentMiles) / Double(goalAmount)
        return min(50, Int(round(50.0 * Double(percent))))
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
    @State private var miles = ""
    @State private var time: Int = 540
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var isShowingAlert = false

    let placeholder: String = "Miles"

    @State private var width = CGFloat.zero
    @State private var labelWidth = CGFloat.zero

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TextField("Miles", text: $miles)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                        .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .trim(from: 0, to: 0.55)
                                    .stroke(.gray, lineWidth: 1)
                                RoundedRectangle(cornerRadius: 5)
                                    .trim(from: 0.565 + (0.44 * (labelWidth / width)), to: 1)
                                    .stroke(.gray, lineWidth: 1)
                                Text(placeholder)
                                    .foregroundColor(.gray)
                                    .overlay( GeometryReader { geo in Color.clear.onAppear { labelWidth = geo.size.width }})
                                    .padding(2)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity,
                                           maxHeight: .infinity,
                                           alignment: .topLeading)
                                    .offset(x: 20, y: -10)
                            }
                        }
                        .overlay( GeometryReader { geo in Color.clear.onAppear { width = geo.size.width }})
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    TimePickerView(seconds: $time)

                    DatePicker("Date:", selection: $date)
                        .padding(.horizontal, 20)

                    // Notes field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes (optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        TextField("How was your run?", text: $notes, axis: .vertical)
                            .lineLimit(3...5)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                    }

                    // Pace preview
                    if let milesVal = Double(miles), milesVal > 0, time > 0 {
                        HStack(spacing: 16) {
                            VStack {
                                Text("Pace")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(FirebaseManager.formatPace(seconds: Int(Double(time) / milesVal))) /mi")
                                    .font(.subheadline)
                                    .bold()
                            }
                            VStack {
                                Text("Speed")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(String(format: "%.2f", milesVal / (Double(time) / 3600.0))) mph")
                                    .font(.subheadline)
                                    .bold()
                            }
                            VStack {
                                Text("Calories (est)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("~\(Int(milesVal * 100))")
                                    .font(.subheadline)
                                    .bold()
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                    }

                    Button {
                        if miles == "" || miles == "0" || miles == "0.0" {
                            isShowingAlert = true
                        } else {
                            fbManager.addData(
                                miles: Double(miles) ?? 0.0,
                                time: time,
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
                            .frame(maxWidth: 350)
                    }
                    .foregroundStyle(.primary)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .alert("Please enter miles", isPresented: $isShowingAlert) {
                        Button("OK", role: .cancel) { isShowingAlert = false }
                    }
                }
            }
            .navigationTitle("New Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.yellow)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
