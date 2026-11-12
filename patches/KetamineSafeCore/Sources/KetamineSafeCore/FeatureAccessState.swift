import Foundation

/// Explicit feature readiness, independent of "version check passed".
public enum FeatureAccessState: Sendable, Equatable {
    case ready
    case missingIdentifier(target: String)
    case invalidConfiguration(reason: String)
    case inaccessible(reason: String)
    case unsupported(reason: String)

    public var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    public var title: String {
        switch self {
        case .ready: return "Ready"
        case .missingIdentifier: return "Missing identifier"
        case .invalidConfiguration: return "Invalid configuration"
        case .inaccessible: return "Inaccessible"
        case .unsupported: return "Unsupported"
        }
    }

    public var detail: String {
        switch self {
        case .ready:
            return "Local app state required for this feature is present."
        case .missingIdentifier(let target):
            return "No usable cached container identifier for \(target)."
        case .invalidConfiguration(let reason),
             .inaccessible(let reason),
             .unsupported(let reason):
            return reason
        }
    }

    public static func dialerThemeState(
        cachedHash: String?,
        privilegedDiscoveryAvailable: Bool
    ) -> FeatureAccessState {
        switch ContainerIdentity.classify(cachedHash) {
        case .presentUnverified:
            return .ready
        case .invalidFormat(let raw):
            return .invalidConfiguration(
                reason: "Cached Phone container value “\(redact(raw))” is not a valid UUID."
            )
        case .empty:
            if privilegedDiscoveryAvailable {
                return .missingIdentifier(target: ContainerIdentity.phoneBundleIdentifier)
            }
            return .inaccessible(
                reason: ContainerResolutionBlocker.operatingSystemRestriction.humanExplanation
            )
        }
    }

    public static func posterBoardState(
        cachedHash: String?,
        privilegedDiscoveryAvailable: Bool
    ) -> FeatureAccessState {
        switch ContainerIdentity.classify(cachedHash) {
        case .presentUnverified:
            return .ready
        case .invalidFormat(let raw):
            return .invalidConfiguration(
                reason: "Cached PosterBoard container value “\(redact(raw))” is not a valid UUID."
            )
        case .empty:
            if privilegedDiscoveryAvailable {
                return .missingIdentifier(target: ContainerIdentity.posterBoardBundleIdentifier)
            }
            return .inaccessible(
                reason: ContainerResolutionBlocker.operatingSystemRestriction.humanExplanation
            )
        }
    }

    /// Keeps UI/logs from dumping full identifiers.
    public static func redact(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 8 else { return "•••" }
        return String(trimmed.prefix(4)) + "…••••"
    }
}
