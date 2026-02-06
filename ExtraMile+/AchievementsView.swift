//
//  AchievementsView.swift
//  ExtraMile+
//
//  Created on 2/6/26.
//

import SwiftUI

struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let requirement: (FirebaseManager) -> Bool
    let progress: (FirebaseManager) -> Double // 0.0 to 1.0
}

struct AchievementsView: View {
    @Environment(FirebaseManager.self) private var fbManager

    private let achievements: [Achievement] = [
        // Mileage milestones
        Achievement(
            icon: "shoe.fill",
            title: "First Steps",
            description: "Log your first run",
            requirement: { $0.totalRunCount >= 1 },
            progress: { min(1.0, Double($0.totalRunCount) / 1.0) }
        ),
        Achievement(
            icon: "flame.fill",
            title: "Getting Warmed Up",
            description: "Run 10 total miles",
            requirement: { $0.totalMiles >= 10 },
            progress: { min(1.0, $0.totalMiles / 10.0) }
        ),
        Achievement(
            icon: "hare.fill",
            title: "Marathon Equivalent",
            description: "Run 26.2 total miles",
            requirement: { $0.totalMiles >= 26.2 },
            progress: { min(1.0, $0.totalMiles / 26.2) }
        ),
        Achievement(
            icon: "star.fill",
            title: "Half Century",
            description: "Run 50 total miles",
            requirement: { $0.totalMiles >= 50 },
            progress: { min(1.0, $0.totalMiles / 50.0) }
        ),
        Achievement(
            icon: "medal.fill",
            title: "Century Club",
            description: "Run 100 total miles",
            requirement: { $0.totalMiles >= 100 },
            progress: { min(1.0, $0.totalMiles / 100.0) }
        ),
        Achievement(
            icon: "trophy.fill",
            title: "Halfway There",
            description: "Run 182.5 miles (half of 365)",
            requirement: { $0.totalMiles >= 182.5 },
            progress: { min(1.0, $0.totalMiles / 182.5) }
        ),
        Achievement(
            icon: "crown.fill",
            title: "ExtraMile Champion",
            description: "Complete the 365 mile goal",
            requirement: { $0.totalMiles >= 365 },
            progress: { min(1.0, $0.totalMiles / 365.0) }
        ),

        // Run count milestones
        Achievement(
            icon: "5.circle.fill",
            title: "Fab Five",
            description: "Log 5 runs",
            requirement: { $0.totalRunCount >= 5 },
            progress: { min(1.0, Double($0.totalRunCount) / 5.0) }
        ),
        Achievement(
            icon: "10.circle.fill",
            title: "Dedicated Runner",
            description: "Log 10 runs",
            requirement: { $0.totalRunCount >= 10 },
            progress: { min(1.0, Double($0.totalRunCount) / 10.0) }
        ),
        Achievement(
            icon: "25.circle.fill",
            title: "Consistent",
            description: "Log 25 runs",
            requirement: { $0.totalRunCount >= 25 },
            progress: { min(1.0, Double($0.totalRunCount) / 25.0) }
        ),
        Achievement(
            icon: "50.circle.fill",
            title: "Half Century Runs",
            description: "Log 50 runs",
            requirement: { $0.totalRunCount >= 50 },
            progress: { min(1.0, Double($0.totalRunCount) / 50.0) }
        ),
        Achievement(
            icon: "100.circle.fill",
            title: "Triple Digits",
            description: "Log 100 runs",
            requirement: { $0.totalRunCount >= 100 },
            progress: { min(1.0, Double($0.totalRunCount) / 100.0) }
        ),

        // Streak milestones
        Achievement(
            icon: "flame",
            title: "On Fire",
            description: "Achieve a 3-day running streak",
            requirement: { $0.bestStreak >= 3 },
            progress: { min(1.0, Double($0.bestStreak) / 3.0) }
        ),
        Achievement(
            icon: "bolt.fill",
            title: "Week Warrior",
            description: "Achieve a 7-day running streak",
            requirement: { $0.bestStreak >= 7 },
            progress: { min(1.0, Double($0.bestStreak) / 7.0) }
        ),
        Achievement(
            icon: "bolt.shield.fill",
            title: "Unstoppable",
            description: "Achieve a 14-day running streak",
            requirement: { $0.bestStreak >= 14 },
            progress: { min(1.0, Double($0.bestStreak) / 14.0) }
        ),
        Achievement(
            icon: "sparkles",
            title: "Month of Miles",
            description: "Achieve a 30-day running streak",
            requirement: { $0.bestStreak >= 30 },
            progress: { min(1.0, Double($0.bestStreak) / 30.0) }
        ),

        // Single run milestones
        Achievement(
            icon: "figure.run",
            title: "5K Runner",
            description: "Complete a single run of 3.1+ miles",
            requirement: { $0.longestRun?.miles ?? 0 >= 3.1 },
            progress: { min(1.0, ($0.longestRun?.miles ?? 0) / 3.1) }
        ),
        Achievement(
            icon: "figure.run.circle.fill",
            title: "10K Runner",
            description: "Complete a single run of 6.2+ miles",
            requirement: { $0.longestRun?.miles ?? 0 >= 6.2 },
            progress: { min(1.0, ($0.longestRun?.miles ?? 0) / 6.2) }
        ),
        Achievement(
            icon: "figure.run.square.stack.fill",
            title: "Half Marathoner",
            description: "Complete a single run of 13.1+ miles",
            requirement: { $0.longestRun?.miles ?? 0 >= 13.1 },
            progress: { min(1.0, ($0.longestRun?.miles ?? 0) / 13.1) }
        ),
        Achievement(
            icon: "star.circle.fill",
            title: "Marathoner",
            description: "Complete a single run of 26.2+ miles",
            requirement: { $0.longestRun?.miles ?? 0 >= 26.2 },
            progress: { min(1.0, ($0.longestRun?.miles ?? 0) / 26.2) }
        ),
    ]

    private var unlockedCount: Int {
        achievements.filter { $0.requirement(fbManager) }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary header
                VStack(spacing: 8) {
                    Text("\(unlockedCount) of \(achievements.count)")
                        .font(.largeTitle)
                        .bold()

                    Text("Achievements Unlocked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ProgressView(value: Double(unlockedCount), total: Double(achievements.count))
                        .tint(.yellow)
                        .padding(.horizontal, 40)
                }
                .padding(.top)

                // Achievement grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(achievements) { achievement in
                        AchievementCard(
                            achievement: achievement,
                            isUnlocked: achievement.requirement(fbManager),
                            progress: achievement.progress(fbManager)
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .navigationTitle("Achievements")
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? .yellow : .gray.opacity(0.4))
            }

            Text(achievement.title)
                .font(.caption)
                .bold()
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(isUnlocked ? .primary : .secondary)

            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if !isUnlocked {
                ProgressView(value: progress)
                    .tint(.yellow)
                    .scaleEffect(x: 1, y: 0.6, anchor: .center)

                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUnlocked ? Color.yellow.opacity(0.05) : .clear)
                .stroke(isUnlocked ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
