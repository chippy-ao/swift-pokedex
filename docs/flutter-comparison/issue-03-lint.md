# #3 Lint と整形（swift-format と SwiftLint）

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/3
- PR: https://github.com/chippy-ao/swift-pokedex/pull/23

Swift のコードを整える 2 つのツール、swift-format と SwiftLint を、Dart の dart format と analysis_options.yaml の lint と比べます。mise、prek、committed は言語に依らないので、ここでは扱いません。方針は [development.md](../development.md#lint-と整形) と [ADR-0011](../adr/0011-lint-and-format.md) にあります。

- [swift-format](#swift-format)
- [.swift-format（整形の設定）](#swift-format整形の設定)
- [SwiftLint](#swiftlint)
- [.swiftlint.yml（無効にしたルール）](#swiftlintymlルールの無効化)
- [早見表](#早見表)

### swift-format

何の話か: コードの見た目（インデントや改行）を、決まった形に自動でそろえるツールです。

意味: Swift 6（Xcode 16）以降のツールチェーンに同梱された整形ツールで、`swift format` で呼び出します。別に入れる必要はなく、Xcode のバージョンに付いてきます。整形は機械に任せるので、人がレビューで見た目を指摘しなくて済みます。

Swift のコード（実行コマンド。[mise.toml](../../mise.toml)）:

```toml
run = "swift format format --in-place --recursive app core feature scripts Package.swift"
```

Dart のコード:

```sh
dart format .
```

違いと間違えやすいところ:

- swift-format は Xcode（Swift 6 以降）と一緒に更新されます。dart format が Dart SDK と一緒に入るのと同じ位置づけです。
- Swift 5 系のツールチェーンには同梱されていません。このリポジトリは Swift 6 以降を前提にしています。
- 整形の検査だけをしたいときは `swift format lint --strict` を使います。dart format なら `dart format --output=none --set-exit-if-changed .` に当たります。
- swift-format には `lint` というサブコマンドもありますが、これは整形の違反を報告するだけです。次の SwiftLint の lint とは別物です。

出典:

- [swiftlang/swift-format の README（同梱と `lint --strict`）](https://github.com/swiftlang/swift-format/blob/main/README.md)
- [dart format（dart.dev）](https://dart.dev/tools/dart-format)

### .swift-format（整形の設定）

何の話か: 整形のルールのうち、既定から変えたいところだけを書くファイルです。

意味: JSON で書き、書いた項目だけが既定を上書きします。このリポジトリはインデントを 4 スペースにしただけで、ほかは既定です。理由は、Xcode の既定のインデントと合わせるためです。JSON にはコメントを書けないので、理由は [development.md](../development.md#lint-と整形) にあります。

Swift のコード（[.swift-format](../../.swift-format)）:

```json
{
  "indentation": { "spaces": 4 }
}
```

Dart のコード（`analysis_options.yaml`。整形の設定はここに書きます。言語バージョン 3.7 以降）:

```yaml
formatter:
  page_width: 100
```

違いと間違えやすいところ:

- swift-format の既定のインデントは 2 スペースです（`swift format dump-configuration` で確かめられます）。このリポジトリは 4 に上書きしています。
- swift-format は設定ファイルが専用（`.swift-format`）です。dart format は `analysis_options.yaml` の `formatter:` に書き、解析の設定と同じファイルになります。
- 設定できる項目は swift-format のほうが多く、行の長さ、末尾のカンマの扱い、import の並び順などを変えられます。dart format はページ幅（既定 80。swift-format の `lineLength` は既定 100）と、末尾のカンマの扱い（`trailing_commas`）などです。

出典:

- [swift-format の設定（Configuration.md）](https://github.com/swiftlang/swift-format/blob/main/Documentation/Configuration.md)
- [dart format のオプション（dart.dev）](https://dart.dev/tools/dart-format)

### SwiftLint

何の話か: コードの書き方に問題がないかを調べるツールです。見た目ではなく、危ない書き方や命名を見ます。

意味: 書き方の検査は SwiftLint が担当します（force unwrap、命名、複雑度など）。コンパイラが止めない問題を拾うためです。Swift ツールチェーンには入っていないので、mise でバージョンを固定して入れています。

Swift のコード（実行コマンド。[mise.toml](../../mise.toml)）:

```toml
run = [
  "swift format lint --strict --recursive app core feature scripts Package.swift",
  "swiftlint --strict",
]
```

Dart のコード:

```sh
flutter analyze
```

違いと間違えやすいところ:

- `flutter analyze` は Dart の解析器（analyzer）を動かし、型エラーなどの解析と lint のルールを同じ設定ファイルでまとめて検査します。SwiftLint は lint だけで、型エラーなどはコンパイラ（`swift build`）が見ます。
- 層をそろえると、SwiftLint のルール集は flutter_lints のようなルール集に当たり、`flutter analyze` は実行役です。ここでは実行コマンドどうしを並べています。
- SwiftLint は Apple 標準ではなく外部のツールです。Dart の解析器は SDK 付属です。
- SwiftLint の `--strict` は警告もエラー扱いにして、終了コードを失敗にします。Dart の `dart analyze` は既定で error と warning で失敗し、info は `--fatal-infos` で失敗にできます。段階の分け方が違います。

出典:

- [realm/SwiftLint](https://github.com/realm/SwiftLint)
- [Dart の静的解析と lint（dart.dev）](https://dart.dev/tools/analysis)
- [dart analyze（dart.dev）](https://dart.dev/tools/dart-analyze)

### .swiftlint.yml（ルールの無効化）

何の話か: どのファイルを検査して、どのルールを止めるかを書く設定ファイルです。

意味: 既定のルールで始め、swift-format の整形結果とぶつかる 2 つだけを止めています。ぶつかるルールは、直しても警告が消えないからです。止めた理由は、設定ファイルのすぐ近くにコメントで書いています。

Swift のコード（[.swiftlint.yml](../../.swiftlint.yml)）:

```yaml
disabled_rules:
  - trailing_comma
  - opening_brace
```

Dart のコード（`analysis_options.yaml`）:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: false
```

違いと間違えやすいところ:

- Dart 側は `include:` で flutter_lints などの推奨セットを取り込み、そこから個別に調整するのが普通です。SwiftLint は最初から入っているルールの一覧があり、そこから `disabled_rules` で止めます。
- Swift は整形（swift-format）と lint（SwiftLint）が別々のツールで、ルールが重なる部分があります。そのため導入時に、整形したあとで SwiftLint を通して、ぶつかるルールを止める手順を踏んでいます（[development.md](../development.md#lint-と整形)）。
- 止めた 2 つは、末尾のカンマ（`trailing_comma`）と `{` の位置（`opening_brace`）です。swift-format は複数要素のコレクションの末尾にカンマを付け、折り返したシグネチャでは `{` を次の行に置きます。

出典:

- [SwiftLint の設定（Configuration）](https://github.com/realm/SwiftLint#configuration)
- [analysis_options.yaml のカスタマイズ（dart.dev）](https://dart.dev/tools/analysis#customizing-analysis-rules)
- [flutter_lints（pub.dev）](https://pub.dev/packages/flutter_lints)

## 早見表

| Swift / iOS | Dart / Flutter での相当 | 違い | このリポジトリで使っている場所 |
| --- | --- | --- | --- |
| swift-format（`swift format`） | dart format | どちらも SDK 側に同梱されている（swift-format は Swift 6 以降）。swift-format は設定できる項目が多い | [mise.toml](../../mise.toml) |
| `.swift-format` | `analysis_options.yaml` の `formatter:` | 専用の JSON ファイル。コメントを書けない | [.swift-format](../../.swift-format) |
| SwiftLint | `flutter analyze` の lint ルール（flutter_lints など） | 外部ツール。型エラーなどの解析は含まない（Dart の analyzer は SDK 付属で、解析と lint が一体） | [mise.toml](../../mise.toml) |
| `.swiftlint.yml` の `disabled_rules` | `analysis_options.yaml` の `linter: rules:` | 既定のルールから止める形。整形ツールとぶつかるルールを止める | [.swiftlint.yml](../../.swiftlint.yml) |
