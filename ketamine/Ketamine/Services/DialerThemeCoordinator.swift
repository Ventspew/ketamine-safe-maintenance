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

    /// Resolves a usable cached hash or explains the missing-cache condition.
    /// Does not invent UUIDs. Optional `discover` closure may perform existing
    /// privileged discovery; this coordinator never implements discovery itself.
    static func resolvePhoneHash(
        cached: String,
        discover: () throws -> String
    ) throws -> String {
        DiagnosticLog.shared.info("THEME_TARGET", "Target: Phone dialer")
        switch ContainerIdentity.classify(cached) {
        case .presentUnverified(let uuid):
            DiagnosticLog.shared.info(
                "THEME_CACHE",
                "Using cached container identifier \(FeatureAccessState.redact(uuid.uuidString))"
            )
            return uuid.uuidString
        case .invalidFormat(let raw):
            DiagnosticLog.shared.error("THEME_CACHE", "Invalid cached identifier")
            throw CoordinatorError.invalidCachedIdentifier(raw)
        case .empty:
            DiagnosticLog.shared.warn("THEME_CACHE", "No cached container identifier")
            DiagnosticLog.shared.info("THEME_RESOLVE", "Checking supported resolution methods")
            do {
                let found = try discover().trimmingCharacters(in: .whitespacesAndNewlines)
                switch ContainerIdentity.classify(found) {
                case .presentUnverified(let uuid):
                    DiagnosticLog.shared.info(
                        "THEME_RESOLVE",
                        "Discovery returned \(FeatureAccessState.redact(uuid.uuidString))"
                    )
                    return uuid.uuidString
                case .empty, .invalidFormat:
                    DiagnosticLog.shared.error("THEME_RESOLVE", "Discovery returned unusable identifier")
                    throw CoordinatorError.missingCachedIdentifier
                }
            } catch is CoordinatorError {
                throw CoordinatorError.missingCachedIdentifier
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
}
