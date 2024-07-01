//
//  TimePickerView.swift
//  ExtraMile
//
//  Created by Brevin Blalock on 1/6/24.
//

import SwiftUI

struct TimePickerView: View {
    @Binding public var seconds: Int
    
    var daysArray = [Int](0..<30)
    var hoursArray = [Int](0..<23)
    var minutesArray = [Int](0..<59)
    var secondsArray = [Int](0..<59)
    
    private let secondsInMinute = 60
    private let minutesInHour = 60
    private let secondsInHour = 3600
    private let secondsInDay = 86400
    
    @State private var daySelection = 0
    @State private var hourSelection = 0
    @State private var minuteSelection = 0
    @State private var secondSelection = 0
    
    @State private var hourSeconds = 0
    @State private var minSeconds = 0
    @State private var secSeconds = 0
    
    private let frameHeight: CGFloat = 160
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                
                Picker(selection: self.$hourSelection, label: Text("")) {
                    ForEach(0 ..< self.hoursArray.count, id: \.self) { index in
                        Text("\(self.hoursArray[index]) h").tag(index)
                    }
                }
                .onChange(of: self.hourSelection) {
                    seconds = totalInSeconds
                }
                .pickerStyle(.wheel)
                
                Picker(selection: self.$minuteSelection, label: Text("")) {
                    ForEach(0 ..< self.minutesArray.count, id: \.self) { index in
                        Text("\(self.minutesArray[index]) m").tag(index)
                    }
                }
                .onChange(of: self.minuteSelection) {
                    seconds = totalInSeconds
                }
                .pickerStyle(.wheel)
                
                Picker(selection: self.self.$secondSelection, label: Text("")) {
                    ForEach(0 ..< self.secondsArray.count, id: \.self) { index in
                        Text("\(self.secondsArray[index]) s").tag(index)
                    }
                }
                .onChange(of: self.secondSelection) {
                    seconds = totalInSeconds
                }
                .pickerStyle(.wheel)
            }
        }
        .frame(maxHeight: 250)
        .onAppear(perform: {
            updatePickers()
            seconds = 0
        })
    }
    
    func updatePickers() {
        hourSelection = seconds / 3600
        minuteSelection = seconds / 60
    }
    
    var totalInSeconds: Int {
        seconds = 0
        return  (hourSelection * self.secondsInHour) + (minuteSelection *     self.secondsInMinute) + secondSelection
    }
}

#Preview {
    TimePickerView(seconds: .constant(30))
}
