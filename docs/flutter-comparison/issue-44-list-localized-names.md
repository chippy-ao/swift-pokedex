# #44 一覧のポケモン名を言語で出す

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/44

一覧の名前をアプリの言語で出すために初めて出てきたもの（`String` を包む struct、`Bundle.module`）を、Dart / Flutter の同じ層のものと比べる学習ノートです。前の Issue で説明した言葉は [issue-38-localization.md](issue-38-localization.md) を見てください。

## Swift の言語機能

### String を包む struct（RawRepresentable）と Dart の typedef / extension type

**何の話か:** 言語コード（`"en"`、`"ja-hrkt"`）を、普通の文字列と取り違えないようにする書き方です。

**意味:** `LanguageCode` は `String` を 1 つ持つ struct で、`RawRepresentable` に準拠します。型の上で `String` と別物なので、名前（`String`）を言語コードの引数に渡すとコンパイルエラーになります。`enum` にしないのは、PokeAPI が将来コードを足したとき、未知のコードも運べるようにするためです（[ADR-0018](../adr/0018-bundled-pokemon-names-table.md) と `LanguageCode.swift` のコメント）。

Dart の `typedef` は別名で、新しい型は作りません（同じ型を短く書く名前、と公式にあります）。区別したいときの近い道具は extension type です。ただし extension type はコンパイル時だけの区別で、実行時にはその跡が残りません。実行時の型は中身の型（representation type）に見えます。

```swift
public struct LanguageCode: RawRepresentable, Hashable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let jaHrkt = LanguageCode(rawValue: "ja-hrkt")
}

func pick(_ names: [LocalizedName], for code: LanguageCode) -> String? { /* … */ nil }
// pick(names, for: "ja-hrkt") は書けない。LanguageCode.jaHrkt を渡す
```

```dart
extension type const LanguageCode(String value) {
  static const jaHrkt = LanguageCode('ja-hrkt');
}

String? pick(List<LocalizedName> names, LanguageCode code) => null; // 省略
// pick(names, 'ja-hrkt') はコンパイルエラー。LanguageCode.jaHrkt を渡す
```

**違いと間違えやすいところ:** Swift の struct は実際の型で、実行時にも `LanguageCode` として存在します。Dart の extension type は実行時に `String` と同じに見えるので、`dynamic` や `Object` を経由した型の判定（`is`、`as`）は `String` として扱われます。外から来た値（JSON など）を受けるところで 1 回だけ包む、という使い方は両方で同じです。このアプリでは、DTO は `String` のままにして、Repository で `LanguageCode` に包みます。

**ダメな例:** `typealias LanguageCode = String` は `String` と区別されないので、取り違えてもコンパイルが通ります。Dart の `typedef LanguageCode = String;` も同じです。

**出典:** [Extension types（Dart）](https://dart.dev/language/extension-types)、[Typedefs（Dart）](https://dart.dev/language/typedefs)、[RawRepresentable（Apple）](https://developer.apple.com/documentation/swift/rawrepresentable)

## Apple 標準

### Bundle.module と Flutter の rootBundle

**何の話か:** アプリに同梱したファイル（このアプリではポケモン名の JSON）を、コードから読む方法です。

**意味:** SwiftPM は、リソースを持つモジュールごとに `Bundle.module` を作ります。各モジュールのリソースは、そのモジュール自身の bundle に入ります。`NetworkClientURLSession` の JSON は `NetworkClientURLSession` の `Bundle.module` から名前で読み、他のモジュールの bundle とは混ざりません。Flutter は、アプリ全体で 1 つの asset bundle（`rootBundle`）があり、`pubspec.yaml` に書いた asset をキーで読みます。

```swift
// core/NetworkClientURLSession の中。Bundle.module はこのモジュールの bundle
let url = Bundle.module.url(forResource: "pokemon-species-names", withExtension: "json")
```

```dart
// pubspec.yaml の flutter: assets: に書いたものだけ読める
final text = await rootBundle.loadString('assets/pokemon-species-names.json');
```

**違いと間違えやすいところ:** Flutter でパッケージの asset を読むときは、パッケージ内のパスに `packages/<名前>/` を付けるなどの決まりがあります（画像では `package:` 引数を渡します）。Swift は、モジュールの中のコードは自分の `Bundle.module` を呼ぶだけで、パスの前置きは要りません。ただし、別のモジュールに入れた JSON を、今のモジュールの `Bundle.module` では読めません。リソースを置いたモジュールの中で読んで、結果だけを interface で返す形にしています（[ADR-0017](../adr/0017-network-client-interface-independent-of-transport.md)）。

**出典:** [Bundling resources with a Swift package（Apple）](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package)、[Assets and images（Flutter）](https://docs.flutter.dev/ui/assets/assets-and-images)の「Loading assets」と「Asset images in package dependencies」の節
