import Foundation
import MapKit
import Combine

class MapNavigationCoordinator: ObservableObject {
    @Published var selectedTab: Tab = .photos
    @Published var zoomToCoordinate: CLLocationCoordinate2D? = nil
    
    enum Tab {
        case photos, map
    }
    
    func showPhotoOnMap(coordinate: CLLocationCoordinate2D) {
        selectedTab = .map
        zoomToCoordinate = coordinate
    }
    
    func clearZoomRequest() {
        zoomToCoordinate = nil
    }
}
