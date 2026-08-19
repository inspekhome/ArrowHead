import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let privacyURL = URL(string: "https://inspekhome.github.io/ArrowHead/privacy.html")!
    private let userGuideURL = URL(string: "https://inspekhome.github.io/ArrowHead/guide.html")!
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
                    Label("Arrow in Picture", systemImage: "camera.viewfinder")
                        .font(.title2.weight(.bold))
                    Text(versionText)
                        .foregroundStyle(.secondary)
                }

                Section("Privacy") {
                    Text(
                        "Arrow in Picture does not require an account and does not send photos, "
                            + "captions, analytics, or personal information to the developer."
                    )
                    Text(
                        "Photos are saved in Apple Photos and remain under your control."
                    )
                    Link(destination: privacyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                }

                Section("Support") {
                    Link(destination: userGuideURL) {
                        Label("User Guide", systemImage: "book.fill")
                    }
                    Link(destination: supportURL) {
                        Label("Arrow in Picture Support", systemImage: "questionmark.circle.fill")
                    }
                }
            }
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview { AboutView() }
