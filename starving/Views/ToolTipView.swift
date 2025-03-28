//
//  ToolTipView.swift
//  starving
//
//  Created by Alan Haro on 3/9/25.
//

// ToolTipView.swift
import SwiftUI

struct ToolTipView: View {
    var text: String
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.primary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
            .frame(maxWidth: 300)
    }
}

#Preview {
    ToolTipView(text: "Example ToolTip Text")
}
