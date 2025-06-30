import SwiftUI
import CoreLocation
import SwiftData

struct PhotoListView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @Query(sort: [SortDescriptor(\PhotoItem.timestamp, order: .reverse)]) private var photos: [PhotoItem]
    @State private var showingImagePicker = false
    @State private var showingCameraPicker = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            List {
                ForEach(photos, id: \.id) { photo in
                    if let image = photo.uiImage {
                        NavigationLink(destination: PhotoInfoView(photo: photo)) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 60)
                        }
                    }
                }
                .onDelete(perform: deletePhoto)
            }
            .background(Color.clear)
            .navigationBarTitle("Photos")
            .navigationBarItems(
                leading: Button("Camera") {
                    showingCameraPicker = true
                },
                trailing: Button("Gallery") {
                    showingImagePicker = true
                }
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { image in
                    guard let image = image else { return }
                    let lastLocation = locationManager.lastKnownLocation
                    let lat = lastLocation?.coordinate.latitude
                    let lon = lastLocation?.coordinate.longitude
                    let newPhoto = PhotoItem(image: image, latitude: lat, longitude: lon)
                    modelContext.insert(newPhoto)
                }
            }
            .sheet(isPresented: $showingCameraPicker) {
                CameraPicker { image in
                    guard let image = image else { return }
                    let lastLocation = locationManager.lastKnownLocation
                    let lat = lastLocation?.coordinate.latitude
                    let lon = lastLocation?.coordinate.longitude
                    let newPhoto = PhotoItem(image: image, latitude: lat, longitude: lon)
                    modelContext.insert(newPhoto)
                }
            }
        }
        .background(Color.clear)
    }
    
    private func deletePhoto(at offsets: IndexSet) {
        for index in offsets {
            let photo = photos[index]
            modelContext.delete(photo)
        }
    }
}
