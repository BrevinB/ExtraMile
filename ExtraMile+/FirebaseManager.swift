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
    private var privateRuns = [RunModel]()
    var filteredRuns: [RunModel] {
        privateRuns.filter { run in
            run.date == Date()
        }
    }
    
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
                let documentId = queryDocumentSnapshot.documentID
                return RunModel(miles: miles, time: self.formatTime(seconds: time), date: date?.dateValue() ?? Date.now, profileId: profileId, documentId: documentId)
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
    
    func addData(miles: Double, time: Int, date: Date, profileId: String) {
        let db = Firestore.firestore()
        do {
            db.collection("RunEntry").addDocument(data: ["miles": miles, "time": time, "date": date, "profileId": profileId])
        }
    }
}
