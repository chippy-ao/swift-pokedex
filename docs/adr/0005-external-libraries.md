# ADR-0005: 外部ライブラリの選定方針

- ステータス: 承認済み
- 日付: 2026-10-27

## コンテキスト

学習目的のプロジェクトなので、標準 API で足りるものは標準で書きます。一方で、実務で「入れておく」定番のライブラリは経験として導入します。

## 決定

方針は「標準で十分なものは標準、実務で入れとく定番だけ入れる」です。

### 採用

| ライブラリ | 用途・補足 |
| --- | --- |
| [swift-http-types](https://github.com/apple/swift-http-types) | Apple 製。HTTPRequest / HTTPResponse / HTTPFields の共通型。HTTPTypesFoundation が URLSession の拡張を提供する。[swift-openapi-runtime](https://github.com/apple/swift-openapi-runtime) や SwiftNIO 周辺でも使われる共通型 |
| [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) | DI([ADR-0004](0004-dependency-injection.md)) |
| [Nuke](https://github.com/kean/Nuke) | NukeUI の `LazyImage`。メモリ・ディスクキャッシュ。14 系はベータが出ているので、導入時に最新の安定版を確認する |
| [LicenseList](https://github.com/cybozu/LicenseList) | SPM 依存のライセンス一覧を生成し `LicenseListView` で表示。Swift 6.2 で書かれ Xcode 26.2 以上が必要。プラグインの適用先など導入手順は README に従い導入時に確認する |
| [SwiftLint](https://github.com/realm/SwiftLint) | Lint |
| [swift-format](https://github.com/swiftlang/swift-format) | 整形(Swift ツールチェーンに同梱) |
| [Swift Testing](https://developer.apple.com/documentation/testing) | 標準のテストフレームワーク |
| [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) | 余裕が出たら導入 |

### 不採用

| ライブラリ | 不採用理由 |
| --- | --- |
| Alamofire / Moya | PokeAPI は GET のみ・認証なしなので不要 |
| Realm | MongoDB が 2024 年 9 月に Atlas Device SDK の廃止を発表し、2025 年 9 月 30 日に EOL。DB 本体はオープンソースとして残るが新規採用は避ける([ADR-0006](0006-local-persistence.md)) |
| Kingfisher | Nuke と同等の選択肢。国内では Kingfisher も多いがどちらか一つでよい |
| Factory | swift-dependencies と同等の選択肢。Riverpod 経験から swift-dependencies を選ぶ |
| TCA | [ADR-0002](0002-state-management-custom-mvi.md) を参照 |
| swift-openapi-generator | PokeAPI に公式の OpenAPI 定義が無い(GitHub issue #528 で議論されているのみ) |
| R.swift / SwiftGen | Xcode のアセットシンボル自動生成と String Catalog で足りる |
| XcodeGen / Tuist | 個人開発なので当面不要 |

### Flutter との対応

| Flutter | Swift |
| --- | --- |
| Freezed / json_serializable | struct・enum・`Codable` で不要 |
| flutter_hooks | `@State`・`.task`・`.onChange` で不要 |
| Signals | `@Observable` が近い(読んだプロパティだけを追跡する) |
| Dio | URLSession + swift-http-types |
| Injectable / get_it | swift-dependencies |
| cached_network_image | Nuke |

## 理由

- 依存を絞ると、標準 API(URLSession、Codable、Observation など)を学ぶ機会が増えます。
- 画像キャッシュ、ライセンス表示、Lint のように自作の価値が低いものは定番に任せます。
- 依存先は 1 モジュールに閉じ込めます(Nuke は DesignSystem のみ、LicenseList は SettingsFeature のみ)。

## 検討した代替案

上記「不採用」の表を参照してください。

## 影響

### 良い点

- 依存が少なく、更新追従の負担が小さい。
- ライブラリごとの利用モジュールが限定される。

### 悪い点・注意点

- Nuke 14 系はベータが出ているため、導入時に最新の安定版を確認する。
- LicenseList はプラグインの適用先を導入時に確認する。
- ライブラリのバージョンはこの ADR では固定しない。

## 参考リンク

- [PokeAPI の OpenAPI 化 issue](https://github.com/PokeAPI/pokeapi/issues/528)
- [Realm の廃止(ドキュメント)](https://www.mongodb.com/docs/realm/)
- [Realm の廃止(フォーラム)](https://www.mongodb.com/community/forums/t/deprecation-of-realm-swift-sdk/300126)
- [String Catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
