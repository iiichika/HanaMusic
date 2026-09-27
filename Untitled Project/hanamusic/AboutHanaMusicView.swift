import SwiftUI

#if os(iOS)
struct AboutHanaMusicView: View {
    var body: some View {
        List {
            // App Logo & 名称
            Section {
                VStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
                        .padding(.top, 16)

                    Text("Hana Music")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(L10n.appVersionDesc)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            // 开发者栏目
            Section(header: Text(L10n.devTeam)) {
                HStack {
                    Label {
                        Text(L10n.developer)
                            .font(.body)
                    } icon: {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    Text(L10n.developerName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 4)
            }

            Section(header: Text(L10n.aboutApp)) {
                HStack {
                    Text(L10n.archMode)
                    Spacer()
                    Text("SwiftUI + MediaPlayer")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text(L10n.uiStyle)
                    Spacer()
                    Text("Liquid Glass / Apple Music")
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.aboutHanaMusic)
        .navigationBarTitleDisplayMode(.inline)
    }
}
#else
struct AboutHanaMusicView: View {
    var body: some View {
        Text("About Hana Music")
    }
}
#endif
