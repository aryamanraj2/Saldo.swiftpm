import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import os.log

@available(iOS 17.0, *)
actor GrailImageMaskingService {
    enum Error: LocalizedError, Equatable {
        case noSubjectDetected
        case maskGenerationFailed
        case renderFailed
        case unsupportedEnvironment

        var errorDescription: String? {
            switch self {
            case .noSubjectDetected:
                return "No clear foreground subject was detected."
            case .maskGenerationFailed:
                return "Failed to generate a subject mask."
            case .renderFailed:
                return "Failed to render masked image."
            case .unsupportedEnvironment:
                return "Background masking is unavailable in this environment."
            }
        }
    }

    private let logger = Logger(subsystem: "aryaman.Saldo", category: "grail-masking")
    private let ciContext: CIContext
    private let maxDimension: CGFloat = 2048

    init() {
        ciContext = CIContext(options: [
            .cacheIntermediates: false,
            .useSoftwareRenderer: false
        ])
    }

    func maskLargestForegroundSubject(from image: UIImage) async throws -> UIImage {
#if targetEnvironment(simulator)
        throw Error.unsupportedEnvironment
#else
        let normalized = normalizeOrientation(image)
        let optimized = downsampleIfNeeded(normalized)

        guard let ciImage = CIImage(image: optimized) else {
            throw Error.renderFailed
        }

        let analysisStart = Date()
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            logger.error("Vision request failed: \(error.localizedDescription)")
            throw Error.maskGenerationFailed
        }
        let analysisMs = Date().timeIntervalSince(analysisStart) * 1000

        guard let observation = request.results?.first,
              !observation.allInstances.isEmpty else {
            throw Error.noSubjectDetected
        }

        let maskStart = Date()
        let largestInstanceID = try largestInstanceID(from: observation, handler: handler)
        let maskBuffer: CVPixelBuffer
        do {
            maskBuffer = try observation.generateScaledMaskForImage(
                forInstances: IndexSet(integer: largestInstanceID),
                from: handler
            )
        } catch {
            logger.error("Scaled mask generation failed: \(error.localizedDescription)")
            throw Error.maskGenerationFailed
        }
        let maskMs = Date().timeIntervalSince(maskStart) * 1000

        let renderStart = Date()
        let maskImage = CIImage(cvPixelBuffer: maskBuffer)
        let filter = CIFilter.blendWithMask()
        filter.inputImage = ciImage
        filter.maskImage = maskImage
        filter.backgroundImage = CIImage.empty()

        guard let outputImage = filter.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            throw Error.renderFailed
        }
        let renderMs = Date().timeIntervalSince(renderStart) * 1000

        logger.debug("Mask timings (ms) analysis=\(Int(analysisMs)) mask=\(Int(maskMs)) render=\(Int(renderMs))")

        return UIImage(cgImage: cgImage, scale: optimized.scale, orientation: .up)
#endif
    }

    private func largestInstanceID(
        from observation: VNInstanceMaskObservation,
        handler: VNImageRequestHandler
    ) throws -> Int {
        var bestInstanceID: Int?
        var bestArea: Int = 0

        for instanceID in observation.allInstances {
            let maskBuffer: CVPixelBuffer
            do {
                maskBuffer = try observation.generateScaledMaskForImage(
                    forInstances: IndexSet(integer: instanceID),
                    from: handler
                )
            } catch {
                continue
            }

            let area = foregroundPixelCount(in: maskBuffer)
            if area > bestArea {
                bestArea = area
                bestInstanceID = instanceID
            }
        }

        guard let bestInstanceID else {
            throw Error.noSubjectDetected
        }

        return bestInstanceID
    }

    private func foregroundPixelCount(in pixelBuffer: CVPixelBuffer) -> Int {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return 0
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixels = baseAddress.assumingMemoryBound(to: UInt8.self)

        var count = 0
        for y in 0..<height {
            let row = pixels.advanced(by: y * bytesPerRow)
            for x in 0..<width where row[x] > 127 {
                count += 1
            }
        }

        return count
    }

    private func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private func downsampleIfNeeded(_ image: UIImage) -> UIImage {
        let currentMax = max(image.size.width, image.size.height)
        guard currentMax > maxDimension else {
            return image
        }

        let scaleFactor = maxDimension / currentMax
        let newSize = CGSize(
            width: image.size.width * scaleFactor,
            height: image.size.height * scaleFactor
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
