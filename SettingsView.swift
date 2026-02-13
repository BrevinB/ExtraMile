//
//  SettingsView.swift
//  ExtraMile+
//
//  Created on 2/6/26.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(FirebaseManager.self) private var fbManager
    @Environment(PurchaseManager.self) private var purchaseManager
    @AppStorage("loginStatus") private var loginStatus: Bool = false
    @AppStorage("mileageGoal") private var mileageGoal: Int = 365
    @AppStorage("weeklyGoal") private var weeklyGoal: Double = 15.0
    @AppStorage("showMotivation") private var showMotivation: Bool = true
    @AppStorage("showCalories") private var showCalories: Bool = true

    @State private var isShowingDeleteAlert = false
    @State private var isShowingLogoutAlert = false
    @State private var customGoalText = ""
    @State private var customWeeklyText = ""
    @State private var showPaywall = false

    var body: some View {
        List {
            // Premium Banner
            Section {
                if purchaseManager.isPremium {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Premium Active")
                                .font(.headline)
                            Text("You have access to all features")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Go Premium")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Unlock custom goals, notes, full history & more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Goal Settings
            Section {
                HStack {
                    Label("Yearly Goal", systemImage: "flag.fill")
                        .foregroundStyle(.primary)
                    Spacer()
                    if purchaseManager.isPremium {
                        TextField("365", text: $customGoalText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onAppear { customGoalText = "\(mileageGoal)" }
                            .onChange(of: customGoalText) {
                                if let val = Int(customGoalText), val > 0 {
                                    mileageGoal = val
                                }
                            }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("\(mileageGoal)")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    Text("mi")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Weekly Goal", systemImage: "calendar")
                        .foregroundStyle(.primary)
                    Spacer()
                    if purchaseManager.isPremium {
                        TextField("15", text: $customWeeklyText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onAppear { customWeeklyText = String(format: "%.1f", weeklyGoal) }
                            .onChange(of: customWeeklyText) {
                                if let val = Double(customWeeklyText), val > 0 {
                                    weeklyGoal = val
                                }
                            }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(String(format: "%.1f", weeklyGoal))
                                    .foregroundStyle(.secondary)
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    Text("mi")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Goals")
            } footer: {
                if purchaseManager.isPremium {
                    Text("Set your yearly mileage target and weekly running goal.")
                } else {
                    Text("Upgrade to Premium to customize your goals.")
                }
            }

            // Preferences
            Section("Preferences") {
                Toggle(isOn: $showMotivation) {
                    Label("Daily Motivation", systemImage: "quote.bubble.fill")
                }
                .tint(.yellow)

                Toggle(isOn: $showCalories) {
                    Label("Show Calorie Estimates", systemImage: "flame.fill")
                }
                .tint(.yellow)
            }

            // Quick goal presets — premium only
            if purchaseManager.isPremium {
                Section("Goal Presets") {
                    Button {
                        mileageGoal = 365
                        customGoalText = "365"
                    } label: {
                        HStack {
                            Label("Mile a Day (365 mi)", systemImage: "1.circle")
                            Spacer()
                            if mileageGoal == 365 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .foregroundStyle(.primary)

                    Button {
                        mileageGoal = 500
                        customGoalText = "500"
                    } label: {
                        HStack {
                            Label("500 Mile Club", systemImage: "star.circle")
                            Spacer()
                            if mileageGoal == 500 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .foregroundStyle(.primary)

                    Button {
                        mileageGoal = 1000
                        customGoalText = "1000"
                    } label: {
                        HStack {
                            Label("1000 Mile Challenge", systemImage: "trophy.circle")
                            Spacer()
                            if mileageGoal == 1000 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .foregroundStyle(.primary)

                    Button {
                        mileageGoal = 2026
                        customGoalText = "2026"
                    } label: {
                        HStack {
                            Label("Year in Miles (2026 mi)", systemImage: "crown.fill")
                            Spacer()
                            if mileageGoal == 2026 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }

            // App Icons — premium only
            Section {
                if purchaseManager.isPremium {
                    AppIconRow(iconName: nil, displayName: "Default", isSelected: UIApplication.shared.alternateIconName == nil)
                    AppIconRow(iconName: "AppIconDark", displayName: "Dark", isSelected: UIApplication.shared.alternateIconName == "AppIconDark")
                    AppIconRow(iconName: "AppIconGold", displayName: "Gold", isSelected: UIApplication.shared.alternateIconName == "AppIconGold")
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "app.badge.fill")
                                .foregroundStyle(.yellow)
                            Text("Alternate App Icons")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            } header: {
                Text("App Icon")
            }

            // Account
            Section("Account") {
                if !purchaseManager.isPremium {
                    Button {
                        Task {
                            _ = await purchaseManager.restorePurchases()
                        }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                            .foregroundStyle(.primary)
                    }
                }

                if purchaseManager.isPremium {
                    Button {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Manage Subscription", systemImage: "creditcard")
                            .foregroundStyle(.primary)
                    }
                }

                Button {
                    isShowingLogoutAlert = true
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.primary)
                }

                Button(role: .destructive) {
                    isShowingDeleteAlert = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }

            // App info
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Log Out?", isPresented: $isShowingLogoutAlert) {
            Button("Log Out", role: .destructive) {
                do {
                    try Auth.auth().signOut()
                    loginStatus = false
                } catch {
                    print("Logout Error")
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account?", isPresented: $isShowingDeleteAlert) {
            Button("Delete", role: .destructive) {
                fbManager.deleteAccount()
                do {
                    try Auth.auth().signOut()
                    loginStatus = false
                } catch {
                    print("Logout Error")
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

// MARK: - App Icon Row

struct AppIconRow: View {
    let iconName: String?
    let displayName: String
    let isSelected: Bool

    var body: some View {
        Button {
            UIApplication.shared.setAlternateIconName(iconName)
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.yellow.opacity(iconName == nil ? 0.3 : iconName == "AppIconDark" ? 0.1 : 0.6))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "figure.run")
                            .foregroundStyle(iconName == "AppIconDark" ? .white : .black)
                    )

                Text(displayName)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.yellow)
                }
            }
        }
    }
}
