import SwiftUI
import PhotosUI
import MapKit
import CoreLocation
import SwiftData
import AVFoundation
import Photos

struct MainView: View {
    var body: some View {
        ZStack {
            TabView {
                PhotoListView()
                    .tabItem {
                        Label("Photos", systemImage: "photo.on.rectangle")
                    }

                PhotoMapView()
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
            }
            PermissionHelper()
        }
    }

    private struct PermissionHelper: View {
        var body: some View {
            Color.clear
                .onAppear {
                    // Location
                    LocationManager.shared.requestLocation()
                    // Camera
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        // You can handle the result here if needed
                    }
                    // Photo Library
                    PHPhotoLibrary.requestAuthorization { status in
                        // You can handle the result here if needed
                    }
                }
        }
    }
}

#Preview {
    MainView()
}
