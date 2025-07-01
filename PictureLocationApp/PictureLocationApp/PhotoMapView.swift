import SwiftUI
import MapKit
import SwiftData
import Combine
import CoreLocation

// MARK: - Hashable conformance for CLLocationCoordinate2D
extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - Identifiable wrapper for navigation by city
struct CityDestination: Identifiable, Hashable {
    let city: String
    var id: String { city }
}

// MARK: - Identifiable annotation type
struct IdentifiablePhotoLocation: Identifiable, Equatable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let photo: PhotoItem
    static func == (lhs: IdentifiablePhotoLocation, rhs: IdentifiablePhotoLocation) -> Bool {
        lhs.id == rhs.id
    }
}

struct PhotoMapView: View {
    @EnvironmentObject private var mapCoordinator: MapNavigationCoordinator
    @State private var zoomCancellable: AnyCancellable? = nil

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedPhoto: PhotoItem? = nil
    @State private var selectedCity: CityDestination? = nil

    @Query(sort: [SortDescriptor(\PhotoItem.timestamp, order: .reverse)]) private var photos: [PhotoItem]

    @State private var locationCounts: [String: Int] = [:]
    @State private var coordinateToCity: [CLLocationCoordinate2D: String] = [:]
    @State private var annotationItems: [IdentifiablePhotoLocation] = []
    @State private var sortedCities: [(String, Int)] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Background()
                
                VStack {
                    Text("Map")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 8)

                    Map(coordinateRegion: $region, annotationItems: annotationItems) { (item: IdentifiablePhotoLocation) in
                        MapAnnotation(coordinate: item.coordinate) {
                            mapMarkerView(for: item)
                        }
                    }
                    .frame(height: 300)

                    if !sortedCities.isEmpty {
                        cityListView
                            .padding(.vertical)
                    }

                    Text("Your photo locations will appear here.")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .onAppear {
                    recalculateAll()
                    zoomCancellable = mapCoordinator.$zoomToCoordinate.sink { coord in
                        guard let coord else { return }
                        region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        if let photo = photos.first(where: { $0.latitude == coord.latitude && $0.longitude == coord.longitude }) {
                            selectedPhoto = photo
                        }
                        mapCoordinator.clearZoomRequest()
                    }
                }
                .onDisappear {
                    zoomCancellable?.cancel()
                }
                .onChange(of: photos) { _ in
                    recalculateAll()
                }
                .sheet(item: $selectedPhoto) { photo in
                    photoSheetView(photo: photo)
                }
            }

        }
        .navigationDestination(item: $selectedCity) { cityDest in
            PhotoListView(city: cityDest.city)
        }
    }

    private func recalculateAll() {
        // Build annotation items
        var builtAnnotationItems: [IdentifiablePhotoLocation] = []
        for photo in photos {
            if let lat = photo.latitude, let lon = photo.longitude {
                builtAnnotationItems.append(IdentifiablePhotoLocation(
                    id: photo.id,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    photo: photo
                ))
            }
        }
        annotationItems = builtAnnotationItems

        // Region
        if let computed = regionToFitAll(annotationItems) {
            region = computed
        }

        // Geocode and city counts
        reverseGeocodeLocationsIfNeeded(annotationItems)
    }

    // MARK: - Map marker view for each annotation
    @ViewBuilder
    private func mapMarkerView(for item: IdentifiablePhotoLocation) -> some View {
        if let uiImage = item.photo.uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(radius: 5)
                .onTapGesture { selectedPhoto = item.photo }
        } else {
            Circle()
                .fill(Color.gray)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "photo").foregroundColor(.white))
                .onTapGesture { selectedPhoto = item.photo }
        }
    }

    // MARK: - City list view as buttons
    @ViewBuilder
    private var cityListView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(sortedCities, id: \.0) { city, count in
                Button(action: {
                    selectedCity = CityDestination(city: city)
                }) {
                    Text("\(city): \(count)")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(.black)
                }
                .background(.white.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.70), lineWidth: 1.8)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Sheet for photo details
    @ViewBuilder
    private func photoSheetView(photo: PhotoItem) -> some View {
        ZStack {
            Background()
            VStack(spacing: 20) {
                if let uiImage = photo.uiImage {
                    Image(uiImage: uiImage)
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

    // MARK: - Fit region to all annotation items
    private func regionToFitAll(_ items: [IdentifiablePhotoLocation]) -> MKCoordinateRegion? {
        guard !items.isEmpty else { return nil }
        let coordinates = items.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        let latDelta = (maxLat - minLat) * 1.3 + 0.005
        let lonDelta = (maxLon - minLon) * 1.3 + 0.005
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: max(latDelta, 0.01), longitudeDelta: max(lonDelta, 0.01)))
    }

    // MARK: - Reverse geocode logic
    private func reverseGeocodeLocationsIfNeeded(_ items: [IdentifiablePhotoLocation]) {
        let geocoder = CLGeocoder()
        let unknown = "Unknown Location"
        var newCoordinateToCity = coordinateToCity
        let unresolvedCoordinates = items.map(\.coordinate).filter { newCoordinateToCity[$0] == nil }
        for coordinate in unresolvedCoordinates {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                var cityName = unknown
                if let firstPlacemark = placemarks?.first {
                    if let locality = firstPlacemark.locality, !locality.isEmpty {
                        cityName = locality
                    } else if let name = firstPlacemark.name, !name.isEmpty {
                        cityName = name
                    }
                }
                DispatchQueue.main.async {
                    newCoordinateToCity[coordinate] = cityName
                    coordinateToCity = newCoordinateToCity
                    recalcLocationCounts(items: items)
                }
            }
        }
        recalcLocationCounts(items: items)
    }

    // MARK: - Count city occurrences
    private func recalcLocationCounts(items: [IdentifiablePhotoLocation]) {
        let cityNames = items.map { coordinateToCity[$0.coordinate] ?? "Unknown Location" }
        var counts: [String: Int] = [:]
        for city in cityNames {
            counts[city, default: 0] += 1
        }
        locationCounts = counts
        sortedCities = counts.sorted(by: { $0.key < $1.key })
    }
}

#Preview {
    PhotoMapView()
        .environmentObject(MapNavigationCoordinator())
}

