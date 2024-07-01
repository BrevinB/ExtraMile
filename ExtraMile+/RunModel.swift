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
}
