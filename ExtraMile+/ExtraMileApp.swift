//
//  ExtraMileApp.swift
//  ExtraMile
//
//  Created by Brevin Blalock on 1/3/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import StoreKit
import RevenueCat

@main
struct ExtraMileApp: App {
    @AppStorage("loginStatus") private var loginStatus: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("launchCount") private var launchCount: Int = 0
    @AppStorage("lastVersion") private var lastVersion: String = ""
    
    var fbManager = FirebaseManager()
    var purchaseManager: PurchaseManager

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        Purchases.configure(withAPIKey: "appl_GCVlGnNxIfTaHpDtWKbCmNzUjHb")
        purchaseManager = PurchaseManager()

        // Customize tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().standardAppearance = tabAppearance
    }

    var body: some Scene {
        WindowGroup {
            if loginStatus {
                MainTabView()
                    .environment(fbManager)
                    .environment(purchaseManager)
                    .onAppear {
                        incrementLaunchCount()
                    }
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .environment(purchaseManager)
                    .onAppear {
                        incrementLaunchCount()
                    }
            } else {
                NavigationStack {
                    Login()
                }
                .onAppear {
                    incrementLaunchCount()
                }
            }
        }
    }

    private func incrementLaunchCount() {
        if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if currentVersion != lastVersion {
                launchCount = 0
                lastVersion = currentVersion
            }
        }

        launchCount += 1

        if launchCount == 5 {
            requestReview()
        }
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(FirebaseManager.self) private var fbManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard tab
            NavigationStack {
                ContentView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            .tag(0)

            // History tab
            NavigationStack {
                HistoryView(profileId: Auth.auth().currentUser?.uid ?? "")
            }
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }
            .tag(1)

            // Stats tab
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(2)

            // Achievements tab
            NavigationStack {
                AchievementsView()
            }
            .tabItem {
                Label("Achievements", systemImage: "trophy.fill")
            }
            .tag(3)

            // Settings tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .tint(.yellow)
    }
}
