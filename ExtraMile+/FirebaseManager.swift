//
//  RunEntryViewModel.swift
//  ExtraMile
//
//  Created by Brevin Blalock on 3/1/24.
//

import Foundation
import Firebase
import FirebaseAuth

@Observable class FirebaseManager {
    var runs = [RunModel]()

    // MARK: - Computed Stats

    var totalMiles: Double {
        runs.reduce(0.0) { $0 + $1.miles }
    }

    var totalRunCount: Int {
        runs.count
    }

    var averagePaceFormatted: String {
        let validRuns = runs.filter { $0.miles > 0 && $0.totalSeconds > 0 }
        guard !validRuns.isEmpty else { return "--:--" }
        let totalSec = validRuns.reduce(0) { $0 + $1.totalSeconds }
        let totalMi = validRuns.reduce(0.0) { $0 + $1.miles }
        guard totalMi > 0 else { return "--:--" }
        let avgPace = Double(totalSec) / totalMi
        return Self.formatPace(seconds: Int(avgPace))
    }

    var longestRun: RunModel? {
        runs.max(by: { $0.miles < $1.miles })
    }

    var fastestPaceRun: RunModel? {
        let valid = runs.filter { $0.miles > 0 && $0.totalSeconds > 0 }
        return valid.min(by: { $0.paceSecondsPerMile < $1.paceSecondsPerMile })
    }

    var currentStreak: Int {
        computeStreak().current
    }

    var bestStreak: Int {
        computeStreak().best
    }

    // MARK: - Weekly / Monthly helpers

    func runsThisWeek() -> [RunModel] {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        return runs.filter { $0.date >= startOfWeek && $0.date <= now }
    }

    func runsThisMonth() -> [RunModel] {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start else { return [] }
        return runs.filter { $0.date >= startOfMonth && $0.date <= now }
    }

    func milesThisWeek() -> Double {
        runsThisWeek().reduce(0.0) { $0 + $1.miles }
    }

    func milesThisMonth() -> Double {
        runsThisMonth().reduce(0.0) { $0 + $1.miles }
    }

    func runsPerWeekday() -> [Int: Int] {
        let calendar = Calendar.current
        var counts = [Int: Int]()
        for run in runs {
            let weekday = calendar.component(.weekday, from: run.date)
            counts[weekday, default: 0] += 1
        }
        return counts
    }

    func weeklyMilesHistory(weeks: Int = 8) -> [(weekLabel: String, miles: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var results = [(weekLabel: String, miles: Double)]()

        for i in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { continue }
            let weekRuns = runs.filter { $0.date >= interval.start && $0.date < interval.end }
            let miles = weekRuns.reduce(0.0) { $0 + $1.miles }
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let label = formatter.string(from: interval.start)
            results.append((weekLabel: label, miles: miles))
        }
        return results.reversed()
    }

    func monthlyMilesHistory(months: Int = 6) -> [(monthLabel: String, miles: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var results = [(monthLabel: String, miles: Double)]()

        for i in 0..<months {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: now),
                  let interval = calendar.dateInterval(of: .month, for: monthStart) else { continue }
            let monthRuns = runs.filter { $0.date >= interval.start && $0.date < interval.end }
            let miles = monthRuns.reduce(0.0) { $0 + $1.miles }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let label = formatter.string(from: interval.start)
            results.append((monthLabel: label, miles: miles))
        }
        return results.reversed()
    }

    // MARK: - Streak Computation

    private func computeStreak() -> (current: Int, best: Int) {
        guard !runs.isEmpty else { return (0, 0) }
        let calendar = Calendar.current
        let runDays = Set(runs.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        guard !runDays.isEmpty else { return (0, 0) }

        var current = 0
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Current streak: starts from today or yesterday
        if runDays[0] == today || runDays[0] == yesterday {
            current = 1
            for i in 1..<runDays.count {
                let expected = calendar.date(byAdding: .day, value: -1, to: runDays[i - 1])!
                if runDays[i] == expected {
                    current += 1
                } else {
                    break
                }
            }
        }

        // Best streak
        var best = 1
        var streak = 1
        for i in 1..<runDays.count {
            let expected = calendar.date(byAdding: .day, value: -1, to: runDays[i - 1])!
            if runDays[i] == expected {
                streak += 1
                best = max(best, streak)
            } else {
                streak = 1
            }
        }

        return (current, max(current, best))
    }

    // MARK: - Formatting

    static func formatPace(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    static func formatSpeed(hours: Int, minutes: Int, seconds: Int, miles: Double) -> String {
        guard miles > 0 else { return "0.00" }
        let totalTimeInSeconds = Double(hours * 3600 + minutes * 60 + seconds)
        guard totalTimeInSeconds > 0 else { return "0.00" }
        let speed = miles / (totalTimeInSeconds / 3600.0)
        return String(format: "%.2f", speed)
    }

    // MARK: - Firebase Operations

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    func fetchData(profileId: String) async {
        let db = Firestore.firestore()
        let runEntryRef = db.collection("RunEntry")
        let query = runEntryRef.whereField("profileId", isEqualTo: profileId)

        query.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No Documents")
                return
            }

            self.runs = documents.map { queryDocumentSnapshot -> RunModel in
                let data = queryDocumentSnapshot.data()
                let miles = data["miles"] as? Double ?? 0.0
                let time = data["time"] as? Int ?? 0
                let date = data["date"] as? Timestamp
                let profileId = data["profileId"] as? String ?? ""
                let notes = data["notes"] as? String ?? ""
                let documentId = queryDocumentSnapshot.documentID
                return RunModel(miles: miles, time: self.formatTime(seconds: time), date: date?.dateValue() ?? Date.now, profileId: profileId, documentId: documentId, notes: notes)
            }

            self.runs = self.runs.sorted { $0.date > $1.date }
        }
    }

    func deleteRuns(documentId: String) async {
        let db = Firestore.firestore()

        Task {
            do {
                try await db.collection("RunEntry").document(documentId).delete()
            } catch {
                print(error)
            }
        }
    }

    func formatTime(seconds: Int) -> DateComponents {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = (seconds % 3600) % 60
        return DateComponents(hour: hours, minute: minutes, second: remainingSeconds)
    }

    func addData(miles: Double, time: Int, date: Date, profileId: String, notes: String = "") {
        let db = Firestore.firestore()
        db.collection("RunEntry").addDocument(data: [
            "miles": miles,
            "time": time,
            "date": date,
            "profileId": profileId,
            "notes": notes
        ])
    }

    func updateNotes(documentId: String, notes: String) {
        let db = Firestore.firestore()
        db.collection("RunEntry").document(documentId).updateData(["notes": notes])
    }

    func deleteAccount() {
        let user = Auth.auth().currentUser

        user?.delete { error in
          if let error = error {
            // An error happened.
          } else {
            // Account deleted.
          }
        }
    }
}
