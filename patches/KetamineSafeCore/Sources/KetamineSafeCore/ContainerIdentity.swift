import Foundation

/// Application-level classification of a cached application-container UUID.
///
/// This type never invents a container path and never probes privileged
/// filesystem locations. It only validates the shape and presence of an
/// identifier the rest of the app already holds in local settings.
public enum ContainerIdentity: Sendable, Equatable {
    case empty
    case invalidFormat(String)
    /// Present and syntactically valid. Verification against the live
    /// container is a separate, privileged concern and is not performed here.
    case presentUnverified(UUID)

    public static let phoneBundleIdentifier = "com.apple.mobilephone"
    public static let posterBoardBundleIdentifier = "com.apple.PosterBoard"

    /// RFC-4122 style UUID string (8-4-4-4-12 hex), case-insensitive.
    private static let uuidPattern = #"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"#

    public static func classify(_ raw: String?) -> ContainerIdentity {
        let trimmed = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        guard trimmed.range(of: uuidPattern, options: .regularExpression) != nil,
              let uuid = UUID(uuidString: trimmed) else {
            return .invalidFormat(trimmed)
        }
        return .presentUnverified(uuid)
    }

    public var uuidString: String? {
        switch self {
        case .presentUnverified(let uuid): return uuid.uuidString
        case .empty, .invalidFormat: return nil
        }
    }

    public var isUsableAsCacheKey: Bool {
        if case .presentUnverified = self { return true }
        return false
    }
}

/// Why dialer/PosterBoard installation cannot proceed from app state alone.
public enum ContainerResolutionBlocker: String, Sendable, Equatable, CaseIterable {
    case missingCachedIdentifier
    case invalidCachedIdentifier
    case privilegedDiscoveryUnavailable
    case privilegedDiscoveryFailed
    case operatingSystemRestriction

    public var humanExplanation: String {
        switch self {
        case .missingCachedIdentifier:
            return "No cached container identifier is stored for this target. After a factory reset or reinstall, previous identifiers are gone and must not be reused from another device."
        case .invalidCachedIdentifier:
            return "The stored container identifier is not a valid UUID. Clear it instead of constructing a filesystem path from it."
        case .privilegedDiscoveryUnavailable:
            return "This build has no authorized on-device method to enumerate other apps' containers. Discovery requires a privileged mechanism that is outside ordinary app entitlements."
        case .privilegedDiscoveryFailed:
            return "A privileged discovery attempt ran but did not resolve the target container."
        case .operatingSystemRestriction:
            return "iOS sandbox rules prevent scanning /var/mobile/Containers from an ordinary app process."
        }
    }
}
