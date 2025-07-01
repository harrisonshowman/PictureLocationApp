import SwiftUI
import SwiftData
import CoreLocation

struct PhotoListView: View {
    @Query(sort: [SortDescriptor(\PhotoItem.timestamp, order: .reverse)]) private var photos: [PhotoItem]
    @State private var isAddPhotoPresented = false

    @State private var showingSourceDialog = false
    @State private var showingCameraPicker = false
    @State private var showingImagePicker = false
    @State private var isEditing = false
    @State private var showAddOptions = false
    @Environment(\.modelContext) private var modelContext
    
    @ObservedObject var locationManager = LocationManager.shared
    
    @Namespace private var addButtonNamespace
    @State private var scrollProxy: ScrollViewProxy? = nil
    var city: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Background()
                VStack(alignment: .center, spacing: 0) {
                    Text("Photos")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Your recent memories appear below.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 18)
                    ScrollView {
                        ScrollViewReader { proxy in
                            LazyVStack {
                                photoRows
                                
                                if showAddOptions {
                                    VStack(spacing: 0) {
                                        Button {
                                            showAddOptions = false
                                            showingCameraPicker = true
                                        } label: {
                                            Label("Camera", systemImage: "camera")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .foregroundColor(.black)
                                        }
                                        Button {
                                            showAddOptions = false
                                            showingImagePicker = true
                                        } label: {
                                            Label("Photo Library", systemImage: "photo")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.white.opacity(0.65))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.blue.opacity(0.70), lineWidth: 1.8)
                                            )
                                    )
                                    .padding(.bottom, 8)
                                    .frame(maxWidth: 260)
                                    .id("addOptions")
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                                
                                Button {
                                    withAnimation {
                                        showAddOptions.toggle()
                                        if !showAddOptions { return }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                            scrollProxy?.scrollTo("addOptions", anchor: .bottom)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text("Add Photo")
                                    }
                                    .foregroundColor(.black)
                                }
                                .id("addButton")
                                .padding(12)
                                .frame(maxWidth: 260)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.65))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.blue.opacity(0.70), lineWidth: 1.8)
                                        )
                                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
                                )
                                .padding(.vertical, 12)
                            }
                            .onAppear {
                                scrollProxy = proxy
                            }
                        }
                    }
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 60)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isEditing.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil")
                                .imageScale(.large)
                            Text(isEditing ? "Done" : "Edit")
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: 120)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCameraPicker) {
            ZStack {
                Background()
                CustomCameraView { image in
                    guard let image = image else { return }
                    showingCameraPicker = false
                    let lastLocation = locationManager.lastKnownLocation
                    let lat = lastLocation?.coordinate.latitude
                    let lon = lastLocation?.coordinate.longitude
                    let newPhoto = PhotoItem(image: image, timestamp: Date(), latitude: lat, longitude: lon)
                    modelContext.insert(newPhoto)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ZStack {
                Background()
                PhotoLibraryPicker { image in
                    showingImagePicker = false
                    let lastLocation = locationManager.lastKnownLocation
                    let lat = lastLocation?.coordinate.latitude
                    let lon = lastLocation?.coordinate.longitude
                    let newPhoto = PhotoItem(image: image, timestamp: Date(), latitude: lat, longitude: lon)
                    modelContext.insert(newPhoto)
                }
            }
        }
    }
    
    private var photoRows: some View {
        ForEach(photos, id: \.id) { photo in
            ZStack(alignment: .topTrailing) {
                NavigationLink(destination: PhotoInfoView(photo: photo)) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(photo.timestamp, style: .date)
                                .font(.headline)
                                .foregroundColor(.black)
                            if let lat = photo.latitude, let lon = photo.longitude {
                                Text(String(format: "Lat: %.4f", lat))
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.7))
                                Text(String(format: "Lon: %.4f", lon))
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                        }
                        Spacer()
                        if let uiImage = photo.uiImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray.opacity(0.6))
                                .background(Color.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.6))
                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
                    )
                    .padding(.horizontal, 18)
                    .padding(.vertical, 4)
                }
                .disabled(isEditing)
                
                if isEditing {
                    Button {
                        delete(photo: photo)
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .imageScale(.large)
                            .padding(8)
                    }
                }
            }
        }
    }
    
    private func delete(photo: PhotoItem) {
        modelContext.delete(photo)
    }
}
