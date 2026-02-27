import SwiftUI
import UIKit
import ImageIO

@MainActor
@Observable
final class GrailStore {
    private(set) var grails: [GrailItem] = []
    private(set) var cachedPreviewItems: [GrailPreviewItem] = []

    private nonisolated static let previewLimit = 3
    private nonisolated static let maxStoredImageDimension: CGFloat = 1024
    private nonisolated static let previewDecodeMaxPixelSize = 320
    private nonisolated static let imagePipelineVersion = 2
    private nonisolated static let imagePipelineVersionKey = "aryaman.Saldo.grailImagePipelineVersion"
    private static let contourWarmColors: [UIColor] = {
        let themes: [AppTheme] = [.danger, .moderate, .wealthy]
        let schemes: [ColorScheme] = [.light, .dark]
        var colors: [UIColor] = []
        for theme in themes {
            for scheme in schemes {
                colors.append(UIColor(theme.colors(for: scheme).accent))
            }
        }
        return colors
    }()

    func load() async {
        let metadataURL = metadataFileURL()
        let imagesURL = imagesDirectoryURL()

        do {
            let snapshot = try await runInBackground {
                try Self.loadSnapshot(
                    metadataURL: metadataURL,
                    imagesURL: imagesURL,
                    previewLimit: Self.previewLimit
                )
            }
            grails = snapshot.grails
            cachedPreviewItems = snapshot.previews
            warmContourCache(for: snapshot.previews)
        } catch {
            print("⚠️ [GrailStore] Failed to load grails: \(error.localizedDescription)")
            grails = []
            cachedPreviewItems = []
        }
    }

    func add(grail: GrailItem, maskedImage: UIImage?) async {
        let metadataURL = metadataFileURL()
        let imagesURL = imagesDirectoryURL()
        let existingGrails = grails

        do {
            let snapshot = try await runInBackground {
                try Self.addGrail(
                    grail: grail,
                    maskedImage: maskedImage,
                    existingGrails: existingGrails,
                    metadataURL: metadataURL,
                    imagesURL: imagesURL,
                    previewLimit: Self.previewLimit
                )
            }
            grails = snapshot.grails
            cachedPreviewItems = snapshot.previews
            warmContourCache(for: snapshot.previews)
        } catch {
            print("⚠️ [GrailStore] Failed to add grail: \(error.localizedDescription)")
        }
    }

    func previewItems(limit: Int) -> [GrailPreviewItem] {
        Array(cachedPreviewItems.prefix(limit))
    }

    func addDeposit(to grailID: UUID, amount: Double, note: String?) async {
        let metadataURL = metadataFileURL()
        let imagesURL = imagesDirectoryURL()
        var updatedGrails = grails

        guard let index = updatedGrails.firstIndex(where: { $0.id == grailID }) else { return }

        let deposit = DepositRecord(amount: amount, note: note)
        updatedGrails[index].deposits.append(deposit)
        updatedGrails[index].currentAmount += amount

        do {
            let snapshot = try await runInBackground {
                try Self.persistGrails(updatedGrails, metadataURL: metadataURL)
                return Self.buildPreviewItems(
                    from: updatedGrails,
                    limit: Self.previewLimit,
                    imagesURL: imagesURL
                )
            }
            grails = updatedGrails
            cachedPreviewItems = snapshot
            warmContourCache(for: snapshot)
        } catch {
            print("⚠️ [GrailStore] Failed to add deposit: \(error.localizedDescription)")
        }
    }

    func updateImage(for grailID: UUID, maskedImage: UIImage) async {
        let metadataURL = metadataFileURL()
        let imagesURL = imagesDirectoryURL()
        var updatedGrails = grails

        guard let index = updatedGrails.firstIndex(where: { $0.id == grailID }) else { return }

        let filename = "\(grailID.uuidString).png"

        do {
            // Do file I/O in background
            try await runInBackground {
                try Self.ensureStorageDirectories(imagesURL: imagesURL)
                let imageURL = imagesURL.appendingPathComponent(filename, isDirectory: false)
                let optimized = Self.optimizedStoredImage(from: maskedImage, maxDimension: Self.maxStoredImageDimension)
                if let imageData = optimized.pngData() {
                    try imageData.write(to: imageURL, options: .atomic)
                }
            }

            // Mutate on MainActor
            updatedGrails[index].maskedImageFilename = filename

            let snapshot = try await runInBackground {
                try Self.persistGrails(updatedGrails, metadataURL: metadataURL)
                return Self.buildPreviewItems(
                    from: updatedGrails,
                    limit: Self.previewLimit,
                    imagesURL: imagesURL
                )
            }
            grails = updatedGrails
            cachedPreviewItems = snapshot
            warmContourCache(for: snapshot)
        } catch {
            print("⚠️ [GrailStore] Failed to update image: \(error.localizedDescription)")
        }
    }

    private func warmContourCache(for previews: [GrailPreviewItem]) {
        let visuals = previews.compactMap { preview -> (cacheID: String, image: UIImage)? in
            guard let image = preview.image else { return nil }
            return (cacheID: preview.visualCacheKey, image: image)
        }
        guard !visuals.isEmpty else { return }

        let colors = Self.contourWarmColors
        DispatchQueue.global(qos: .utility).async {
            for visual in visuals {
                GrailContourRenderer.warmCache(
                    for: visual.image,
                    cacheID: visual.cacheID,
                    colors: colors
                )
            }
        }
    }

    private func runInBackground<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try work())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private nonisolated struct Snapshot {
        let grails: [GrailItem]
        let previews: [GrailPreviewItem]
    }

    private nonisolated static func loadSnapshot(
        metadataURL: URL,
        imagesURL: URL,
        previewLimit: Int
    ) throws -> Snapshot {
        try ensureStorageDirectories(imagesURL: imagesURL)
        var loaded = try loadGrails(metadataURL: metadataURL)
        loaded.sort(by: { $0.createdAt > $1.createdAt })
        migrateImagesIfNeeded(grails: loaded, imagesURL: imagesURL)
        try cleanupOrphanedImages(referencedBy: loaded, imagesURL: imagesURL)

        let previews = buildPreviewItems(
            from: loaded,
            limit: previewLimit,
            imagesURL: imagesURL
        )
        return Snapshot(grails: loaded, previews: previews)
    }

    private nonisolated static func addGrail(
        grail: GrailItem,
        maskedImage: UIImage?,
        existingGrails: [GrailItem],
        metadataURL: URL,
        imagesURL: URL,
        previewLimit: Int
    ) throws -> Snapshot {
        try ensureStorageDirectories(imagesURL: imagesURL)
        var updated = existingGrails
        var storedGrail = grail

        if let maskedImage {
            let filename = "\(storedGrail.id.uuidString).png"
            let imageURL = imagesURL.appendingPathComponent(filename, isDirectory: false)
            let optimized = optimizedStoredImage(from: maskedImage, maxDimension: maxStoredImageDimension)
            if let imageData = optimized.pngData() {
                try imageData.write(to: imageURL, options: .atomic)
                storedGrail.maskedImageFilename = filename
            } else {
                storedGrail.maskedImageFilename = nil
            }
        } else {
            storedGrail.maskedImageFilename = nil
        }

        updated.insert(storedGrail, at: 0)
        updated.sort(by: { $0.createdAt > $1.createdAt })

        try persistGrails(updated, metadataURL: metadataURL)
        try cleanupOrphanedImages(referencedBy: updated, imagesURL: imagesURL)

        let previews = buildPreviewItems(
            from: updated,
            limit: previewLimit,
            imagesURL: imagesURL
        )
        return Snapshot(grails: updated, previews: previews)
    }

    private nonisolated static func loadGrails(metadataURL: URL) throws -> [GrailItem] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            return []
        }

        let data = try Data(contentsOf: metadataURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([GrailItem].self, from: data)
    }

    private nonisolated static func persistGrails(_ grails: [GrailItem], metadataURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(grails)
        try data.write(to: metadataURL, options: .atomic)
    }

    private nonisolated static func cleanupOrphanedImages(referencedBy grails: [GrailItem], imagesURL: URL) throws {
        let fileManager = FileManager.default
        let referencedFiles = Set(grails.compactMap(\.maskedImageFilename))
        let files = try fileManager.contentsOfDirectory(
            at: imagesURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        for file in files where !referencedFiles.contains(file.lastPathComponent) {
            try? fileManager.removeItem(at: file)
        }
    }

    private nonisolated static func migrateImagesIfNeeded(grails: [GrailItem], imagesURL: URL) {
        let defaults = UserDefaults.standard
        let savedVersion = defaults.integer(forKey: imagePipelineVersionKey)
        guard savedVersion < imagePipelineVersion else { return }

        for grail in grails {
            guard let filename = grail.maskedImageFilename else { continue }
            let url = imagesURL.appendingPathComponent(filename, isDirectory: false)
            guard let image = UIImage(contentsOfFile: url.path) else { continue }
            let optimized = optimizedStoredImage(from: image, maxDimension: maxStoredImageDimension)
            guard let pngData = optimized.pngData() else { continue }
            do {
                try pngData.write(to: url, options: .atomic)
            } catch {
                print("⚠️ [GrailStore] Failed to migrate image \(filename): \(error.localizedDescription)")
            }
        }

        defaults.set(imagePipelineVersion, forKey: imagePipelineVersionKey)
    }

    private nonisolated static func buildPreviewItems(
        from grails: [GrailItem],
        limit: Int,
        imagesURL: URL
    ) -> [GrailPreviewItem] {
        let recent = grails
            .sorted(by: { $0.createdAt > $1.createdAt })
            .prefix(limit)

        return recent.map { grail in
            GrailPreviewItem(
                id: grail.id,
                visualCacheKey: visualCacheKey(for: grail),
                name: grail.name,
                category: grail.category,
                image: loadPreviewImage(for: grail, imagesURL: imagesURL),
                targetAmount: grail.targetAmount,
                currentAmount: grail.currentAmount,
                currency: grail.currency
            )
        }
    }

    private nonisolated static func visualCacheKey(for grail: GrailItem) -> String {
        grail.maskedImageFilename ?? grail.id.uuidString
    }

    private nonisolated static func loadPreviewImage(for grail: GrailItem, imagesURL: URL) -> UIImage? {
        guard let filename = grail.maskedImageFilename else { return nil }
        let imageURL = imagesURL.appendingPathComponent(filename, isDirectory: false)
        return loadDownsampledImage(
            at: imageURL,
            maxPixelSize: previewDecodeMaxPixelSize
        ) ?? UIImage(contentsOfFile: imageURL.path)
    }

    private nonisolated static func loadDownsampledImage(at url: URL, maxPixelSize: Int) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithURL(
            url as CFURL,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ) else {
            return nil
        }

        let options: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    private nonisolated static func optimizedStoredImage(from image: UIImage, maxDimension: CGFloat) -> UIImage {
        let normalized = normalizeOrientation(image)
        let currentMax = max(normalized.size.width, normalized.size.height)
        guard currentMax > maxDimension else {
            return normalized
        }

        let scaleFactor = maxDimension / currentMax
        let newSize = CGSize(
            width: max(1, normalized.size.width * scaleFactor),
            height: max(1, normalized.size.height * scaleFactor)
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            normalized.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private nonisolated static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private nonisolated static func ensureStorageDirectories(imagesURL: URL) throws {
        try FileManager.default.createDirectory(
            at: imagesURL,
            withIntermediateDirectories: true
        )
    }

    private func rootDirectoryURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
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
