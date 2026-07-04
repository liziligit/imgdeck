import SwiftUI

struct SettingsView: View {
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .simplifiedChinese

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        Form {
            Picker(strings.languageLabel, selection: $language) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }

            Text(strings.languageHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding(12)
        .frame(width: 420, height: 150)
        .navigationTitle(strings.settingsTitle)
    }
}
