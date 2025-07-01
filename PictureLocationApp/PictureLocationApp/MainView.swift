import SwiftUI
import PhotosUI
import MapKit
import CoreLocation
import SwiftData
import AVFoundation
import Photos
import Combine

struct MainView: View {
    @StateObject private var mapCoordinator = MapNavigationCoordinator()
    @State private var selectedTab: MapNavigationCoordinator.Tab = .photos

    var body: some View {
        ZStack {
            Background()
            TabView(selection: $selectedTab) {
                ZStack {
                    Background()
                    PhotoListView()
                }
                .tabItem {
                    Label("Photos", systemImage: "photo.on.rectangle")
                }
                .tag(MapNavigationCoordinator.Tab.photos)

                ZStack {
                    Background()
                    PhotoMapView()
                }
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(MapNavigationCoordinator.Tab.map)
            }
            .background(Color.clear)
            .environmentObject(mapCoordinator)
            .onAppear { selectedTab = mapCoordinator.selectedTab }
            .onChange(of: mapCoordinator.selectedTab) { newValue in
                selectedTab = newValue
            }
            .onChange(of: selectedTab) { newValue in
                mapCoordinator.selectedTab = newValue
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
