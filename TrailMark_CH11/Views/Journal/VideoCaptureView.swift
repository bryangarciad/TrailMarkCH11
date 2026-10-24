import SwiftUI
import AVFoundation
import UIKit
import UniformTypeIdentifiers

// This view needs to pull the camera screen in the app
// A lot of apple screens are build in UIKit
//
struct VideoCaptureView: UIViewControllerRepresentable {
    let onCapture: (URL, TimeInterval) -> Void
    
    // Create The Actual UI View (Cammera)
    //
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // The simulator does not have a camera so we show the photo library to select
        // an image as fallback scenario
        picker.sourceType =
            UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeMedium
        
        if picker.sourceType == .camera {
            picker.cameraCaptureMode = .video
        }
        
        if #available(iOS 16.0, *) {
            picker.sourceType = .photoLibrary
            picker.cameraCaptureMode = .photo
        }
        
        return picker
    }
    
    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) { }
    
    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (URL, TimeInterval) -> Void

        init(onCapture: @escaping (URL, TimeInterval) -> Void) {
            self.onCapture = onCapture
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)
            guard let url = info[.mediaURL] as? URL else { return }
            let asset = AVURLAsset(url: url)
            if #available(iOS 16.0, *) {
                Task {
                    let seconds: TimeInterval
                    do {
                        let duration = try await asset.load(.duration)
                        let value = CMTimeGetSeconds(duration)
                        seconds = value.isFinite ? value : 0
                    } catch {
                        seconds = 0
                    }
                    self.onCapture(url, seconds)
                }
            } else {
                asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                    var seconds: TimeInterval = 0
                    var error: NSError?
                    let status = asset.statusOfValue(forKey: "duration", error: &error)
                    switch status {
                    case .loaded:
                        let duration = asset.duration
                        let value = CMTimeGetSeconds(duration)
                        seconds = value.isFinite ? value : 0
                    default:
                        seconds = 0
                    }
                    DispatchQueue.main.async {
                        self.onCapture(url, seconds)
                    }
                }
            }
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController
        ) {
            picker.dismiss(animated: true)
        }
        
        
    }
    
}

