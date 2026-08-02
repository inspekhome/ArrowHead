import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let privacyURL = URL(string: "https://inspekhome.github.io/ArrowHead/privacy.html")!
    private let supportURL = URL(string: "https://inspekhome.github.io/ArrowHead/support.html")!

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("ArrowHead", systemImage: "camera.viewfinder")
                        .font(.title2.weight(.bold))
                    Text(versionText)
                        .foregroundStyle(.secondary)
                }

                Section("Privacy / 隐私") {
                    Text(
                        "ArrowHead does not require an account and does not send photos, "
                            + "captions, analytics, or personal information to the developer."
                    )
                    Text(
                        "照片保存在 Apple 照片中。ArrowHead 不会把照片、文字或个人信息发送给开发者。"
                    )
                    Link(destination: privacyURL) {
                        Label("Privacy Policy / 隐私政策", systemImage: "hand.raised.fill")
                    }
                }

                Section("Support / 支持") {
                    Link(destination: supportURL) {
                        Label("ArrowHead Support", systemImage: "questionmark.circle.fill")
                    }
                }
            }
            .navigationTitle("About / 关于")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done / 完成") { dismiss() }
                }
            }
        }
    }
}

#Preview { AboutView() }
