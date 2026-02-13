//
//  RunModel.swift
//  ExtraMile
//
//  Created by Brevin Blalock on 1/4/24.
//

import Foundation

struct RunModel: Observable, Identifiable {
    var id = UUID()
    let miles: Double
    let time: DateComponents
    let date: Date
    let profileId: String
    let documentId: String
    let notes: String

    var totalSeconds: Int {
        let h = time.value(for: .hour) ?? 0
        let m = time.value(for: .minute) ?? 0
        let s = time.value(for: .second) ?? 0
        return h * 3600 + m * 60 + s
    }

    var paceSecondsPerMile: Double {
        guard miles > 0 else { return 0 }
        return Double(totalSeconds) / miles
    }

    var speedMPH: Double {
        guard totalSeconds > 0 else { return 0 }
        return miles / (Double(totalSeconds) / 3600.0)
    }
}
