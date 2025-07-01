import SwiftUI
import MapKit
import UniformTypeIdentifiers

struct TransferableImage: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { transferableImage in
            transferableImage.image.pngData() ?? Data()
        }
        .suggestedFileName("SharedPhoto.png")
    }
}

struct PhotoInfoView: View {
    let photo: PhotoItem
    @EnvironmentObject private var mapCoordinator: MapNavigationCoordinator
    
    private func formattedShareMessage() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: photo.timestamp)
        var locationString = "Location: Unknown"
        if let lat = photo.latitude, let lon = photo.longitude {
            locationString = String(format: "Location: %.5f, %.5f", lat, lon)
        }
        return "Sent with PictureLocationApp:\nDate: \(dateString)\n\(locationString)"
    }
    
    var body: some View {
        ZStack {
            Background()
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
                
                VStack(spacing: 12) {
                    if let image = photo.uiImage {
                        ShareLink(item: TransferableImage(image: image), message: Text(formattedShareMessage()), preview: SharePreview("Photo", image: Image(uiImage: image))) {
                            Label("Share Photo", systemImage: "square.and.arrow.up")
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(.white.opacity(0.65))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.70), lineWidth: 1.8)
                                )
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    Button {
                        if let lat = photo.latitude, let lon = photo.longitude {
                            mapCoordinator.showPhotoOnMap(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        }
                    } label: {
                        Label("View on Map", systemImage: "map")
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(.white.opacity(0.65))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.70), lineWidth: 1.8)
                            )
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(photo.latitude == nil || photo.longitude == nil)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Photo Details")
        }
    }
}

struct MapView: View {
    let coordinate: CLLocationCoordinate2D
    @State private var region: MKCoordinateRegion
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        _region = State(initialValue: MKCoordinateRegion(center: coordinate,
                                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [AnnotatedItem(coordinate: coordinate)]) { item in
            MapMarker(coordinate: item.coordinate)
        }
    }
    
    struct AnnotatedItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
}

#Preview {
    // Provide a dummy PhotoItem for preview
    let dummy = PhotoItem(image: UIImage(systemName: "photo") ?? UIImage(), timestamp: Date(), latitude: 37.77, longitude: -122.42)
    PhotoInfoView(photo: dummy)
        .environmentObject(MapNavigationCoordinator())
}
