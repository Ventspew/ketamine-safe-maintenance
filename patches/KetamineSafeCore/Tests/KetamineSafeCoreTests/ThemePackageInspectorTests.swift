import XCTest
@testable import KetamineSafeCore

final class ThemePackageInspectorTests: XCTestCase {
    func testMatchKeyStripsLocalePrefix() {
        XCTAssertEqual(
            ThemePackageInspector.matchKey(for: "en-lock-number-1.png"),
            "lock-number-1.png"
        )
        XCTAssertEqual(
            ThemePackageInspector.matchKey(for: "lock-number-1.png"),
            "lock-number-1.png"
        )
    }

    func testRejectsNonZip() throws {
        XCTAssertThrowsError(try ThemePackageInspector.inspect(data: Data("hello".utf8))) { error in
            XCTAssertEqual(error as? ThemePackageInspectorError, .notZip)
        }
    }

    func testInspectsStoredZipWithTenKeys() throws {
        let pngNames = (0..<10).map { "en-key-\($0).png" }
        let zip = try Self.makeStoreZip(entryNames: pngNames, payload: Self.tinyPNG)
        let inspection = try ThemePackageInspector.inspect(data: zip)
        XCTAssertEqual(inspection.imageCount, 10)
        XCTAssertEqual(inspection.distinctKeys.count, 10)
        XCTAssertTrue(inspection.summary.contains("10 images"))
        XCTAssertTrue(inspection.summary.contains("10 keys"))
    }

    func testEmptyZipHasNoPNGs() throws {
        let zip = try Self.makeStoreZip(entryNames: ["readme.txt"], payload: Data("x".utf8))
        XCTAssertThrowsError(try ThemePackageInspector.inspect(data: zip)) { error in
            XCTAssertEqual(error as? ThemePackageInspectorError, .noPNGs)
        }
    }

    // MARK: - Minimal stored ZIP writer (method 0)

    private static let tinyPNG = Data([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE,
        0xD4, 0xEF, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
        0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
    ])

    private static func makeStoreZip(entryNames: [String], payload: Data) throws -> Data {
        var local = Data()
        var central = Data()
        var offset: UInt32 = 0

        for name in entryNames {
            let nameData = Data(name.utf8)
            let crc = crc32(payload)
            let size = UInt32(payload.count)
            let nameLen = UInt16(nameData.count)

            var localHeader = Data()
            localHeader.append(contentsOf: [0x50, 0x4B, 0x03, 0x04]) // sig
            localHeader.append(u16: 20) // version
            localHeader.append(u16: 0) // flags
            localHeader.append(u16: 0) // method store
            localHeader.append(u16: 0) // time
            localHeader.append(u16: 0) // date
            localHeader.append(u32: crc)
            localHeader.append(u32: size)
            localHeader.append(u32: size)
            localHeader.append(u16: nameLen)
            localHeader.append(u16: 0) // extra
            localHeader.append(nameData)
            localHeader.append(payload)

            var centralHeader = Data()
            centralHeader.append(contentsOf: [0x50, 0x4B, 0x01, 0x02])
            centralHeader.append(u16: 20) // version made by
            centralHeader.append(u16: 20) // version needed
            centralHeader.append(u16: 0)
            centralHeader.append(u16: 0)
            centralHeader.append(u16: 0)
            centralHeader.append(u16: 0)
            centralHeader.append(u32: crc)
            centralHeader.append(u32: size)
            centralHeader.append(u32: size)
            centralHeader.append(u16: nameLen)
            centralHeader.append(u16: 0)
            centralHeader.append(u16: 0)
            centralHeader.append(u16: 0)
            centralHeader.append(u16: 0)
            centralHeader.append(u32: 0)
            centralHeader.append(u32: offset)
            centralHeader.append(nameData)

            offset += UInt32(localHeader.count)
            local.append(localHeader)
            central.append(centralHeader)
        }

        var end = Data()
        end.append(contentsOf: [0x50, 0x4B, 0x05, 0x06])
        end.append(u16: 0)
        end.append(u16: 0)
        end.append(u16: UInt16(entryNames.count))
        end.append(u16: UInt16(entryNames.count))
        end.append(u32: UInt32(central.count))
        end.append(u32: UInt32(local.count))
        end.append(u16: 0)

        return local + central + end
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                if crc & 1 != 0 {
                    crc = (crc >> 1) ^ 0xEDB88320
                } else {
                    crc >>= 1
                }
            }
        }
        return crc ^ 0xFFFFFFFF
    }
}

private extension Data {
    mutating func append(u16 value: UInt16) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { append(contentsOf: $0) }
    }

    mutating func append(u32 value: UInt32) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { append(contentsOf: $0) }
    }
}
