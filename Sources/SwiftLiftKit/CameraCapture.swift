//
//  CameraCapture.swift
//  SwiftLiftKit
//
//  Created by Jude Wilson on 10/15/25.
//

import UIKit
import AVFoundation

final class CameraCapture: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    // Concurrency-safe association key
    private static let assocKey: UnsafeRawPointer = {
        UnsafeRawPointer(bitPattern: "CameraCaptureAssocKey".hashValue)!
    }()

    private var continuation: CheckedContinuation<UIImage, Error>?
    private weak var presenter: UIViewController?

    static func capture(from presenter: UIViewController) async throws -> UIImage {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            throw SubjectLiftError.cameraUnavailable
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else { throw SubjectLiftError.cameraDenied }
        } else if status != .authorized {
            throw SubjectLiftError.cameraDenied
        }

        return try await withCheckedThrowingContinuation { cont in
            let capture = CameraCapture()
            capture.presenter = presenter
            capture.continuation = cont

            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.modalPresentationStyle = .fullScreen
            picker.delegate = capture

            // retain the delegate object using the static immutable key
            objc_setAssociatedObject(picker, CameraCapture.assocKey, capture, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            presenter.present(picker, animated: true)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.continuation?.resume(throwing: SubjectLiftError.presentationFailed)
            self?.cleanup(picker)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            if let image {
                self?.continuation?.resume(returning: image)
            } else {
                self?.continuation?.resume(throwing: SubjectLiftError.presentationFailed)
            }
            self?.cleanup(picker)
        }
    }

    private func cleanup(_ picker: UIImagePickerController) {
        objc_setAssociatedObject(picker, CameraCapture.assocKey, nil, .OBJC_ASSOCIATION_ASSIGN)
    }
}
