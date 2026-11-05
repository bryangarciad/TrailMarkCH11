import SwiftUI
import AVFoundation
import UIKit
import UniformTypeIdentifiers

struct VideoCaptureView: UIViewControllerRepresentable {
    let onCapture: (URL, TimeInterval) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // The simulator does not have camera so we add a fallback to the image library
        picker.sourceType =
            UIImagePickerController.isSourceTypeAvailable(.camera) ?
            .camera : .photoLibrary
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeMedium
        
        if picker.sourceType == .camera {
            picker.cameraCaptureMode = .video
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (URL, TimeInterval) -> Void
        
        init(onCapture: @escaping (URL, TimeInterval) -> Void) {
            self.onCapture = onCapture
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            guard let url = info[.mediaURL] as? URL else { return }
            let duration = CMTimeGetSeconds(AVURLAsset(url: url).duration)
            onCapture(url, duration.isFinite ? duration : 0)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    
}
