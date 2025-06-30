import SwiftData
import UIKit

@Model class PhotoItem: Identifiable {
    let id: UUID
    var imageData: Data?
    var timestamp: Date
    var latitude: Double?
    var longitude: Double?
    
    var uiImage: UIImage? {
        get {
            guard let imageData = imageData else { return nil }
            return UIImage(data: imageData)
        }
        set {
            imageData = newValue?.jpegData(compressionQuality: 0.9)
        }
    }
    
    init(id: UUID = UUID(), image: UIImage, timestamp: Date = Date(), latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.imageData = image.jpegData(compressionQuality: 0.9)
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
    }
}
