import SwiftUI
import UIKit

@MainActor
@Observable
final class GrailStore {
    private(set) var grails: [GrailItem] = []

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func load() async {
        do {
            let loaded = try loadGrails()
            grails = loaded.sorted(by: { $0.createdAt > $1.createdAt })
            try normalizeStoredImagesIfNeeded()
            try cleanupOrphanedImages(referencedBy: grails)
        } catch {
            print("⚠️ [GrailStore] Failed to load grails: \(error.localizedDescription)")
            grails = []
        }
    }

    func add(grail: GrailItem, maskedImage: UIImage?) async {
        var storedGrail = grail

        do {
            try ensureStorageDirectories()

            if let maskedImage, let imageData = maskedImage.pngData() {
                let filename = "\(storedGrail.id.uuidString).png"
                let imageURL = imagesDirectoryURL().appendingPathComponent(filename, isDirectory: false)
                try imageData.write(to: imageURL, options: .atomic)
                storedGrail.maskedImageFilename = filename
            } else {
                storedGrail.maskedImageFilename = nil
            }

            grails.insert(storedGrail, at: 0)
            try persistGrails()
            try cleanupOrphanedImages(referencedBy: grails)
        } catch {
            print("⚠️ [GrailStore] Failed to add grail: \(error.localizedDescription)")
        }
    }

    func previewItems(limit: Int) -> [GrailPreviewItem] {
        let recent = grails
            .sorted(by: { $0.createdAt > $1.createdAt })
            .prefix(limit)

        return recent.map { grail in
            GrailPreviewItem(
                id: grail.id,
                name: grail.name,
                category: grail.category,
                image: loadImage(for: grail),
                targetAmount: grail.targetAmount,
                currentAmount: grail.currentAmount,
                currency: grail.currency
            )
        }
    }

    private func loadGrails() throws -> [GrailItem] {
        try ensureStorageDirectories()
        let metadataURL = metadataFileURL()

        guard fileManager.fileExists(atPath: metadataURL.path) else {
            return []
        }

        let data = try Data(contentsOf: metadataURL)
        return try decoder.decode([GrailItem].self, from: data)
    }

    private func persistGrails() throws {
        try ensureStorageDirectories()
        let metadataURL = metadataFileURL()
        let data = try encoder.encode(grails)
        try data.write(to: metadataURL, options: .atomic)
    }

    private func loadImage(for grail: GrailItem) -> UIImage? {
        guard let filename = grail.maskedImageFilename else {
            return nil
        }

        let imageURL = imagesDirectoryURL().appendingPathComponent(filename, isDirectory: false)
        return UIImage(contentsOfFile: imageURL.path)
    }

    private func cleanupOrphanedImages(referencedBy grails: [GrailItem]) throws {
        let referencedFiles = Set(grails.compactMap(\.maskedImageFilename))
        let imagesURL = imagesDirectoryURL()
        let files = try fileManager.contentsOfDirectory(
            at: imagesURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        for file in files where !referencedFiles.contains(file.lastPathComponent) {
            try? fileManager.removeItem(at: file)
        }
    }
    
    // Re-normalize older saved cutouts that were stored with too much transparent padding.
    private func normalizeStoredImagesIfNeeded() throws {
        for grail in grails {
            guard let filename = grail.maskedImageFilename else { continue }
            let url = imagesDirectoryURL().appendingPathComponent(filename, isDirectory: false)
            guard let image = UIImage(contentsOfFile: url.path),
                  let normalized = normalizedImageIfNeeded(image),
                  let png = normalized.pngData() else {
                continue
            }
            try png.write(to: url, options: .atomic)
        }
    }
    
    private func normalizedImageIfNeeded(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        guard let bounds = alphaBoundingRect(in: cgImage) else { return nil }
        
        let imageMax = CGFloat(max(cgImage.width, cgImage.height))
        let subjectMax = max(bounds.width, bounds.height)
        let occupancy = subjectMax / imageMax
        guard occupancy < 0.9 else { return nil }
        
        guard let cropped = cgImage.cropping(to: bounds.integral) else { return nil }
        
        let targetOccupancy: CGFloat = 0.96
        let subjectSide = CGFloat(max(cropped.width, cropped.height))
        let canvasSide = max(1, Int(ceil(subjectSide / targetOccupancy)))
        let canvasSize = CGSize(width: canvasSide, height: canvasSide)
        let drawRect = CGRect(
            x: (canvasSize.width - CGFloat(cropped.width)) / 2,
            y: (canvasSize.height - CGFloat(cropped.height)) / 2,
            width: CGFloat(cropped.width),
            height: CGFloat(cropped.height)
        )
        
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = image.scale
        
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
        return renderer.image { _ in
            UIImage(cgImage: cropped, scale: image.scale, orientation: .up).draw(in: drawRect)
        }
    }
    
    private func alphaBoundingRect(in image: CGImage, alphaThreshold: UInt8 = 8) -> CGRect? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return nil }
        
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var buffer = [UInt8](repeating: 0, count: bytesPerRow * height)
        
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        guard let context = CGContext(
            data: &buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        var found = false
        
        for y in 0..<height {
            let row = y * bytesPerRow
            for x in 0..<width {
                let alpha = buffer[row + (x * bytesPerPixel) + 3]
                if alpha > alphaThreshold {
                    found = true
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        
        guard found else { return nil }
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
    }

    private func ensureStorageDirectories() throws {
        try fileManager.createDirectory(
            at: imagesDirectoryURL(),
            withIntermediateDirectories: true
        )
    }

    private func rootDirectoryURL() -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport
            .appendingPathComponent("Saldo", isDirectory: true)
            .appendingPathComponent("Grails", isDirectory: true)
    }

    private func imagesDirectoryURL() -> URL {
        rootDirectoryURL().appendingPathComponent("images", isDirectory: true)
    }

    private func metadataFileURL() -> URL {
        rootDirectoryURL().appendingPathComponent("grails.json", isDirectory: false)
    }
}
