//
//  ContentView.swift
//  ExtraMile
//
//  Created by Brevin Blalock on 1/3/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import Observation

struct ContentView: View {
    @Environment(FirebaseManager.self) private var fbManager
    @Environment(GoalStore.self) private var goalStore
    @AppStorage("loginStatus") private var loginStatus: Bool = false
    @State private var showNewEntry = false
    @State private var showHistory = false
    @State private var showGoalCreator = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 40) {
                    goalSection
                    recentRunsSection
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showHistory.toggle()
                    } label: {
                        Text("History")
                            .font(.title3)
                            .foregroundStyle(.yellow)
                    }
                    .sheet(isPresented: $showHistory, content: {
                        HistoryView(profileId: Auth.auth().currentUser?.uid ?? "")
                    })
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewEntry.toggle()
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.yellow)
                    }
                    .sheet(isPresented: $showNewEntry) {
                        AddNewEntry()
                    }
                }

                ToolbarItem {
                    Button {
                        do {
                            try Auth.auth().signOut()
                            loginStatus = false
                        } catch {
                            print("Logout Error")
                        }
                    } label: {
                        Text("Log Out")
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .task {
                await fbManager.fetchData(profileId: Auth.auth().currentUser?.uid ?? "")
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("ExtraMile")
        }
        .sheet(isPresented: $showGoalCreator) {
            GoalEditorView()
        }
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goals")
                        .font(.title2)
                        .bold()
                    Text("Create yearly, monthly, or race goals with personalized progress.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showGoalCreator = true
                } label: {
                    Label("Add Goal", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.callout)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                .foregroundStyle(.black)
            }

            if goalStore.goals.isEmpty {
                Text("You haven't added any goals yet. Tap **Add Goal** to build yearly, monthly, or race targets that match your training.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(goalStore.goals) { goal in
                        GoalProgressRow(
                            goal: goal,
                            milesCompleted: miles(for: goal),
                            progress: progress(for: goal),
                            streak: streak(for: goal)
                        )
                        .swipeActions {
                            Button(role: .destructive) {
                                goalStore.removeGoal(goal)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private var recentRunsSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Recent")
                Spacer()
            }
            .font(.title2)
            .bold()

            VStack(spacing: 10) {
                ForEach(fbManager.runs) { run in
                    HStack(spacing: 50) {
                        Text("\(String(format: "%.2f", run.miles)) mi")
                        Text("\(run.time.value(for: .hour) ?? 0)hr \(run.time.value(for: .minute) ?? 0)min")
                        Text("\(calculatePace(run.time.value(for: .hour) ?? 0, run.time.value(for: .minute) ?? 0, run.time.value(for: .second) ?? 0, run.miles)) mph")
                    }
                    .font(.headline)
                }
            }
        }
    }

    private func miles(for goal: GoalModel) -> Double {
        fbManager.runs
            .filter { goal.contains(date: $0.date) }
            .reduce(0.0) { $0 + $1.miles }
    }

    private func progress(for goal: GoalModel) -> Double {
        guard goal.targetMiles > 0 else { return 0 }
        let milesCompleted = miles(for: goal)
        return milesCompleted / goal.targetMiles
    }

    private func streak(for goal: GoalModel) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: goal.startDate)
        let comparisonEnd = calendar.startOfDay(for: min(goal.endDate, Date()))

        if comparisonEnd < start {
            return 0
        }

        let runDates = Set(
            fbManager.runs
                .filter { goal.contains(date: $0.date) }
                .map { calendar.startOfDay(for: $0.date) }
        )

        if runDates.isEmpty {
            return 0
        }

        var currentDate = comparisonEnd
        var streakCount = 0

        while currentDate >= start {
            if runDates.contains(currentDate) {
                streakCount += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else {
                break
            }
        }

        return streakCount
    }

    func calculatePace(_ hour: Int, _ min: Int, _ sec: Int, _ miles: Double) -> String {
        let totalTimeInSeconds = Double(hour * 3600 + min * 60 + sec)
        let pacePerMile = totalTimeInSeconds / miles
        return formatTime(seconds: Int(pacePerMile))
    }

    func formatTime(hours: Int, minutes: Int, seconds: Int) -> String {
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = (seconds % 3600) % 60
        return formatTime(hours: hours, minutes: minutes, seconds: remainingSeconds)
    }
}

#Preview {
    ContentView()
        .environment(FirebaseManager())
        .environment(GoalStore())
}

struct AddNewEntry: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FirebaseManager.self) private var fbManager
    @State private var miles = ""
    @State private var time: Int = 540
    @State private var date: Date = Date()
    @State private var speed = 0.0
    @State private var pace = ""
    @State private var isShowingAlert = false

    let placeholder: String = "Miles"

    @State private var width = CGFloat.zero
    @State private var labelWidth = CGFloat.zero

    var body: some View {
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
                .padding(20)

            TimePickerView(seconds: $time)

            DatePicker("Date:", selection: $date)
                .padding(20)

            Button {
                if miles == "" || miles == "0" || miles == "0.0"{
                    isShowingAlert = true
                } else {
                    fbManager.addData(miles: Double(miles) ?? 0.0, time: time, date: date, profileId: Auth.auth().currentUser?.uid ?? "")

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

    func convertSecondsToDateTime(_ seconds: Int) -> DateComponents {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60

        var dateComponents = DateComponents()
        dateComponents.hour = hours
        dateComponents.minute = minutes
        dateComponents.second = seconds

        return dateComponents
    }
}

struct GoalProgressRow: View {
    let goal: GoalModel
    let milesCompleted: Double
    let progress: Double
    let streak: Int

    private var progressText: String {
        let percent = progress * 100
        return String(format: "%.0f%%", percent)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            GoalProgressRing(progress: progress, label: progressText)

            VStack(alignment: .leading, spacing: 8) {
                Text(goal.title)
                    .font(.headline)
                Text(goal.intervalDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(goal.kind.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                RunnerProgressTrack(progress: progress)

                VStack(alignment: .leading, spacing: 4) {
                    Label("\(String(format: "%.2f", milesCompleted)) / \(String(format: "%.2f", goal.targetMiles)) mi", systemImage: "figure.run")
                        .font(.subheadline)
                    Label("\(streak) day streak", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(streak > 0 ? .orange : .secondary)
                }

                if progress >= 1 {
                    Text("Goal complete! Keep the streak alive.")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .padding(.top, 4)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

struct GoalProgressRing: View {
    let progress: Double
    let label: String

    private var normalizedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 10)
            Circle()
                .trim(from: 0, to: normalizedProgress)
                .stroke(
                    .linearGradient(
                        colors: [.yellow.opacity(0.8), .yellow],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(label)
                .font(.caption)
                .bold()
        }
        .frame(width: 80, height: 80)
    }
}

struct RunnerProgressTrack: View {
    let progress: Double

    private let trackLength = 50

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var leadingDots: Int {
        Int((clampedProgress * Double(trackLength)).rounded())
    }

    private var trailingDots: Int {
        max(trackLength - leadingDots, 0)
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(String(repeating: ".", count: leadingDots))
            Text(Image(systemName: "figure.run"))
                .padding(.horizontal, 2)
            Text(String(repeating: ".", count: trailingDots))
            Text(Image(systemName: "rectangle.checkered"))
                .padding(.leading, 2)
        }
        .font(.caption.monospaced())
        .foregroundStyle(.yellow)
        .animation(.easeInOut(duration: 0.4), value: leadingDots)
    }
}

enum GoalKind: String, CaseIterable, Codable, Identifiable {
    case yearly
    case monthly
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .yearly:
            return "Yearly Goal"
        case .monthly:
            return "Monthly Goal"
        case .custom:
            return "Race Goal"
        }
    }

    func defaultTitle(for startDate: Date, endDate: Date) -> String {
        let calendar = Calendar.current
        switch self {
        case .yearly:
            let year = calendar.component(.year, from: startDate)
            return "\(year) Mileage"
        case .monthly:
            let formatter = DateFormatter()
            formatter.dateFormat = "LLLL yyyy"
            return "\(formatter.string(from: startDate)) Mileage"
        case .custom:
            return "Race Goal"
        }
    }

    func defaultDateRange(from referenceDate: Date = Date(), calendar: Calendar = .current) -> (start: Date, end: Date) {
        switch self {
        case .yearly:
            let components = calendar.dateComponents([.year], from: referenceDate)
            let start = calendar.date(from: components) ?? referenceDate
            let end = calendar.date(byAdding: DateComponents(year: 1, second: -1), to: start) ?? referenceDate
            return (start, end)
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: referenceDate)
            let start = calendar.date(from: components) ?? referenceDate
            let end = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: start) ?? referenceDate
            return (start, end)
        case .custom:
            return (referenceDate, referenceDate)
        }
    }
}

struct GoalModel: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var targetMiles: Double
    var kind: GoalKind
    var startDate: Date
    var endDate: Date

    func contains(date: Date, calendar: Calendar = .current) -> Bool {
        let normalizedDate = calendar.startOfDay(for: date)
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return normalizedDate >= start && normalizedDate <= end
    }

    var intervalDescription: String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: startDate, to: endDate)
    }
}

@Observable
final class GoalStore {
    private(set) var goals: [GoalModel] = []
    private let storageKey = "storedGoals"

    init() {
        loadGoals()
    }

    func addGoal(_ goal: GoalModel) {
        goals.append(goal)
        sortGoals()
        saveGoals()
    }

    func removeGoal(_ goal: GoalModel) {
        goals.removeAll { $0.id == goal.id }
        saveGoals()
    }

    private func sortGoals() {
        goals.sort { $0.startDate < $1.startDate }
    }

    private func saveGoals() {
        do {
            let data = try JSONEncoder().encode(goals)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save goals: \(error.localizedDescription)")
        }
    }

    private func loadGoals() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            goals = try JSONDecoder().decode([GoalModel].self, from: data)
            sortGoals()
        } catch {
            print("Failed to load goals: \(error.localizedDescription)")
        }
    }
}

struct GoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GoalStore.self) private var goalStore

    @State private var title: String = ""
    @State private var targetMiles: String = ""
    @State private var kind: GoalKind = .yearly
    @State private var startDate: Date
    @State private var endDate: Date

    init() {
        let defaults = GoalKind.yearly.defaultDateRange()
        _startDate = State(initialValue: defaults.start)
        _endDate = State(initialValue: defaults.end)
    }

    private var isSaveDisabled: Bool {
        guard let miles = Double(targetMiles), miles > 0 else { return true }
        return startDate > endDate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal title", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(GoalKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    TextField("Target miles", text: $targetMiles)
                        .keyboardType(.decimalPad)
                }

                Section("Schedule") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section("Preview") {
                    let previewGoal = GoalModel(title: previewTitle, targetMiles: Double(targetMiles) ?? 0, kind: kind, startDate: startDate, endDate: endDate)
                    GoalProgressRow(goal: previewGoal, milesCompleted: 0, progress: 0, streak: 0)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .onChange(of: kind) { _, newKind in
                if newKind != .custom {
                    let defaults = newKind.defaultDateRange(from: startDate)
                    startDate = defaults.start
                    endDate = defaults.end
                }
            }
            .onChange(of: startDate) { _, newValue in
                if kind != .custom {
                    let defaults = kind.defaultDateRange(from: newValue)
                    startDate = defaults.start
                    endDate = defaults.end
                } else if endDate < newValue {
                    endDate = newValue
                }
            }
        }
    }

    private var previewTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return kind.defaultTitle(for: startDate, endDate: endDate)
        }
        return trimmed
    }

    private func saveGoal() {
        guard let miles = Double(targetMiles), miles > 0 else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let newGoal = GoalModel(
            title: trimmed.isEmpty ? kind.defaultTitle(for: startDate, endDate: endDate) : trimmed,
            targetMiles: miles,
            kind: kind,
            startDate: startDate,
            endDate: endDate
        )
        goalStore.addGoal(newGoal)
        dismiss()
    }
}
