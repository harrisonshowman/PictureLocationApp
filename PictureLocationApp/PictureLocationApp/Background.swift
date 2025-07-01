import SwiftUI

struct Background: View {
    var body: some View {
        LinearGradient(
            colors: [.red, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Background()
    }
}
