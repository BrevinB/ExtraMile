//
//  HistoryView.swift
//  ExtraMile
//
//  Created by Brevin Blalock on 2/21/24.
//

import SwiftUI

struct HistoryView: View {
    @Environment(FirebaseManager.self) private var fbManager
    
    var profileId: String = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 10) {
            List(fbManager.runs) { run in
                HStack {
                    historyCardView(run: run)
                    
                    Button {
                        Task {
                            await fbManager.deleteRuns(documentId: run.documentId)
                            await fbManager.fetchData(profileId: profileId)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    
                }
            }
        }
        
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

struct historyCardView: View {
    var run: RunModel
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack {
            HStack() {
                Text("\(String(format: "%.2f", run.miles)) mi")
                    .bold()
                    .font(.subheadline)
                    .padding(.leading)
                
                Text("\(calculatePace(run.time.value(for: .hour) ?? 0, run.time.value(for: .minute) ?? 0, run.time.value(for: .second) ?? 0, run.miles)) mph")
                    .padding(.trailing)
            }
            
            HStack() {
                Text(dateFormatter.string(from: run.date))
                    .font(.subheadline)
                    .padding(.leading)
                
                Text("\(run.time.value(for: .hour) ?? 0)hr \(run.time.value(for: .minute) ?? 0)min \(run.time.value(for: .second) ?? 0)sec")
                    .font(.subheadline)
                    .padding(.trailing)
            }
        }
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
