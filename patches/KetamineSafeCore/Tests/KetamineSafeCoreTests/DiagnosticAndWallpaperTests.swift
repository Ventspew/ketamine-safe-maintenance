import XCTest
@testable import KetamineSafeCore

final class DiagnosticAndWallpaperTests: XCTestCase {
    func testDiagnosticRedaction() {
        let line = "[ERROR] /var/mobile/Containers/Data/Application/A1B2C3D4-E5F6-7890-ABCD-EF1234567890/Library"
        let redacted = DiagnosticLog.redactSensitive(line)
        XCTAssertFalse(redacted.contains("EF1234567890"))
        XCTAssertTrue(redacted.contains("/var/mobile/Containers/[redacted]"))
    }

    func testDiagnosticLogRecordsAndExports() {
        let log = DiagnosticLog()
        log.info("THEME_START", "Starting keypad theme operation")
        log.info("THEME_NAME", "Theme: colored_numbers")
        log.warn("CACHE_MISS", "No cached container identifier")
        log.error("CONTAINER_UNAVAILABLE", "Container unavailable")
        let text = log.exportText()
        XCTAssertTrue(text.contains("THEME_START"))
        XCTAssertTrue(text.contains("[WARN]"))
        XCTAssertTrue(text.contains("[ERROR]"))
    }

    func testWallpaperDescriptorRequiresMarker() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ketamine-wallpaper-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        XCTAssertThrowsError(try WallpaperDescriptorInspector.inspectExtractedDirectory(root))

        let descriptor = root.appendingPathComponent("collection/desc1", isDirectory: true)
        try FileManager.default.createDirectory(at: descriptor, withIntermediateDirectories: true)
        let marker = descriptor.appendingPathComponent(
            WallpaperDescriptorInspector.descriptorMarker
        )
        try Data("12345".utf8).write(to: marker)

        let inspection = try WallpaperDescriptorInspector.inspectExtractedDirectory(root)
        XCTAssertEqual(inspection.descriptorFolderCount, 1)
        XCTAssertTrue(inspection.hasCollectionsMarkers)
    }

    func testZipMagicForTendies() {
        XCTAssertThrowsError(try WallpaperDescriptorInspector.inspectZipMagic(Data("nope".utf8)))
        XCTAssertNoThrow(try WallpaperDescriptorInspector.inspectZipMagic(Data([0x50, 0x4B, 0x03, 0x04])))
    }
}
