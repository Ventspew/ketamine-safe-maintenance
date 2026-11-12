import SwiftUI
import UIKit
import KetamineSafeCore

struct DiagnosticsView: View {
    @AppStorage("phoneHash") private var phoneHash = ""
    @AppStorage("pbHash") private var pbHash = ""
    @State private var exportText = ""
    @State private var showExporter = false

    private var snapshot: DiagnosticsSnapshot {
        DiagnosticsReportBuilder.build(
            phoneHash: phoneHash,
            posterBoardHash: pbHash,
            privilegedDiscoveryAvailable: BadQuery.isAvailable
        )
    }

    var body: some View {
        List {
            Section("Device") {
                LabeledContent("Model", value: snapshot.deviceModel)
                LabeledContent("iOS", value: snapshot.iosVersion)
                LabeledContent("Build", value: snapshot.iosBuild)
                LabeledContent("Ketamine", value: snapshot.appVersion)
            }
            Section("Container cache") {
                LabeledContent("Phone", value: snapshot.phoneContainerCache)
                LabeledContent("PosterBoard", value: snapshot.posterBoardContainerCache)
            }
            Section("Feature status") {
                LabeledContent("Dialer theme", value: snapshot.dialerThemeState)
                LabeledContent("PosterBoard", value: snapshot.posterBoardState)
                Text("Status reflects local configuration and whether privileged discovery is available — not a claim that installation succeeded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Recent events") {
                if snapshot.lastEvents.isEmpty {
                    Text("No diagnostic events yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(snapshot.lastEvents.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            Section {
                Button("Export diagnostic log") {
                    exportText = snapshot.textualReport
                    showExporter = true
                }
                Button("Clear log", role: .destructive) {
                    DiagnosticLog.shared.clear()
                }
            }
        }
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExporter) {
            ActivityView(activityItems: [exportText])
        }
    }
}

enum DiagnosticsReportBuilder {
    static func build(
        phoneHash: String,
        posterBoardHash: String,
        privilegedDiscoveryAvailable: Bool
    ) -> DiagnosticsSnapshot {
        let os = DeviceCompatibility.currentOS()
        let version = "\(os.version.majorVersion).\(os.version.minorVersion).\(os.version.patchVersion)"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let model = {
#if canImport(UIKit)
            return UIDevice.current.model
#else
            return "unknown"
#endif
        }()

        let phoneState = FeatureAccessState.dialerThemeState(
            cachedHash: phoneHash,
            privilegedDiscoveryAvailable: privilegedDiscoveryAvailable
        )
        let pbState = FeatureAccessState.posterBoardState(
            cachedHash: posterBoardHash,
            privilegedDiscoveryAvailable: privilegedDiscoveryAvailable
        )

        return DiagnosticsSnapshot(
            deviceModel: model,
            iosVersion: version,
            iosBuild: os.build ?? "unknown",
            appVersion: appVersion,
            phoneContainerCache: describe(ContainerIdentity.classify(phoneHash)),
            posterBoardContainerCache: describe(ContainerIdentity.classify(posterBoardHash)),
            dialerThemeState: "\(phoneState.title) — \(phoneState.detail)",
            posterBoardState: "\(pbState.title) — \(pbState.detail)",
            lastEvents: DiagnosticLog.shared.snapshot().suffix(40).map(\.line)
        )
    }

    private static func describe(_ identity: ContainerIdentity) -> String {
        switch identity {
        case .empty: return "empty"
        case .invalidFormat(let raw):
            return "invalid (\(FeatureAccessState.redact(raw)))"
        case .presentUnverified(let uuid):
            return "present unverified (\(FeatureAccessState.redact(uuid.uuidString)))"
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
