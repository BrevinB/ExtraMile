//
//  ExtraMileApp.swift
//  ExtraMile
//
//  Created by Brevin Blalock on 1/3/24.
//

import SwiftUI
import Firebase



@main
struct ExtraMileApp: App {
    @AppStorage("loginStatus") private var loginStatus: Bool = false
    var fbManager = FirebaseManager()
    
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
                } else {
                    Login()
                }
            }
        }
    }
}
