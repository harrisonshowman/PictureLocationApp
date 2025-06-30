import SwiftUI
import PhotosUI
import MapKit
import CoreLocation
import SwiftData

struct MainView: View {
    var body: some View {
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
    }
}

#Preview {
    MainView()
}
