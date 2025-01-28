import SwiftUI

struct HideBackButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)  // Hide the back button
            .navigationBarHidden(true)            // Optionally hide the entire navigation bar
    }
}

extension View {
    func hideBackButton() -> some View {
        self.modifier(HideBackButtonModifier())
    }
}

#Preview {
    NavigationView {
        Text("Preview Content")
            .hideBackButton() // Apply the modifier here
    }
}
