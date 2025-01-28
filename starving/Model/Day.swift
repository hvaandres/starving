//
//  Day.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import Foundation
import SwiftData

@Model

class Day: Identifiable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var item = [Item]()
    
    init(){
        
    }
}


extension Day {
    static func currentDayPredicate () -> Predicate<Day> {
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: Date.now)
        
        return #Predicate<Day> { $0.date >= start}
    }
}
