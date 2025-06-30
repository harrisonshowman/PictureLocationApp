import SwiftUI

struct PhotoListView: View {
    var body: some View {
        VStack {
            Text("Photo List")
                .font(.largeTitle)
            Text("Your photos will appear here.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    PhotoListView()
}
