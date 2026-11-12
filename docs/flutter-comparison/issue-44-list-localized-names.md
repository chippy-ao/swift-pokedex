# #44 一覧のポケモン名を言語で出す

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/44

一覧の名前をアプリの言語で出すために初めて出てきたもの（`String` を包む struct、`Bundle.module`、アプリ本体の言語、XCUITest）を、Dart / Flutter の同じ層のものと比べる学習ノートです。前の Issue で説明した言葉は [issue-38-localization.md](issue-38-localization.md) を見てください。

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

**出典:** [Bundling resources with a Swift package（Apple）](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package)、[Assets and images（Flutter）](https://docs.flutter.dev/ui/assets/assets-and-images)の「Loading assets」の中の「Loading text assets」（`rootBundle`）と、「Asset images in package dependencies」（`package:` 引数、`packages/<名前>/`）の節

### InfoPlist.xcstrings と、アプリ本体の言語（Flutter の iOS 側の設定）

**何の話か:** パッケージに訳があっても、アプリ本体（`Pokedex.app`）に言語を持たせないと、アプリが「日本語に対応している」と見なされない話です。

**意味:** Swift では、`Bundle.main.preferredLocalizations` が本体の bundle の言語から選ばれます。本体に言語が無いと常に開発言語（en）が返り、一覧のポケモン名が日本語になりませんでした。そこで本体に `InfoPlist.xcstrings`（アプリの表示名の en / ja）を置き、`en.lproj` と `ja.lproj` ができるようにしました（詳しくは [localization.md](../localization.md#アプリ本体にも言語を持たせる)）。

Flutter では、公式に「訳は Flutter が扱う（localizations are handled by Flutter）」とあるので、本体の言語が実行時の表示を決めることはありません。それでも iOS 側には、対応言語を Xcode プロジェクトに足す手順があります。公式の「Localizing for iOS: Updating the iOS app bundle」には、`ios/Runner.xcodeproj` を Xcode で開き、Info タブの Localizations で言語を足す手順が書かれています。理由は、App Store の掲載が対応言語を正しく出すため、また、Xcode が作る空の `.strings` を App Store が対応言語の判定に使うためです。

```swift
// Swift: 本体に言語があれば、ユーザーの言語順に選ばれる。無ければ en だけ
let language = Bundle.main.preferredLocalizations.first  // "ja" / "en"
```

```dart
// Flutter: 実行時の言語は Dart 側が決める（iOS の本体の言語には頼らない）
final language = Localizations.localeOf(context).languageCode; // 'ja' / 'en'
```

**違いと間違えやすいところ:** 手順は `Info.plist` に `CFBundleLocalizations` を書くやり方ではなく、Xcode の Localizations に言語を足すやり方で、公式のページに `Info.plist` や `CFBundleLocalizations` の記述はありません。

**ダメな例:** パッケージの訳だけで「日本語対応した」と思い込むこと。UI の文字は日本語に見えても、本体の言語を読むコードは英語のままです。

**出典:** [preferredLocalizations（Apple）](https://developer.apple.com/documentation/foundation/bundle/preferredlocalizations)、[WWDC19 セッション 403](https://developer.apple.com/wwdc19/403)、[Internationalizing Flutter apps の「Localizing for iOS: Updating the iOS app bundle」（Flutter）](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)

### XCUITest の launchArguments / launchEnvironment と Flutter の integration_test

**何の話か:** 組み上げたアプリを実際に起動して、画面を見て確かめるテストの書き方です。

**意味:** XCUITest は、テストとは別のプロセスでアプリを起動して画面を操作します。起動前に `launchArguments`（起動引数）と `launchEnvironment`（環境変数）を設定でき、アプリはそれを読んで動きを変えられます。このアプリでは、`-AppleLanguages (ja)` で言語を指定し、環境変数 `POKEDEX_UI_TEST_FIXTURE=1` で一覧の通信だけを固定データにしています（[development.md](../development.md#ui-テスト)）。

Flutter の `integration_test` は、`flutter test integration_test/app_test.dart` で実機やエミュレーターにアプリを起動し、`flutter_test` の API（`tester.tap` など）で操作します。公式の統合テストのページには、アプリに起動引数や環境変数を渡す方法の記載は見つかりませんでした。差し替えはテストコード側で Dart のオブジェクトを差し替えて行うのが基本で、このアプリのように「ビルド済みのアプリに外から値を渡す」形ではありません。

```swift
let app = XCUIApplication()
app.launchArguments = ["-AppleLanguages", "(ja)"]
app.launchEnvironment["POKEDEX_UI_TEST_FIXTURE"] = "1"
app.launch()
```

```dart
// integration_test: アプリは同じプロセスで動き、テストの中から直接差し替えられる
testWidgets('日本語の名前が出る', (tester) async {
  await tester.pumpWidget(const MyApp(repository: FakeRepository()));
  expect(find.text('フシギダネ'), findsOneWidget);
});
```

**違いと間違えやすいところ:** XCUITest は別プロセスなので、アプリのコードには触れず、画面の accessibility の情報だけを見ます。このアプリの行は読み上げを 1 つにまとめているため、cell の中の文字のラベル（`Bulbasaur, #0001` のような形）を部分一致で探します。

**出典:** [launchArguments（Apple）](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/launcharguments)、[launchEnvironment（Apple）](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/launchenvironment)、[An introduction to integration testing（Flutter）](https://docs.flutter.dev/testing/integration-tests)

### ビルドの警告の出どころと数え方（Xcode と dart analyze）

**何の話か:** コードの警告が、いつ・どこから出て、どうやって「1 件でもあれば CI を落とす」ようにするかの話です。

**意味:** Swift の警告は、コンパイラがビルドの途中で出します。Xcode のビルド結果（xcresult）に入り、`xcrun xcresulttool get build-results` で件数（`warningCount`）と本文を取れます。このリポジトリでの運用は [development.md](../development.md) にあります。

Dart の警告は analyzer が出します。公式のページには「Normally the analyzer reports failure when it finds any errors or warnings, but not when it finds info-level issues.」とあり、`dart analyze` は既定で警告があれば失敗扱いです。info は `--fatal-infos` で失敗にでき、`--no-fatal-warnings` で警告を失敗にしないこともできます。analyze と test は別のコマンドです。CI で `dart analyze` を走らせると、既定で警告があれば落ちるのに近いです（`flutter analyze` も同じ analyzer を使いますが、既定の挙動は確かめていません）。

手元の Xcode は増分ビルドです。変わっていないファイルは再コンパイルされないので、その警告は出ず、xcresult にも載らないことがあります。`dart analyze` は引数なしなら「performing static analysis over all the Dart files under the current directory」（カレントディレクトリの下の Dart ファイルを全部解析する）と書かれています。CI はまっさらな状態からビルドするので、全部の警告が出ます。

```swift
// 警告の件数は、ビルドが残した xcresult から取る
// $ xcrun xcresulttool get build-results --path build/AllTests.xcresult
// → warningCount が 1 以上なら scripts/check-build-warnings.swift が exit 1
```

```yaml
# Dart: dart analyze は既定で警告があれば失敗する。テストとは別のステップ
- run: dart analyze
- run: flutter test
```

**違いと間違えやすいところ:** Swift は「ビルドが警告を出す」ので、増分ビルドだと 0 件でも当てになりません。手元の 0 件は「今回コンパイルし直した範囲では 0 件」という意味で、CI の結果が正です。Dart は analyzer がビルドと別なので、引数なしならカレントディレクトリの下の全ファイルを解析します。

コンパイラのフラグで済ませる道は試して駄目でした。`-warnings-as-errors`（[SE-0443](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0443-warning-control-flags.md) の警告の制御フラグ）を付けても、このリポジトリで出た Swift 6 の並行性の警告（下の `@MainActor` の件）はエラーにならず、ビルドが通りました。また、Xcode は外部の SwiftPM 依存を `-suppress-warnings` で組むので、フラグと衝突して外部依存のビルドが失敗しました。経緯は [scripts/check-build-warnings.swift](../../scripts/check-build-warnings.swift) の冒頭のコメントにあります。

**例（@MainActor）:** UI テストで `XCUIApplication` を使うと、テスト関数に `@MainActor` を付けないと並行性の警告が 10 件出ました。`XCUIApplication` が `@MainActor` の型なので、触る関数もメインアクターに置きます。Swift は型でスレッド（アクター）を縛れますが、Dart / Flutter に型でスレッドを縛る仕組みはありません。Dart は isolate ごとにメモリが分かれていて、isolate 同士はメッセージで話します。`@MainActor` の基本は [issue-07-pokemon-list.md](issue-07-pokemon-list.md) の「@MainActor と @Observable の Store」 を見てください。

**出典:** `xcrun xcresulttool get build-results --help`（Xcode 付属のヘルプ。手元で実行して確認）、Xcode 27.2 の SDK のヘッダー（`XCUIAutomation.framework/Headers/XCUIApplication.h` で `@interface XCUIApplication` の直前に `XCUI_SWIFT_MAIN_ACTOR` があり、`XCUIAutomationDefines.h` で `#define XCUI_SWIFT_MAIN_ACTOR __attribute__((swift_attr("@MainActor")))` と定義されている）、[SE-0443 Precise control flags over compiler warnings](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0443-warning-control-flags.md)、[dart analyze（Dart）](https://dart.dev/tools/dart-analyze)、[Concurrency in Dart](https://dart.dev/language/concurrency)
