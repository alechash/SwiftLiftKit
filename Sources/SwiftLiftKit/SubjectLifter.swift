//
//  SubjectLifter.swift
//  SwiftLiftKit
//
//  Created by Jude Wilson on 10/15/25.
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO

enum SubjectLifter {
    static func cutout(image uiImage: UIImage) async -> UIImage? {
        // 1) Normalize & apply orientation so pixels are upright RGBA8 sRGB
        guard let cg = makeUprightRGBA8(uiImage) else { return nil }
        // 2) Foreground mask (iOS 17+) → fallback to person segmentation
        if #available(iOS 17.0, *) {
            if let cut = await foregroundInstanceCutout(from: cg, scale: uiImage.scale) {
                return cut
            }
        }
        if let cut = await personOnlyCutout(from: cg, scale: uiImage.scale) {
            return cut
        }
        return nil
    }

    @available(iOS 17.0, *)
    private static func foregroundInstanceCutout(from cg: CGImage, scale: CGFloat) async -> UIImage? {
        let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
        let req = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([req])
            guard let obs = req.results?.first else { return nil }
            let pxMask = try obs.generateScaledMaskForImage(forInstances: obs.allInstances, from: handler)
            return blend(original: cg, maskPixelBuffer: pxMask, scale: scale)
        } catch {
            return nil
        }
    }

    private static func personOnlyCutout(from cg: CGImage, scale: CGFloat) async -> UIImage? {
        let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
        let req = VNGeneratePersonSegmentationRequest()
        req.qualityLevel = .accurate
        req.outputPixelFormat = kCVPixelFormatType_OneComponent8
        do {
            try handler.perform([req])
            guard let px = req.results?.first?.pixelBuffer else { return nil }
            return blend(original: cg, maskPixelBuffer: px, scale: scale)
        } catch {
            return nil
        }
    }

    // MARK: - CI blend
    private static func blend(original cg: CGImage, maskPixelBuffer px: CVPixelBuffer, scale: CGFloat) -> UIImage? {
        let ciInput = CIImage(cgImage: cg) // already upright RGBA8
        let ciMask  = CIImage(cvPixelBuffer: px)
        let bg      = CIImage(color: .clear).cropped(to: ciInput.extent)

        let f = CIFilter.blendWithMask()
        f.inputImage = ciInput
        f.maskImage  = ciMask
        f.backgroundImage = bg
        guard let out = f.outputImage else { return nil }

        let ctx = CIContext()
        guard let cgOut = ctx.createCGImage(out, from: out.extent) else { return nil }
        return UIImage(cgImage: cgOut, scale: scale, orientation: .up)
    }

    // MARK: - Image normalization
    private static func normalizedRGBA8(_ cg: CGImage) -> CGImage? {
        let w = cg.width, h = cg.height
        guard let cs = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let info = CGBitmapInfo.byteOrder32Little.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue))
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: info.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage()
    }

    /// Draws UIImage applying orientation, then normalizes to RGBA8 sRGB.
    fileprivate static func makeUprightRGBA8(_ ui: UIImage) -> CGImage? {
        if let cg = ui.cgImage, ui.imageOrientation == .up {
            return normalizedRGBA8(cg)
        }
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = ui.scale
        fmt.opaque = false
        let rendered = UIGraphicsImageRenderer(size: ui.size, format: fmt).image { _ in
            ui.draw(in: CGRect(origin: .zero, size: ui.size))
        }
        guard let renderedCG = rendered.cgImage else { return nil }
        return normalizedRGBA8(renderedCG)
    }
}
