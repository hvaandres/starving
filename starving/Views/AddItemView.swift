//
//  AddItemView.swift
//  starving
//
//  Created by Alan Haro on 1/27/25.
//

import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme
    @State private var itemTitle = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("What groceries do you need to purchased", text: $itemTitle)
                .textFieldStyle(.roundedBorder)
            
            Button(action: {
                addItem()
                itemTitle = ""
                dismiss()
            }) {
                Text("Add")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                    .cornerRadius(10)
            }
            .disabled(itemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
    
    func addItem() {
        let cleanedTitle = itemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        context.insert(Item(title: cleanedTitle))
        try? context.save()
    }
}

#Preview {
    AddItemView()
}
