//
//  StatsView.swift
//  ExtraMile+
//
//  Created on 2/6/26.
//

import SwiftUI
import FirebaseAuth

struct StatsView: View {
    @Environment(FirebaseManager.self) private var fbManager
    @State private var selectedPeriod: StatsPeriod = .weekly

    enum StatsPeriod: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case allTime = "All Time"
    }

    @AppStorage("mileageGoal") private var mileageGoal: Int = 365

    private var totalMiles: Double {
        fbManager.totalMiles
    }

    private var percentComplete: Double {
        guard mileageGoal > 0 else { return 0 }
        return totalMiles / Double(mileageGoal)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mini runner track for goal progress
                miniRunnerTrack
                    .padding(.horizontal)

                // Period picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Summary cards
                summaryCards

                // Bar chart
                barChartSection

                // Personal records
                personalRecordsSection

                // Favorite run day
                favoriteDaySection
            }
            .padding(.vertical)
        }
        .navigationTitle("Stats")
    }

    // MARK: - Mini Runner Track

    @ViewBuilder
    private var miniRunnerTrack: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(String(format: "%.1f", totalMiles)) mi")
                    .font(.headline)
                    .bold()
                Spacer()
                Text("Goal: \(mileageGoal) mi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                let trackWidth = geo.size.width
                let clampedProgress = min(max(CGFloat(percentComplete), 0), 1.0)
                let runnerX = clampedProgress * trackWidth

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.yellow.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.yellow.gradient)
                        .frame(width: max(0, runnerX), height: 8)
                        .animation(.easeInOut(duration: 0.6), value: percentComplete)

                    Image(systemName: "figure.run")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.yellow)
                        .offset(x: max(0, runnerX - 6), y: -16)
                        .animation(.easeInOut(duration: 0.6), value: percentComplete)

                    Image(systemName: "flag.checkered")
                        .font(.system(size: 13))
                        .foregroundStyle(.yellow.opacity(0.6))
                        .offset(x: trackWidth - 10, y: -14)
                }
            }
            .frame(height: 40)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Summary Cards

    @ViewBuilder
    private var summaryCards: some View {
        let periodRuns = runsForPeriod
        let miles = periodRuns.reduce(0.0) { $0 + $1.miles }
        let count = periodRuns.count
        let avgDistance = count > 0 ? miles / Double(count) : 0
        let totalTime = periodRuns.reduce(0) { $0 + $1.totalSeconds }
        let avgPace: String = {
            guard miles > 0 else { return "--:--" }
            return FirebaseManager.formatPace(seconds: Int(Double(totalTime) / miles))
        }()

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Miles", value: String(format: "%.1f", miles), icon: "figure.run", color: .yellow)
            StatCard(title: "Runs", value: "\(count)", icon: "number", color: .blue)
            StatCard(title: "Avg Distance", value: String(format: "%.2f mi", avgDistance), icon: "ruler", color: .green)
            StatCard(title: "Avg Pace", value: "\(avgPace) /mi", icon: "speedometer", color: .orange)
            StatCard(title: "Total Time", value: formatTotalTime(totalTime), icon: "clock", color: .purple)
            StatCard(title: "Calories (est)", value: "\(estimatedCalories(miles: miles))", icon: "flame.fill", color: .red)
        }
        .padding(.horizontal)
    }

    // MARK: - Bar Chart

    @ViewBuilder
    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mileage Trend")
                .font(.headline)
                .padding(.horizontal)

            let data: [(label: String, miles: Double)] = {
                switch selectedPeriod {
                case .weekly, .allTime:
                    return fbManager.weeklyMilesHistory(weeks: 8).map { ($0.weekLabel, $0.miles) }
                case .monthly:
                    return fbManager.monthlyMilesHistory(months: 6).map { ($0.monthLabel, $0.miles) }
                }
            }()

            let maxMiles = data.map(\.miles).max() ?? 1

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", item.miles))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow.gradient)
                            .frame(height: max(4, CGFloat(item.miles / maxMiles) * 120))

                        Text(item.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 160)
            .padding(.horizontal)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Personal Records

    @ViewBuilder
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 10) {
                if let longest = fbManager.longestRun {
                    RecordRow(
                        icon: "arrow.up.right",
                        title: "Longest Run",
                        value: String(format: "%.2f mi", longest.miles),
                        date: longest.date
                    )
                }

                if let fastest = fbManager.fastestPaceRun {
                    RecordRow(
                        icon: "bolt.fill",
                        title: "Fastest Pace",
                        value: "\(FirebaseManager.formatPace(seconds: Int(fastest.paceSecondsPerMile))) /mi",
                        date: fastest.date
                    )
                }

                RecordRow(
                    icon: "flame",
                    title: "Current Streak",
                    value: "\(fbManager.currentStreak) day\(fbManager.currentStreak == 1 ? "" : "s")",
                    date: nil
                )

                RecordRow(
                    icon: "trophy.fill",
                    title: "Best Streak",
                    value: "\(fbManager.bestStreak) day\(fbManager.bestStreak == 1 ? "" : "s")",
                    date: nil
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Favorite Day

    @ViewBuilder
    private var favoriteDaySection: some View {
        let weekdayData = fbManager.runsPerWeekday()
        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let maxCount = weekdayData.values.max() ?? 1

        VStack(alignment: .leading, spacing: 12) {
            Text("Runs by Day of Week")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    let count = weekdayData[day] ?? 0
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(count == maxCount ? Color.yellow : Color.yellow.opacity(0.4))
                            .frame(height: max(4, CGFloat(count) / CGFloat(maxCount) * 80))

                        Text(dayNames[day])
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var runsForPeriod: [RunModel] {
        switch selectedPeriod {
        case .weekly:
            return fbManager.runsThisWeek()
        case .monthly:
            return fbManager.runsThisMonth()
        case .allTime:
            return fbManager.runs
        }
    }

    private func formatTotalTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func estimatedCalories(miles: Double) -> Int {
        // ~100 calories per mile is a common running estimate
        return Int(miles * 100)
    }
}

// MARK: - Subviews

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                Spacer()
            }
            HStack {
                Text(value)
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
            }
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct RecordRow: View {
    let icon: String
    let title: String
    let value: String
    let date: Date?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.yellow)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let date {
                    Text(dateFormatter.string(from: date))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text(value)
                .font(.subheadline)
                .bold()
        }
        .padding(.vertical, 4)
    }
}
