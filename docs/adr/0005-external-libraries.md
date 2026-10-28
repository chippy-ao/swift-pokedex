# ADR-0005: 外部ライブラリの選定方針

- ステータス: 承認済み
- 日付: 2026-10-27

## コンテキスト

学習目的のプロジェクトなので、標準 API で足りるものは標準で書きます。一方で、実務で「入れておく」定番のライブラリは経験として導入します。

## 決定

方針は「標準で十分なものは標準、実務で入れとく定番だけ入れる」です。

- 採用するライブラリは swift-http-types、swift-dependencies、Nuke、LicenseList、SwiftLint、swift-format、Swift Testing とします。swift-snapshot-testing は余裕が出たら導入します。
- 各ライブラリの用途と、依存してよい target は [docs/package-dependencies.md](../package-dependencies.md#外部ライブラリ) にまとめています。
- 依存先は 1 モジュールに閉じ込めます(Nuke は DesignSystem のみ、LicenseList は SettingsFeature のみ)。
- ライブラリのバージョンはこの ADR では固定せず、導入時に最新の安定版を確認します。

## 理由

- 依存を絞ると、標準 API(URLSession、Codable、Observation など)を学ぶ機会が増えます。
- 画像キャッシュ、ライセンス表示、Lint のように自作の価値が低いものは定番に任せます。
- swift-http-types は Apple 製の標準的な HTTP 型で、[swift-openapi-runtime](https://github.com/apple/swift-openapi-runtime) や SwiftNIO 周辺でも使われる共通型なので、学んでおく価値が高いです。
- swift-dependencies は interface と実装を別モジュールに分けるパターンが公式に整理されており、Riverpod 経験から入りやすいです([ADR-0004](0004-dependency-injection.md))。
- 標準の `AsyncImage` はキャッシュ制御が弱いので、Nuke(NukeUI)を使います。
- SwiftLint は実務で定番です。swift-format は Swift ツールチェーンに同梱されています。
- 依存先を 1 モジュールに閉じ込めると、ライブラリの差し替え点が限定されます。

## 検討した代替案

採用しなかったライブラリです。

| ライブラリ | 不採用理由 |
| --- | --- |
| Alamofire / Moya | PokeAPI は GET のみ・認証なしなので、URLSession + swift-http-types で足りる |
| Realm | 新規採用を避ける理由は [ADR-0006](0006-local-persistence.md) を参照 |
| Kingfisher | Nuke と同等の選択肢。国内では Kingfisher も多いがどちらか一つでよい |
| Factory | swift-dependencies と同等の選択肢。Riverpod 経験から swift-dependencies を選ぶ |
| TCA | 2026 年 10 月時点で 1.26.x が出ており 2.0 への移行期で、書き方が変わるリスクがある。素の Swift を学ぶ目的に対して抽象化が厚い([ADR-0002](0002-state-management-custom-mvi.md)、[TCA releases](https://github.com/pointfreeco/swift-composable-architecture/releases)) |
| swift-openapi-generator | PokeAPI に公式の OpenAPI 定義が無い(GitHub issue #528 で議論されているのみ) |
| R.swift / SwiftGen | Xcode のアセットシンボル自動生成と String Catalog で足りる |
| XcodeGen / Tuist | 個人開発なので当面不要([ADR-0014](0014-xcode-project-management.md)) |

## 影響

### 良い点

- 依存が少なく、更新追従の負担が小さい。
- ライブラリごとの利用モジュールが限定される。

### 悪い点・注意点

- Nuke と LicenseList は導入時に確認すべき点がある([docs/package-dependencies.md](../package-dependencies.md#外部ライブラリ)の備考を参照)。

## 参考リンク

- [PokeAPI の OpenAPI 化 issue](https://github.com/PokeAPI/pokeapi/issues/528)
- [Realm の廃止(ドキュメント)](https://www.mongodb.com/docs/realm/)
- [Realm の廃止(フォーラム)](https://www.mongodb.com/community/forums/t/deprecation-of-realm-swift-sdk/300126)
- [String Catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
