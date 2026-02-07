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
                image: loadImage(for: grail)
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
