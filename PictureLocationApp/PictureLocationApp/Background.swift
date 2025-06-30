import SwiftUI

struct Background: View {
    @State private var animate = false
    
    var body: some View {
        LinearGradient(
            colors: [Color("Background1"), Color("Background2")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(Animation.linear(duration: 10).repeatForever(autoreverses: true), value: animate)
        .onAppear {
            animate = true
        }
    }
}

struct Background_Previews: PreviewProvider {
    static var previews: some View {
        Background()
    }
}
