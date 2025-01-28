//
//  ItemRow.swift
//  starving
//
//  Created by Alan Haro on 1/28/25.
//

import SwiftUI

struct ItemRow: View {
    let item: Item
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(item.title)
            Spacer()
            
            Button(action: action) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "checkmark.circle")
                    .foregroundStyle(isSelected ? .green : .black)
                    .imageScale(.large)
            }
        }
    }
}

