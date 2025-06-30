import SwiftUI
import MapKit
import SwiftData

struct PhotoMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @Query<PhotoItem>(sort: [SortDescriptor(\PhotoItem.timestamp, order: .reverse)]) private var photos: [PhotoItem]

    var body: some View {
        let annotationItems: [IdentifiablePhotoLocation] = photos.compactMap { photo in
            guard let lat = photo.latitude, let lon = photo.longitude else { return nil }
            return IdentifiablePhotoLocation(id: photo.id, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), photo: photo)
        }
        
        VStack {
            Map(coordinateRegion: $region, annotationItems: annotationItems) { (item: IdentifiablePhotoLocation) in
                MapMarker(coordinate: item.coordinate, tint: .blue)
            }
            .frame(height: 300)
            Text("Your photo locations will appear here.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    struct IdentifiablePhotoLocation: Identifiable {
        let id: UUID
        let coordinate: CLLocationCoordinate2D
        let photo: PhotoItem
    }
}

#Preview {
    PhotoMapView()
}
