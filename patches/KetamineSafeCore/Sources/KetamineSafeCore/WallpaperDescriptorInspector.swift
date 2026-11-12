import Foundation

/// Read-only validation of PosterBoard "tendies" descriptor packs.
/// Does not open or modify PosterBoard's application container.
public struct WallpaperDescriptorInspection: Sendable, Equatable {
    public let isZip: Bool
    public let descriptorFolderCount: Int
    public let hasCollectionsMarkers: Bool
    public let hasPhotosMarkers: Bool
    public let markerFilesFound: [String]

    public init(
        isZip: Bool,
        descriptorFolderCount: Int,
        hasCollectionsMarkers: Bool,
        hasPhotosMarkers: Bool,
        markerFilesFound: [String]
    ) {
        self.isZip = isZip
        self.descriptorFolderCount = descriptorFolderCount
        self.hasCollectionsMarkers = hasCollectionsMarkers
        self.hasPhotosMarkers = hasPhotosMarkers
        self.markerFilesFound = markerFilesFound
    }

    public var looksLikeTendiesPack: Bool {
        isZip && descriptorFolderCount > 0
    }
}

public enum WallpaperDescriptorInspectorError: Error, LocalizedError, Equatable {
    case unreadable
    case notZip
    case noDescriptors

    public var errorDescription: String? {
        switch self {
        case .unreadable: return "The wallpaper pack could not be read."
        case .notZip: return "That file is not a valid tendies/zip archive."
        case .noDescriptors:
            return "No PosterBoard descriptor folders were found in that pack."
        }
    }
}

public enum WallpaperDescriptorInspector {
    public static let descriptorMarker = "com.apple.posterkit.provider.descriptor.identifier"
    public static let collectionsExt = "com.apple.WallpaperKit.CollectionsPoster"
    public static let collectionsModernExt = "com.apple.Posters.CollectionsPosterApp"
    public static let mercuryExt = "com.apple.MercuryPoster"
    public static let photosExt = "com.apple.PhotosUIPrivate.PhotosPosterProvider"

    /// KAMUI-compatible provider selection from a descriptor's parent folder name.
    public static func providerExtension(forDescriptorParentName parentName: String) -> String {
        let lower = parentName.lowercased()
        if lower.contains("video") || lower.contains("photos") {
            return photosExt
        }
        if lower.contains("mercury") {
            return mercuryExt
        }
        if lower.contains("collectionsposterapp") || lower.contains("posters.collections") {
            return collectionsModernExt
        }
        return collectionsExt
    }

    /// Inspect an already-extracted directory tree (unit tests / previews).
    public static func inspectExtractedDirectory(_ root: URL) throws -> WallpaperDescriptorInspection {
        var descriptorCount = 0
        var markers: [String] = []
        var hasCollections = false
        var hasPhotos = false

        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw WallpaperDescriptorInspectorError.unreadable
        }

        for case let url as URL in enumerator {
            if url.lastPathComponent == descriptorMarker {
                markers.append(url.path)
                descriptorCount += 1
                let parentName = url.deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .lastPathComponent
                    .lowercased()
                if parentName.contains("video") {
                    hasPhotos = true
                } else {
                    hasCollections = true
                }
            }
        }

        guard descriptorCount > 0 else {
            throw WallpaperDescriptorInspectorError.noDescriptors
        }

        return WallpaperDescriptorInspection(
            isZip: false,
            descriptorFolderCount: descriptorCount,
            hasCollectionsMarkers: hasCollections,
            hasPhotosMarkers: hasPhotos,
            markerFilesFound: markers
        )
    }

    public static func inspectZipMagic(_ data: Data) throws {
        guard ThemePackageInspector.isZipMagic(data) else {
            throw WallpaperDescriptorInspectorError.notZip
        }
    }
}
