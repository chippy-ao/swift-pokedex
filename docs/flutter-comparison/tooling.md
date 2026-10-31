# 開発ツール

バージョン管理、Git フック、Lint、整形、テストの実行に使うツールの対応です。表の書き方は [README](README.md#表の書き方) を参照してください。方針は [development.md](../development.md) にあります。

| Swift / iOS | Flutter での相当 | 違い | このリポジトリで使っている場所 |
| --- | --- | --- | --- |
| mise | fvm + asdf | ツールのバージョン固定に加えて、タスクも定義できる。タスクは melos scripts に近いが、パッケージを横断する機能は無い | [mise.toml](../../mise.toml) |
| prek | lefthook / husky | Git フックの設定を YAML に書く。pre-commit の設定ファイル形式を読む | [.pre-commit-config.yaml](../../.pre-commit-config.yaml) |
| committed | commitlint | コミットメッセージの規約を検査する。設定は TOML | [committed.toml](../../committed.toml) |
| swift-format | dart format | 設定ファイルで幅などを変えられる（dart format は主にページ幅だけ）。このリポジトリはインデント 4 | [.swift-format](../../.swift-format) |
| SwiftLint | analysis_options.yaml の lint / flutter analyze | 整形は別ツールが担うので、整形とぶつかるルールは切っている。コンパイラの解析（型エラーなど）は含まない | [.swiftlint.yml](../../.swiftlint.yml) |
| xcbeautify | 相当なし | `xcodebuild` のログを読みやすくするだけの整形ツール。flutter test の出力は最初から読みやすい | [mise.toml](../../mise.toml) |
| `swift x.swift`（スクリプト実行） | `dart run tool/x.dart` | ファイルを 1 つ指定して直接実行できる。ビルド設定は不要 | [scripts/check-dependencies.swift](../../scripts/check-dependencies.swift) |
| `xcodebuild test` / `mise run test` | `flutter test` | 走らせる target と実行先のシミュレーターを明示する。`flutter test` は `test/` を自動で見つける | [mise.toml](../../mise.toml) |

## 参考リンク

- [mise](https://mise.jdx.dev/)
- [prek](https://github.com/j178/prek)
- [committed](https://github.com/crate-ci/committed)
- [swift-format](https://github.com/swiftlang/swift-format)
- [SwiftLint](https://github.com/realm/SwiftLint)
- [xcbeautify](https://github.com/cpisciotta/xcbeautify)
- [fvm](https://fvm.app/) / [asdf](https://asdf-vm.com/) / [melos](https://pub.dev/packages/melos)
- [lefthook](https://github.com/evilmartians/lefthook) / [husky](https://typicode.github.io/husky/) / [commitlint](https://commitlint.js.org/)
- [dart format](https://dart.dev/tools/dart-format) / [flutter analyze と analysis_options.yaml](https://dart.dev/tools/analysis)
- [dart run](https://dart.dev/tools/dart-run) / [flutter test](https://docs.flutter.dev/testing/overview)
