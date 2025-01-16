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
    @State private var showNewEntry = false
    @State private var showHistory = false
    @State private var count = 0
    @State private var moveMan = false
    @State private var goalAmount = 365
    
    private var currentMiles: Double {
        return fbManager.runs.reduce(0.00) { $0 + $1.miles}
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 50) {
                Text("\((String(format: "%.2f", calcPercent(currentMiles, goalAmount) * 100)))% Complete")
                    .font(.title3)
                    .bold()
                    .animation(.default)
                    .contentTransition(.numericText())
                   
                HStack {
                    Text(String(repeating: ".", count: calcDistance(currentMiles, goalAmount))).foregroundStyle(.yellow) + Text(Image(systemName: "figure.run")).foregroundStyle(.yellow) + Text(String(repeating: ".", count: 50-calcDistance(currentMiles, goalAmount))).foregroundStyle(.yellow)
                    + Text(Image(systemName: "rectangle.checkered"))
                        .foregroundStyle(.yellow)
                }
                
                Text("\(String(format: "%.2f", currentMiles))mi of 365mi")
                    .font(.headline)
                    .contentTransition(.numericText())
                
                VStack(spacing: 20){
                    HStack {
                        Text("Recent")
                        Spacer()
                    }.font(.title2).bold()
                    
                    VStack(spacing: 10) {
                        ForEach(fbManager.runs) { run in
                            HStack(spacing: 50) {
                                Text("\(String(format: "%.2f", run.miles)) mi")
                                Text("\(run.time.value(for: .hour) ?? 0)hr \(run.time.value(for: .minute) ?? 0)min")
                                Text("\(calculatePace(run.time.value(for: .hour) ?? 0, run.time.value(for: .minute) ?? 0, run.time.value(for: .second) ?? 0, run.miles)) mph")
                            }.font(.headline)
                        }
                    }
                }
            }
            .padding()
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
        }.ignoresSafeArea(.all)
        
    }
    
    func calcDistance(_ currentMiles: Double, _ goalAmount: Int) -> Int {
        let percent = Double(currentMiles) / Double(goalAmount)
        return Int(round(50.0 * Double(percent)))
    }
    
    func calcPercent(_ currentMiles: Double, _ goalAmount: Int) -> Double {
        return currentMiles / Double(goalAmount)
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
