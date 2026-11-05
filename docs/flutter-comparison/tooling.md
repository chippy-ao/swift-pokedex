# 開発ツール

バージョン管理、Git フック、Lint、整形、テストの実行、CI、依存の更新に使うツールの対応です。表の書き方は [README](README.md#表の書き方) を参照してください。方針は [development.md](../development.md) にあります。

| Swift / iOS | Flutter での相当 | 違い | このリポジトリで使っている場所 |
| --- | --- | --- | --- |
| mise | fvm + asdf | ツールのバージョン固定に加えて、タスクも定義できる。タスクは melos scripts に近いが、パッケージを横断する機能は無い | [mise.toml](../../mise.toml) |
| prek | lefthook / husky | Git フックの設定を YAML に書く。pre-commit の設定ファイル形式を読む | [.pre-commit-config.yaml](../../.pre-commit-config.yaml) |
| committed | commitlint | コミットメッセージの規約を検査する。設定は TOML | [committed.toml](../../committed.toml) |
| swift-format | dart format | 設定ファイルで幅などを変えられる（dart format は主にページ幅だけ）。このリポジトリはインデント 4 | [.swift-format](../../.swift-format) |
| SwiftLint | analysis_options.yaml の lint / flutter analyze | 整形は別ツールが担うので、整形とぶつかるルールは切っている。コンパイラの解析（型エラーなど）は含まない | [.swiftlint.yml](../../.swiftlint.yml) |
| xcbeautify | 相当なし | `xcodebuild` のログを読みやすくするだけの整形ツール。flutter test の出力は最初から読みやすい | [mise.toml](../../mise.toml) |
| `swift x.swift`（スクリプト実行） | `dart run tool/x.dart` | ファイルを 1 つ指定して直接実行できる。ビルド設定は不要 | [scripts/check-dependencies.swift](../../scripts/check-dependencies.swift) |
| CI のランナーイメージの Xcode（`DEVELOPER_DIR`、`xcode-select`） | `subosito/flutter-action` で Flutter SDK をジョブごとに取得 | Flutter SDK はバージョンを指定して取得できる。Xcode は取得できず、ランナーイメージに入っているものから `DEVELOPER_DIR` で選ぶ | [ci.yml](../../.github/workflows/ci.yml) |
| Renovate（swift / mise / github-actions マネージャー） | Renovate（pub マネージャー） | 仕組みは同じ。対象のマネージャーが違う。Dependabot は `mise.toml` に対応しない | [renovate.json5](../../.github/renovate.json5) |
| `committed --no-merge-commit` | 相当なし（Git の話で、言語に依らない） | PR 内のマージコミットを禁止し、main の取り込みは rebase にする | [conventions.yml](../../.github/workflows/conventions.yml) |
| ルールセットの必須チェックと集約ジョブ | 同じ（GitHub の機能で、言語に依らない） | 違いなし。個々のジョブでなく集約ジョブを必須にする | [ci.yml](../../.github/workflows/ci.yml) |
| 自動ラベル（GitHub Actions の workflow で `gh` を使って付ける） | 同じ（GitHub の機能で、言語に依らない） | 違いなし。Flutter のモノレポでも `actions/labeler` や `gh` で同じことができる。ここでは取得したバイナリを実行するアクションを避け、`gh` / `jq` / `yq` だけで書く | [pr-labels.yml](../../.github/workflows/pr-labels.yml) |
| `xcodebuild test` / `mise run test` | `flutter test` | 走らせる target と実行先のシミュレーターを明示する。`flutter test` は `test/` を自動で見つける | [mise.toml](../../mise.toml) |
| 変わったところだけ CI を走らせる（`changes` ジョブ + `if`。skipped は必須チェックで成功扱い） | melos の `--diff` に近い | 変更ファイルから走らせるジョブを決める点は同じ。違いは、飛ばしたジョブを skipped として成功扱いにし、必須チェックをまとめるジョブで結果を報告する必要があること | [ci.yml](../../.github/workflows/ci.yml) |

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
- [subosito/flutter-action](https://github.com/subosito/flutter-action) / [Renovate](https://docs.renovatebot.com/)
- [dart run](https://dart.dev/tools/dart-run) / [flutter test](https://docs.flutter.dev/testing/overview)
