import Dependencies
import Foundation

extension DependencyValues {
    /// アプリが今使っている言語（`Bundle.main.preferredLocalizations.first`。`ja`、`en` など）。
    /// テストで言語を差し替えられるよう、UseCase は Bundle を直接読まずにこの依存を使う。
    package var preferredLocalization: String? {
        get { self[PreferredLocalizationKey.self] }
        set { self[PreferredLocalizationKey.self] = newValue }
    }
}

private enum PreferredLocalizationKey: DependencyKey {
    static let liveValue: String? = Bundle.main.preferredLocalizations.first
    static let testValue: String? = "en"
}
