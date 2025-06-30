import SwiftUI
import SwiftData

struct ImageInfoView: View {
    @Query(sort: [SortDescriptor(\PhotoItem.timestamp, order: .reverse)]) private var photos: [PhotoItem]
    @State private var selectedPhoto: PhotoItem?
    
    var body: some View {
        NavigationStack {
            List(photos) { photo in
                HStack {
                    if let image = photo.uiImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                selectedPhoto = photo
                            }
                    }
                    VStack(alignment: .leading) {
                        Text(photo.timestamp, style: .date)
                        if let lat = photo.latitude, let lon = photo.longitude {
                            Text(String(format: "Lat: %.4f", lat))
                            Text(String(format: "Lon: %.4f", lon))
                        }
                    }
                }
            }
            .navigationTitle("Photo Info List")
            .sheet(item: $selectedPhoto) { photo in
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
            }
        }
    }
}

#Preview {
    ImageInfoView()
        .modelContainer(for: PhotoItem.self, inMemory: true)
}
