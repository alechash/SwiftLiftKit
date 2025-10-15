import UIKit

public enum SwiftLiftKit {
    /// Programmatic subject cut-out from an existing UIImage (returns image with transparent bg).
    public static func liftSubject(from image: UIImage) async throws -> UIImage {
        if let result = await SubjectLifter.cutout(image: image) {
            return result
        }
        throw SubjectLiftError.noMaskProduced
    }

    /// Present the camera, capture a photo, then return the subject cut-out.
    /// - Parameters:
    ///   - presenter: a UIViewController to present from (e.g., topmost vc)
    ///   - preferOriginalIfNoMask: if true, returns the original photo when mask fails
    public static func captureAndLift(presenter: UIViewController,
                                      preferOriginalIfNoMask: Bool = true) async throws -> UIImage {
        let photo = try await CameraCapture.capture(from: presenter)
        if let cut = await SubjectLifter.cutout(image: photo) {
            return cut
        }
        if preferOriginalIfNoMask { return photo }
        throw SubjectLiftError.noMaskProduced
    }
}

public enum SubjectLiftError: Error {
    case noMaskProduced
    case cameraUnavailable
    case cameraDenied
    case presentationFailed
}
