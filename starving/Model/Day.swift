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
