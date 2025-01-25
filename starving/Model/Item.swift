//
//  Item.swift
//  starving
//
//  Created by Alan Haro on 1/24/25.
//

import Foundation
import SwiftData

@Model
class Item: Identifiable {
    var id: String = UUID().uuidString
    var title: String = ""
    var lastUpdated: Date = Date()
    var isHidden: Bool = false
    
    init(title: String) {
        self.title = title
    }
}
