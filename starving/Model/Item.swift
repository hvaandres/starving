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
    var sharedById: String? = nil
    var sharedByName: String? = nil
    var sharedByPhotoURL: String? = nil
    var sharedListId: String? = nil
    var isCompleted: Bool = false
    
    init(title: String, sharedById: String? = nil, sharedByName: String? = nil, sharedByPhotoURL: String? = nil, sharedListId: String? = nil) {
        self.title = title
        self.sharedById = sharedById
        self.sharedByName = sharedByName
        self.sharedByPhotoURL = sharedByPhotoURL
        self.sharedListId = sharedListId
    }
}
