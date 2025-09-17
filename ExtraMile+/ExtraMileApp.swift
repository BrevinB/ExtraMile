//
//  ExtraMileApp.swift
//  ExtraMile
//
//  Created by Brevin Blalock on 1/3/24.
//

import SwiftUI
import Firebase
import StoreKit

@main
struct ExtraMileApp: App {
    @AppStorage("loginStatus") private var loginStatus: Bool = false
    @AppStorage("launchCount") private var launchCount: Int = 0
    @AppStorage("lastVersion") private var lastVersion: String = ""
    
    var fbManager = FirebaseManager()
    var goalStore = GoalStore()
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if loginStatus {
                    ContentView()
                        .environment(fbManager)
                        .environment(goalStore)
                } else {
                    Login()
                }
            }
            .onAppear {
                incrementLaunchCount()
            }
        }
    }
    
    private func incrementLaunchCount() {
        if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            // Check if the version has changed
            if currentVersion != lastVersion {
                // Reset launch count and update the stored version
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
