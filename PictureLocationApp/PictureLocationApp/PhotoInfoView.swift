import SwiftUI

struct PhotoInfoView: View {
    let photo: PhotoItem
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = photo.uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 350, maxHeight: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Text(photo.timestamp, style: .date)
                .font(.headline)
            if let lat = photo.latitude, let lon = photo.longitude {
                Text(String(format: "Latitude: %.6f", lat))
                Text(String(format: "Longitude: %.6f", lon))
            } else {
                Text("No location data available.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Photo Details")
    }
}

#Preview {
    // Provide a dummy PhotoItem for preview
    let dummy = PhotoItem(image: UIImage(systemName: "photo") ?? UIImage(), timestamp: Date(), latitude: 37.77, longitude: -122.42)
    PhotoInfoView(photo: dummy)
}
