# プロジェクトの構成

Package.swift、Xcode プロジェクト、テストプラン、依存チェックの対応です。表の書き方は [README](README.md#表の書き方) を参照してください。構成そのものは [package-dependencies.md](../package-dependencies.md) にあります。

| Swift / iOS | Flutter での相当 | 違い | このリポジトリで使っている場所 |
| --- | --- | --- | --- |
| Package.swift | pubspec.yaml + melos のワークスペース | 1 つの Package.swift に全 target を書く（Dart はパッケージごとに pubspec.yaml を置く） | [Package.swift](../../Package.swift) |
| SwiftPM の target / product | melos 配下の各 package / 公開ライブラリ | target がモジュール（ビルドの単位）で、product は外部に公開するもの。公開しない target は同じパッケージ内でだけ使える | [Package.swift](../../Package.swift) |
| app/App.xcodeproj | Flutter の ios/Runner.xcodeproj に近い | Flutter の Runner は Flutter アプリの iOS 側の入れ物だが、こちらはアプリ本体の target を持つ | [app/App.xcodeproj](../../app/App.xcodeproj) |
| テストプラン（AllTests.xctestplan） | 相当なし | `flutter test` は `test/` を自動で見つけるが、Xcode は走らせる target をテストプランに明示する | [app/AllTests.xctestplan](../../app/AllTests.xctestplan) |
| 依存チェックのスクリプト | depend_on_referenced_packages lint + 層の許可リスト | Flutter の標準には層の許可リストが無い。このリポジトリは docs の依存グラフを許可リストにしている | [scripts/check-dependencies.swift](../../scripts/check-dependencies.swift) |
| `swift package describe` | `melos list --graph` / `dart pub deps` | 依存の一覧を JSON でも出せるので、スクリプトから読める | [scripts/check-dependencies.swift](../../scripts/check-dependencies.swift) |

## 参考リンク

- [Swift Package Manager（Package.swift、target、product）](https://www.swift.org/documentation/package-manager/)
- [Organizing tests to improve feedback（テストプラン）](https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback)
- [Adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
- [pubspec.yaml](https://dart.dev/tools/pub/pubspec) / [Dart のワークスペース](https://dart.dev/tools/pub/workspaces)
- [melos](https://pub.dev/packages/melos)
- [depend_on_referenced_packages](https://dart.dev/tools/linter-rules/depend_on_referenced_packages)
- [dart pub deps](https://dart.dev/tools/pub/cmd/pub-deps)
- [Flutter の iOS 向けの設定](https://docs.flutter.dev/platform-integration/ios/setup)
