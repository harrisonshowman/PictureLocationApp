import SwiftUI
import AVFoundation
import Combine
import UIKit
import CoreLocation
import SwiftData
import PhotosUI

class CameraCoordinator: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {

    @Published var capturedImage: UIImage? = nil
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer? = nil

    override init() {
        super.init()
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(output)
        else { return }
        session.addInput(input)
        session.sessionPreset = .photo
        session.addOutput(output)
        session.commitConfiguration()
    }
    
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.stopRunning()
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// A UIViewControllerRepresentable wrapper for PHPickerViewController to select images from the photo library.
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        
        init(parent: PhotoLibraryPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                parent.dismiss()
                return
            }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            self.parent.onImagePicked(uiImage)
                        }
                        self.parent.dismiss()
                    }
                }
            } else {
                parent.dismiss()
            }
        }
    }
}

struct CustomCameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var coordinator = CameraCoordinator()
    @ObservedObject private var locationManager = LocationManager.shared
    let onPhoto: (UIImage?) -> Void
    
    @State private var didTakePhoto = false
    @State private var isShowingPhotoLibrary = false
    
    @State private var isSessionRunning = false
    
    var body: some View {
        ZStack {
            Background()
            VStack(spacing: 28) {
                Spacer(minLength: 30)
                ZStack {
                    if let image = coordinator.capturedImage, didTakePhoto {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: UIScreen.main.bounds.height * 0.42)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                    } else {
                        CameraPreview(session: coordinator.session)
                            .frame(height: UIScreen.main.bounds.height * 0.42)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                        
                        if !isSessionRunning {
                            Color.black.opacity(0.35)
                                .frame(height: UIScreen.main.bounds.height * 0.42)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                if !didTakePhoto {
                    VStack(spacing: 16) {
                        // Take Photo Button
                        Button(action: {
                            coordinator.takePhoto()
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 72, height: 72)
                                .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 4))
                                .shadow(radius: 4)
                        }
                        .accessibilityLabel("Take Photo")
                        .disabled(!isSessionRunning)
                        
                        // Choose from Library Button
                        Button(action: {
                            isShowingPhotoLibrary = true
                        }) {
                            Text("Choose from Library")
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.65))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.blue.opacity(0.70), lineWidth: 1.8)
                                        )
                                )
                        }
                        .accessibilityLabel("Choose Photo from Library")
                    }
                } else {
                    Button(action: {
                        if let image = coordinator.capturedImage {
                            let lastLocation = locationManager.lastKnownLocation
                            let lat = lastLocation?.coordinate.latitude
                            let lon = lastLocation?.coordinate.longitude
                            let photoItem = PhotoItem(image: image, timestamp: Date(), latitude: lat, longitude: lon)
                            modelContext.insert(photoItem)
                            onPhoto(image)
                        }
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Save Photo")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.black)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.65))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.blue.opacity(0.70), lineWidth: 1.8)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
                        )
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 12)
                    
                    Button(action: {
                        didTakePhoto = false
                        coordinator.capturedImage = nil
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Retake")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.black)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.65))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.blue.opacity(0.70), lineWidth: 1.8)
                                )
                        )
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 6)
                }
                Spacer()
            }
        }
        .onAppear {
            coordinator.startSession()
            
            // Poll session.isRunning for up to 2 seconds every 0.1 seconds
            var attempts = 0
            let maxAttempts = 20
            let interval = 0.1
            
            func checkSessionRunning() {
                if coordinator.session.isRunning {
                    isSessionRunning = true
                } else {
                    attempts += 1
                    if attempts < maxAttempts {
                        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                            checkSessionRunning()
                        }
                    } else {
                        isSessionRunning = false
                    }
                }
            }
            checkSessionRunning()
        }
        .onDisappear {
            coordinator.stopSession()
            isSessionRunning = false
        }
        .onChange(of: coordinator.capturedImage) { image in
            if image != nil { didTakePhoto = true }
        }
        // Photo Library sheet presentation
        .sheet(isPresented: $isShowingPhotoLibrary) {
            PhotoLibraryPicker { image in
                // Save the selected image with location data
                let lastLocation = locationManager.lastKnownLocation
                let lat = lastLocation?.coordinate.latitude
                let lon = lastLocation?.coordinate.longitude
                let photoItem = PhotoItem(image: image, timestamp: Date(), latitude: lat, longitude: lon)
                modelContext.insert(photoItem)
                onPhoto(image)
                dismiss()
                isShowingPhotoLibrary = false
            }
        }
    }
}

// Usage: Present CustomCameraView { image in ... } in a sheet where needed.

