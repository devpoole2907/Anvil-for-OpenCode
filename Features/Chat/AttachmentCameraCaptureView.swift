import SwiftUI

#if os(iOS)
import UIKit

struct AttachmentCameraCaptureView: UIViewControllerRepresentable {
    var onCapture: (PendingAttachment) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

extension AttachmentCameraCaptureView {
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (PendingAttachment) -> Void
        private let onCancel: () -> Void

        init(
            onCapture: @escaping (PendingAttachment) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 0.9)
            else {
                onCancel()
                return
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            let filename = "Photo-\(formatter.string(from: .now)).jpg"
            onCapture(.fromData(data, filename: filename, mediaType: "image/jpeg"))
        }
    }
}
#endif
