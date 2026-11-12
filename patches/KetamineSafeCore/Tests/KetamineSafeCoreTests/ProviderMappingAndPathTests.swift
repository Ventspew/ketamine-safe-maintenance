import XCTest
@testable import KetamineSafeCore

/// Path/format helpers that mirror application-level fixes without privileged I/O.
final class ProviderMappingAndPathTests: XCTestCase {
    func testProviderMappingMatchesKAMUIHeuristics() {
        XCTAssertEqual(
            WallpaperDescriptorInspector.providerExtension(forDescriptorParentName: "video-loop"),
            WallpaperDescriptorInspector.photosExt
        )
        XCTAssertEqual(
            WallpaperDescriptorInspector.providerExtension(forDescriptorParentName: "MercuryPoster"),
            WallpaperDescriptorInspector.mercuryExt
        )
        XCTAssertEqual(
            WallpaperDescriptorInspector.providerExtension(forDescriptorParentName: "CollectionsPosterApp"),
            WallpaperDescriptorInspector.collectionsModernExt
        )
        XCTAssertEqual(
            WallpaperDescriptorInspector.providerExtension(forDescriptorParentName: "static-pack"),
            WallpaperDescriptorInspector.collectionsExt
        )
    }

    func testNormalizeUUIDShape() {
        let raw = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        XCTAssertEqual(ContainerIdentity.classify(raw).uuidString?.lowercased(), raw.lowercased())
    }
}
