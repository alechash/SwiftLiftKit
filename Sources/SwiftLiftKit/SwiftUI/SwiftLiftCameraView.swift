//
//  SwiftLiftCameraView.swift
//  SwiftLiftKit
//
//  Created by Jude Wilson on 10/15/25.
//

import SwiftUI

/// SwiftUI convenience: presents the camera and returns the cut-out.
public struct SubjectLiftCameraView: View {
    @Environment(\.dismiss) private var dismiss
    public var onComplete: (UIImage) -> Void

    public init(onComplete: @escaping (UIImage) -> Void) { self.onComplete = onComplete }

    public var body: some View {
        _SubjectLiftCameraHost(onComplete: onComplete)
            .ignoresSafeArea()
    }
}

private struct _SubjectLiftCameraHost: UIViewControllerRepresentable {
    var onComplete: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        Task { @MainActor in
            do {
                let img = try await SwiftLiftKit.captureAndLift(presenter: vc)
                onComplete(img)
            } catch {
                // you can present an alert here if desired
            }
            context.coordinator.dismiss(vc)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coord { Coord() }
    final class Coord {
        func dismiss(_ vc: UIViewController) {
            if let presenting = vc.presentingViewController {
                presenting.dismiss(animated: true)
            }
        }
    }
}
