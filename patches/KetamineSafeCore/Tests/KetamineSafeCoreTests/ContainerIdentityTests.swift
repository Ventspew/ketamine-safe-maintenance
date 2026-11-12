import XCTest
@testable import KetamineSafeCore

final class ContainerIdentityTests: XCTestCase {
    func testEmptyCache() {
        XCTAssertEqual(ContainerIdentity.classify(nil), .empty)
        XCTAssertEqual(ContainerIdentity.classify(""), .empty)
        XCTAssertEqual(ContainerIdentity.classify("   "), .empty)
    }

    func testValidUUID() {
        let raw = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        let classified = ContainerIdentity.classify(raw)
        guard case .presentUnverified(let uuid) = classified else {
            return XCTFail("expected presentUnverified")
        }
        XCTAssertEqual(uuid.uuidString.lowercased(), raw.lowercased())
        XCTAssertTrue(classified.isUsableAsCacheKey)
    }

    func testInvalidFormatRejected() {
        XCTAssertEqual(
            ContainerIdentity.classify("not-a-uuid"),
            .invalidFormat("not-a-uuid")
        )
        XCTAssertEqual(
            ContainerIdentity.classify("Phone"),
            .invalidFormat("Phone")
        )
        // Must not treat a bare hex blob as a container hash without dashes.
        if case .invalidFormat = ContainerIdentity.classify("a1b2c3d4e5f67890abcdef1234567890") {
            // ok
        } else {
            XCTFail("expected invalidFormat for undashed hex")
        }
    }

    func testDialerMissingCacheWithoutPrivilegedDiscovery() {
        let state = FeatureAccessState.dialerThemeState(
            cachedHash: "",
            privilegedDiscoveryAvailable: false
        )
        guard case .inaccessible = state else {
            return XCTFail("expected inaccessible when no privileged discovery")
        }
    }

    func testDialerMissingCacheWithPrivilegedDiscoveryFlag() {
        let state = FeatureAccessState.dialerThemeState(
            cachedHash: "",
            privilegedDiscoveryAvailable: true
        )
        guard case .missingIdentifier(let target) = state else {
            return XCTFail("expected missingIdentifier")
        }
        XCTAssertEqual(target, ContainerIdentity.phoneBundleIdentifier)
    }

    func testReproduceReportedPhoneDialerMissingHashCondition() {
        // Mirrors the factory-reset condition behind the 2.1 beta message:
        // theme assets may be valid while the Phone container hash is absent.
        let identity = ContainerIdentity.classify("")
        XCTAssertEqual(identity, .empty)

        let blocker = ContainerResolutionBlocker.missingCachedIdentifier
        XCTAssertTrue(blocker.humanExplanation.contains("factory reset") ||
                      blocker.humanExplanation.contains("cached container"))

        let state = FeatureAccessState.dialerThemeState(
            cachedHash: nil,
            privilegedDiscoveryAvailable: false
        )
        XCTAssertFalse(state.isReady)
        XCTAssertEqual(state.title, "Inaccessible")
    }

    func testRedaction() {
        let redacted = FeatureAccessState.redact("A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
        XCTAssertFalse(redacted.contains("EF1234567890"))
        XCTAssertTrue(redacted.hasPrefix("A1B2"))
    }
}
