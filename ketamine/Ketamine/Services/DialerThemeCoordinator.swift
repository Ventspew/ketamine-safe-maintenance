import Foundation
import KetamineSafeCore

/// Coordinates dialer theme preview/validation separately from privileged install.
enum DialerThemeCoordinator {
    enum CoordinatorError: LocalizedError {
        case missingCachedIdentifier
        case invalidCachedIdentifier(String)
        case package(ThemePackageInspectorError)
        case underlying(Error)

        var errorDescription: String? {
            switch self {
            case .missingCachedIdentifier:
                return """
                Could not update theme

                Phone dialer has no cached container hash.
                Ordinary apps cannot scan /var/mobile/Containers,
                so the bundle UUID must already be available from a
                prior authorized discovery session — or discovery must
                succeed on this firmware. A factory reset clears prior hashes.
                """
            case .invalidCachedIdentifier(let raw):
                return "Cached Phone container identifier \(FeatureAccessState.redact(raw)) is not a valid UUID. Clear it in Preferences and rediscover if your firmware allows."
            case .package(let error):
                return error.errorDescription
            case .underlying(let error):
                return error.localizedDescription
            }
        }
    }

    static func inspectPackage(at url: URL) throws -> ThemePackageInspection {
        DiagnosticLog.shared.info("THEME_INSPECT", "Inspecting theme package")
        do {
            let inspection = try ThemePackageInspector.inspect(fileURL: url)
            DiagnosticLog.shared.info(
                "THEME_ASSETS",
                "Assets validated: \(inspection.imageCount)/\(inspection.imageCount) (\(inspection.summary))"
            )
            return inspection
        } catch let error as ThemePackageInspectorError {
            DiagnosticLog.shared.error("THEME_ASSETS", error.localizedDescription)
            throw CoordinatorError.package(error)
        }
    }

    /// Resolves a Phone container reference when available.
    /// Returns `nil` when no hash exists but the global TelephonyUI cache may
    /// still be reachable (Ketamine 2.1b1 layout). Does not invent UUIDs.
    static func resolvePhoneHash(
        cached: String,
        discover: () throws -> String
    ) throws -> String? {
        DiagnosticLog.shared.info("THEME_TARGET", "Target: Phone dialer")
        if let normalized = BadQuery.normalizeContainerReference(cached) {
            DiagnosticLog.shared.info(
                "THEME_CACHE",
                "Using cached container identifier \(FeatureAccessState.redact(normalized.uuid))"
            )
            return normalized.uuid
        }
        let trimmed = cached.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            DiagnosticLog.shared.error("THEME_CACHE", "Invalid cached identifier")
            throw CoordinatorError.invalidCachedIdentifier(trimmed)
        }

        DiagnosticLog.shared.warn("THEME_CACHE", "No cached container identifier")
        DiagnosticLog.shared.info("THEME_RESOLVE", "Checking supported resolution methods")
        do {
            let found = try discover().trimmingCharacters(in: .whitespacesAndNewlines)
            if let normalized = BadQuery.normalizeContainerReference(found) {
                DiagnosticLog.shared.info(
                    "THEME_RESOLVE",
                    "Discovery returned \(FeatureAccessState.redact(normalized.uuid))"
                )
                return normalized.uuid
            }
        } catch {
            DiagnosticLog.shared.warn(
                "THEME_RESOLVE",
                "Bundle discovery failed — \(error.localizedDescription); trying global TelephonyUI paths"
            )
        }

        // 2.1b1-compatible fallback: proceed without a Phone UUID if global
        // TelephonyUI caches can be opened with the existing consume API.
        do {
            let path = try BadQuery.resolveTelephonyUIPath(appHash: nil)
            DiagnosticLog.shared.info("THEME_RESOLVE", "Using TelephonyUI path without Phone UUID")
            _ = path
            return nil
        } catch {
            DiagnosticLog.shared.error(
                "THEME_RESOLVE",
                "Container unavailable — \(error.localizedDescription)"
            )
            DiagnosticLog.shared.info("THEME_ABORT", "Theme installation aborted safely")
            throw CoordinatorError.missingCachedIdentifier
        }
    }
}
