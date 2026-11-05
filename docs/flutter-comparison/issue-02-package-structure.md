# #2 Package.swift とモジュールの骨組みを作る

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/2
- PR: https://github.com/chippy-ao/swift-pokedex/pull/21

中身が空のまま全モジュールとアプリをビルドできる状態にした Issue です。ここでは、その骨組みに出てくる Swift の言語機能と Apple の標準の部品、Swift のツールチェーンを、Dart / Flutter の同じ層のものと比べます。学習用のメモで、仕様やルールではありません。構成そのものは [package-dependencies.md](../package-dependencies.md) にあります。

## 目次

- [Package.swift（パッケージの定義ファイル）](#packageswiftパッケージの定義ファイル)
- [swift-tools-version と platforms](#swift-tools-version-と-platforms)
- [swiftLanguageModes（言語モード）](#swiftlanguagemodes言語モード)
- [target（モジュール）とアクセス制御](#targetモジュールとアクセス制御)
- [product（外から使える形で公開するもの）](#product外から使える形で公開するもの)
- [target の依存（dependencies と path）](#target-の依存dependencies-と-path)
- [testTarget と Swift Testing、`@testable import`](#testtarget-と-swift-testingtestable-import)
- [Xcode プロジェクトとローカルパッケージ参照](#xcode-プロジェクトとローカルパッケージ参照)
- [テストプラン（AllTests.xctestplan）](#テストプランalltestsxctestplan)
- [`@main` と App プロトコル](#main-と-app-プロトコル)
- [`swift package describe`](#swift-package-describe)
- [`swift x.swift`（スクリプト実行）](#swift-xswiftスクリプト実行)
- [早見表](#早見表)

### Package.swift（パッケージの定義ファイル）

何の話か: アプリを部品ごとに分けて、どの部品が何に頼っているかを書いておくファイルです。

意味:

- Swift のパッケージは、`Package.swift` という Swift のコードで定義します。YAML ではなく、Swift の関数呼び出しで書きます。
- 型付きなので、書き間違えるとビルド前にエラーになります。
- このリポジトリは、ルートに `Package.swift` を 1 つだけ置き、全モジュールをまとめています。
- 例えるなら、`pubspec.yaml` を Dart で書く形です。ただし、1 つのファイルで複数のモジュールを持てます。

Swift のコード（[Package.swift](../../Package.swift)）:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-pokedex",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
    ],
    targets: [
        .target(name: "Common", path: "core/Common/Sources"),
    ],
    swiftLanguageModes: [.v6]
)
```

Dart のコード（pubspec.yaml）:

```yaml
name: pokedex_domain
environment:
  sdk: ^3.6.0
dependencies:
  pokedex_common:
    path: ../common
```

違いと間違えやすいところ:

- `pubspec.yaml` は宣言だけの YAML です。`Package.swift` は Swift のコードなので、変数や条件分岐も書けます。ただし、書くのは宣言にとどめる方針です。
- Dart は 1 つの `pubspec.yaml` が 1 つのパッケージです。Swift は 1 つの `Package.swift` に、複数の target（モジュール）を書けます。
- Dart でルートにまとめる相当は、workspace です（ルートの `pubspec.yaml` の `workspace:` に各パッケージを並べ、各パッケージに `resolution: workspace` と書きます）。ただし workspace でも、パッケージごとの `pubspec.yaml` は残ります。

出典:

- [Package（PackageDescription）](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html)
- [Swift Package Manager](https://www.swift.org/documentation/package-manager/)
- [pubspec.yaml](https://dart.dev/tools/pub/pubspec)
- [Pub workspaces](https://dart.dev/tools/pub/workspaces)

### swift-tools-version と platforms

何の話か: そのパッケージを読むのに必要な道具の版と、動かす OS の最低版を決める設定です。

意味:

- 1 行目の `// swift-tools-version: 6.2` は、`Package.swift` を読める SwiftPM の最低版です。コメントに見えますが、SwiftPM がこの行を読みます。
- `platforms` は、対応する OS の最低版です。このリポジトリは iOS 26 だけです。
- Dart の `environment: sdk:` は、SDK の版の範囲を決めます。1 つの設定で、道具の版と言語の版をまとめて縛ります。

Swift のコード（[Package.swift](../../Package.swift)）:

```swift
// swift-tools-version: 6.2
platforms: [.iOS(.v26)],
```

Dart のコード（pubspec.yaml）:

```yaml
environment:
  sdk: ^3.6.0
  flutter: ">=3.27.0"
```

違いと間違えやすいところ:

- `// swift-tools-version:` の行は、先頭に置く決まりです。普通のコメントとして消すと、パッケージが読めなくなります。
- Dart の `sdk:` は言語の版も決めます。Swift の tools-version は、主に `Package.swift` を読む SwiftPM の版です。言語モードは、次の項目の `swiftLanguageModes` で明示します（省略したときの既定値は tools-version に連動します）。
- 対応 OS の最低版は、Dart の pubspec にはありません。Flutter では、iOS 側の Podfile や Xcode の設定に書きます。このリポジトリの Xcode 側は `IPHONEOS_DEPLOYMENT_TARGET = 26.0` で、[project.pbxproj](../../app/App.xcodeproj/project.pbxproj) にあります。`Package.swift` の `platforms` と別々に持つので、両方をそろえる必要があります。

出典:

- [Swift Package Manager のドキュメント](https://www.swift.org/documentation/package-manager/)
- [SupportedPlatform（PackageDescription）](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html)
- [pubspec.yaml の environment](https://dart.dev/tools/pub/pubspec#sdk-constraints)

### swiftLanguageModes（言語モード）

何の話か: 同じコンパイラで、古い書き方の判定にするか、新しい厳しい判定にするかを選ぶ設定です。

意味:

- Swift 6 言語モードでは、同時に動くコードの間でのデータ競合を、コンパイラが見つけてエラーにします。
- このリポジトリは `[.v6]` だけを指定します。警告のエラー化や MainActor の既定の設定は使いません（理由は [package-dependencies.md](../package-dependencies.md#packageswift-の書き方の方針)）。
- Dart の言語バージョン（`sdk: ^3.6.0` で決まる）が一番近いです。言語の機能の有無を、パッケージ単位で決めるからです。

Swift のコード（[Package.swift](../../Package.swift)）:

```swift
swiftLanguageModes: [.v6]
```

Dart のコード（pubspec.yaml）:

```yaml
environment:
  sdk: ^3.6.0 # この下限が、そのパッケージの言語バージョンになる
```

違いと間違えやすいところ:

- Swift の言語モードは、新しいコンパイラでも古い判定に戻せます。Dart は SDK の下限で言語バージョンが決まり、別の設定はありません。
- Dart には Isolate がありますが、普段は使いません。Dart のデータ競合は、メモリを共有しない設計で避けています。Swift は、メモリを共有したままコンパイラが検査します。

出典:

- [Swift 6 Migration Guide](https://www.swift.org/migration/documentation/migrationguide/)
- [Dart language versioning](https://dart.dev/resources/language/evolution#language-versioning)

### target（モジュール）とアクセス制御

何の話か: アプリを、まとめてビルドする小さな部品に分ける単位です。

意味:

- target は、まとめてビルドされる 1 つのモジュールです。import するときの名前は、target の名前です。
- 何も書かないメンバーは `internal` で、同じ target の中でだけ見えます。外から使わせるには `public` を付けます。
- 例えるなら、Dart のパッケージです。ただし、Dart のパッケージは `pubspec.yaml` ごとに作り、Swift の target は 1 つの `Package.swift` の中に並べます。

Swift のコード（[Package.swift](../../Package.swift)、[PokemonPage.swift](../../core/Model/Sources/PokemonPage.swift)）:

```swift
.target(
    name: "Model",
    dependencies: ["Common"],
    path: "core/Model/Sources"
),
```

```swift
// core/Model/Sources/PokemonPage.swift（外に見せる型には public を付ける）
public struct PokemonPage: Equatable, Sendable {
    public var items: [PokemonSummary]
    public var hasNext: Bool

    public init(items: [PokemonSummary], hasNext: Bool) {
        self.items = items
        self.hasNext = hasNext
    }
}
```

Dart のコード:

```dart
// lib/src/pokemon.dart（パッケージの外からは見えない）
class Pokemon {}

// lib/model.dart（外に出すものだけを export する）
export 'src/pokemon.dart' show Pokemon;
```

違いと間違えやすいところ:

- Dart の見えるかどうかは、`_` を付けるかどうか（ライブラリ、つまりファイル単位）で決まります。Swift は、既定の `internal` が target 単位で、`public` と `internal` の線引きがモジュールの境界です。
- Dart は `lib/src/` に置いて `export` したものだけが、慣習として外から使える形になります。強制ではありません。Swift は `public` を付けないと、コンパイラが外からの使用を止めます。
- 骨組みの段階では、各 target に空に近いファイルが 1 つあるだけです。実装が入ると、外に見せる型に `public` を付ける必要があります。

ダメな例（別の target から `public` の無い型を使う）:

```swift
// Model 側が `struct Foo {}`（internal）のとき、Domain 側で
import Model
let x = Foo()  // エラー: cannot find 'Foo' in scope
```

出典:

- [Access Control（The Swift Programming Language）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/)
- [Target（PackageDescription）](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html)
- [Libraries and imports（Dart）](https://dart.dev/language/libraries)
- [Package layout conventions（Dart）](https://dart.dev/tools/pub/package-layout)

### product（外から使える形で公開するもの）

何の話か: 作った部品のうち、どれを外のアプリに渡すかを選ぶ設定です。

意味:

- product は、パッケージの外（ここでは Xcode のアプリ）がリンクできるものです。`.library` は、target をライブラリとして公開します。
- このリポジトリは、App ターゲットが直接リンクするものだけを公開します。それ以外の target は、同じパッケージの中でだけ使います。
- Dart には product に当たる設定がありません。パッケージの `lib/` にあるファイルが、そのまま公開の入口です。

Swift のコード（[Package.swift](../../Package.swift)）:

```swift
products: [
    // App ターゲット（app/App.xcodeproj）がリンクするものだけを公開する
    .library(name: "PokedexFeature", targets: ["PokedexFeature"]),
],
```

Dart のコード:

```dart
// lib/pokedex_feature.dart が、パッケージの入口（`lib/src/` は慣習で非公開）
export 'src/pokedex_page.dart' show PokedexPage;
```

違いと間違えやすいところ:

- Dart は、パッケージを依存に加えた側が `lib/` のファイルを import できます。Swift は、product を選んでリンクします。product に入れていない target は、外から import できません。
- `.library` は、target を束ねる箱です。1 つの product に複数の target を入れることもできます。このリポジトリは、1 つの product に 1 つの target です。
- 外部パッケージ側では、`.product(name:package:)` で product を指名して使います（次の項目）。

出典:

- [Product（PackageDescription）](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html)
- [Package layout conventions（Dart）](https://dart.dev/tools/pub/package-layout)

### target の依存（dependencies と path）

何の話か: ある部品が、どの別の部品や外部ライブラリを使うかを、部品ごとに書く設定です。

意味:

- `dependencies` に書いていない target は、import できません。依存は target ごとに宣言します。
- パッケージ内の target は名前の文字列で、外部パッケージの部品は `.product(name:package:)` で指名します。
- `path` は、ソースの置き場所を指定します。省略すると、`Sources/<target 名>` を探します。
- 例えるなら、`pubspec.yaml` の `dependencies:` です。ただし、Dart は依存をパッケージ単位で書き、Swift は target 単位で書きます。

Swift のコード（[Package.swift](../../Package.swift)）:

```swift
dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.17.2"),
],
targets: [
    .target(
        name: "NetworkClient",
        dependencies: [
            "Common",
            .product(name: "Dependencies", package: "swift-dependencies"),
        ],
        path: "core/NetworkClient/Sources"
    ),
]
```

Dart のコード（pubspec.yaml）:

```yaml
dependencies:
  pokedex_common:
    path: ../common
  riverpod: ^2.6.1
```

違いと間違えやすいところ:

- Dart は、パッケージの中の全ファイルが同じ `dependencies` を共有します。Swift は、同じパッケージの中でも、target ごとに別の依存を書けます。
- Dart の `path:` は、別のパッケージの場所を指します。Swift の `path:` は、その target のソースの場所です。意味が違います。
- Swift の依存は、直接書いていなくても、推移的な依存として import できてしまう場合があります。このリポジトリは、これを防ぐために自前の検査をしています（[依存チェック](../package-dependencies.md#依存チェック)）。Dart の `depend_on_referenced_packages` lint が近いものです。
- 外部ライブラリは、最初に使う Issue で追加します。この Issue の時点では、`dependencies:` は空でした。

出典:

- [Target.Dependency（PackageDescription）](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html)
- [Package dependencies（Dart）](https://dart.dev/tools/pub/dependencies)
- [depend_on_referenced_packages](https://dart.dev/tools/linter-rules/depend_on_referenced_packages)

### testTarget と Swift Testing、`@testable import`

何の話か: テスト用のコードを、本体とは別の部品として置き、本体の中身まで見せる仕組みです。

意味:

- `.testTarget` は、テストを入れる専用の target です。テスト対象と、TestSupport などの依存を書きます。
- `import Testing` は、Swift Testing というテストのライブラリです。Swift のツールチェーンに付く公式のライブラリで、`@Test` と `#expect` を使います。
- `@testable import Common` を書くと、`internal` のメンバーもテストから見えます。
- 骨組みの段階では、テストの中身は空です。

Swift のコード（[Package.swift](../../Package.swift)、[CommonTests.swift](../../core/Common/Tests/CommonTests.swift)）:

```swift
.testTarget(
    name: "CommonTests",
    dependencies: ["Common", "TestSupport"],
    path: "core/Common/Tests"
),
```

```swift
import Testing

@testable import Common
```

Dart のコード:

```dart
// test/common_test.dart
import 'package:test/test.dart';
import 'package:pokedex_common/src/common.dart'; // src を直接 import すれば内部も見える

void main() {
  test('...', () {
    expect(1 + 1, 2);
  });
}
```

違いと間違えやすいところ:

- Dart は、`lib/src/` のファイルを直接 import すれば、テストからも見えます（`_` の付いた名前は別）。Swift の `internal` は、`@testable import` を書かないと見えません。
- `@testable` が使えるのは、テスト用にビルドするときだけです。リリースのビルドでは使えません。
- Flutter のアプリでは、`package:test` の代わりに `flutter_test` を使うのが普通です。書き方は同じ形です。
- `dev_dependencies` に近いのは、`.testTarget` の `dependencies` です。テスト target ごとに依存を書きます。
- 骨組みの段階では、`@Test` が 1 つもないので、テストのケース数は 0 です。

出典:

- [Testing（Apple）](https://developer.apple.com/documentation/testing)
- [Access Control: Unit Test Targets](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/)
- [testTarget（PackageDescription）](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html)
- [package:test](https://pub.dev/packages/test)

### Xcode プロジェクトとローカルパッケージ参照

何の話か: アプリ本体を作る入れ物（Xcode プロジェクト）に、手元のパッケージを部品として取り込む設定です。

意味:

- `app/App.xcodeproj` が、iOS アプリの入れ物です。ルートの `Package.swift` を、ローカルパッケージとして参照します（`relativePath = ..`）。
- アプリのターゲットが、パッケージの product を選んでリンクします。
- Flutter の `ios/Runner.xcodeproj` も、同じ入れ物です。ただし、Flutter はアプリ本体を Dart で書き、Runner は Flutter のエンジンを載せる側に回ります。

Swift 側の実物: [app/App.xcodeproj](../../app/App.xcodeproj)、構成の理由は [ADR 0015](../adr/0015-xcode-project-structure.md)。pbxproj のうち、パッケージ参照は次の形です。

```text
XCLocalSwiftPackageReference ".." { relativePath = ..; }
XCSwiftPackageProductDependency { productName = PokedexFeature; }
```

Dart のコード（Flutter でも、別パッケージを手元のパスで参照するときは pubspec.yaml に書く）:

```yaml
dependencies:
  pokedex_domain:
    path: ../packages/domain
```

違いと間違えやすいところ:

- Flutter は、依存を `pubspec.yaml` で一元的に管理します。Swift の場合は、Package.swift で管理するモジュールと、Xcode プロジェクトでリンクする product を、両方に書きます。
- `project.pbxproj` は人が編集するファイルではありません。Xcode が書き換えます。Package.swift のように、中身をレビューするものではありません。
- このリポジトリの `app/Pokedex` は、Xcode の「同期されたフォルダー」で、フォルダーの中身が自動でターゲットに入ります。ファイルを足すたびに pbxproj を編集する必要はありません。

出典:

- [Adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
- [Creating a standalone Swift package with Xcode](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode)
- [Flutter の iOS 向けの設定](https://docs.flutter.dev/platform-integration/ios/setup)

### テストプラン（AllTests.xctestplan）

何の話か: 「どのテストを、どの設定で走らせるか」を一覧にしたファイルです。

意味:

- テストプランは、走らせるテスト target の一覧を JSON で持つファイルです。⌘U や `xcodebuild test` が、これを読みます。
- アプリの scheme は、ルートのパッケージのテスト target を自動では走らせません。そのため、このリポジトリは全テスト target をプランに登録します（[ADR 0015](../adr/0015-xcode-project-structure.md)）。
- Dart には相当するものがありません。`flutter test` が `test/` を自動で探すからです。

Swift 側の実物（[app/AllTests.xctestplan](../../app/AllTests.xctestplan)）:

```json
{
  "target": {
    "containerPath": "container:..",
    "identifier": "PokedexFeatureTests",
    "name": "PokedexFeatureTests"
  }
}
```

Dart のコード（相当なし。実行はコマンドだけ）:

```sh
flutter test            # test/ を自動で探して走らせる
flutter test test/foo_test.dart
```

違いと間違えやすいところ:

- Flutter は、新しいテストファイルを足すだけで走ります。Swift は、新しいテスト target を足したら、テストプランにも足す必要があります。足し忘れても、ビルドは通ります。
- テストプランは、実行の設定（並列、言語、環境変数など）も持てます。`flutter test` のオプションに近い役目です。
- このリポジトリでは、登録漏れを依存チェックのスクリプトが検出します。

出典:

- [Organizing tests to improve feedback](https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback)
- [Testing Flutter apps](https://docs.flutter.dev/testing/overview)

### `@main` と App プロトコル

何の話か: アプリの最初に動く場所を決める書き方です。

意味:

- `@main` を付けた型が、アプリの入口です。Dart の `main()` に当たります。
- SwiftUI の `App` プロトコルに従った型が、アプリの全体を表します。`body` に `Scene` を返し、`WindowGroup` がウィンドウを作ります。
- 例えるなら、`void main() => runApp(const MyApp());` を、型の宣言 1 つで書く形です。

Swift のコード（[PokedexApp.swift](../../app/Pokedex/PokedexApp.swift)）:

```swift
import SwiftUI

@main
struct PokedexApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Pokedex")
        }
    }
}
```

Dart のコード:

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: Text('Pokedex'));
}
```

違いと間違えやすいところ:

- Dart は `main()` という関数を書き、`runApp` を呼びます。Swift は関数を書かず、`@main` の属性が入口を作ります。
- `App` の `body` は `Scene` を返し、`Widget` ではありません。`Scene` の中に画面（`View`）を入れます。`MaterialApp` はテーマやナビゲーションを持つ Widget で、`App` / `WindowGroup` と役目が同じではありません。ここでは Text を置くために使っただけです。
- SwiftUI の `View` は `struct` で、状態を持つときは `@State` などの property wrapper を使います。Flutter の `StatelessWidget` / `StatefulWidget` の分け方とは違います。この Issue の時点では `Text` だけで、状態管理は出てきません。

出典:

- [App（SwiftUI）](https://developer.apple.com/documentation/swiftui/app)
- [WindowGroup（SwiftUI）](https://developer.apple.com/documentation/swiftui/windowgroup)
- [SE-0281: `@main`](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0281-main-attribute.md)
- [runApp（Flutter）](https://api.flutter.dev/flutter/widgets/runApp.html)

### `swift package describe`

何の話か: パッケージの中身（部品と、その依存）を、コマンドで一覧にして見る機能です。

意味:

- `swift package describe` は、`Package.swift` を読み込んだ結果を表示します。`--type json` を付けると、JSON で出ます。
- このリポジトリは、依存チェックのスクリプトが JSON を読み、各 target の直接依存を調べます。
- Dart の `dart pub deps` が近いです。こちらは、パッケージの依存の木を出します。

Swift のコード（[scripts/check-dependencies.swift](../../scripts/check-dependencies.swift)）:

```swift
process.arguments = ["swift", "package", "describe", "--type", "json"]
```

Dart のコード（コマンド）:

```sh
dart pub deps --json
```

違いと間違えやすいところ:

- `dart pub deps` は、パッケージ間の依存を出します。`swift package describe` は、パッケージの中の target ごとの依存まで出します。
- Swift の JSON の `target_dependencies` と `product_dependencies` で、パッケージ内の target と、外部の product を見分けられます。

出典:

- [Swift Package Manager のドキュメント](https://www.swift.org/documentation/package-manager/)
- [dart pub deps](https://dart.dev/tools/pub/cmd/pub-deps)

### `swift x.swift`（スクリプト実行）

何の話か: Swift のファイルを 1 つ指定して、そのまま動かす機能です。

意味:

- `swift scripts/check-dependencies.swift` のように、ファイルを渡すと、ビルド設定なしで実行できます。
- 小さな検査やツールを、Swift で書くときに使います。このリポジトリの依存チェックが、この形です。
- 例えるなら、`dart run tool/x.dart` です。

Swift のコード（[scripts/check-dependencies.swift](../../scripts/check-dependencies.swift)）:

```swift
import Foundation

let rootURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .deletingLastPathComponent()
```

Dart のコード（tool/check_dependencies.dart）:

```dart
import 'dart:io';

void main() {
  final root = File(Platform.script.toFilePath()).parent.parent;
  print(root.path);
}
```

違いと間違えやすいところ:

- Dart のスクリプトは `main()` が入口です。Swift のスクリプトは、ファイルの先頭から順に実行されます（`main.swift` と同じ扱い）。
- `#filePath` は、そのソースファイルのパスに置き換わるコンパイラの機能です。`Platform.script` は実行時の値です。
- Dart は `pubspec.yaml` の依存を使えます。Swift のスクリプトは、Foundation などの標準のモジュールだけで書いています。

出典:

- [Swift Package Manager のドキュメント](https://www.swift.org/documentation/package-manager/)
- [dart run](https://dart.dev/tools/dart-run)
- [Literal Expressions（`#filePath`）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/expressions/)

## 早見表

| Swift / iOS | Dart / Flutter での相当 | 違い | このリポジトリで使っている場所 |
| --- | --- | --- | --- |
| Package.swift | pubspec.yaml（複数まとめるなら Pub workspaces） | Swift のコードで書き、1 つで複数の target を持てる。Dart はパッケージごとに 1 つ | [Package.swift](../../Package.swift) |
| swift-tools-version と platforms | environment の sdk / flutter、Podfile の platform | tools-version は主に SwiftPM の版で、言語モードは別に指定する。OS の最低版は Xcode 側にも別に持つ | [Package.swift](../../Package.swift) |
| swiftLanguageModes | Dart の言語バージョン（sdk の下限） | Swift は新しいコンパイラでも古い判定に戻せる | [Package.swift](../../Package.swift) |
| target とアクセス制御（`internal` / `public`） | パッケージと `lib/src/` + `export`、`_` の非公開 | Swift は target 単位で、Dart は `_` がファイル単位。Swift は `public` が無いと外から使えない | [Package.swift](../../Package.swift) |
| product（`.library`） | `lib/` の公開ファイル | Swift は product を選んでリンクする。Dart は `lib/` のファイルを import できる | [Package.swift](../../Package.swift) |
| target の依存（`dependencies`、`path`） | pubspec の `dependencies`、`path:` | Swift は target ごとに依存を書き、`path` はソースの場所を指す。Dart の `path:` は別パッケージを指す | [Package.swift](../../Package.swift)、[依存チェック](../package-dependencies.md#依存チェック) |
| testTarget、Swift Testing、`@testable import` | `test/`、package:test、`dev_dependencies` | `@testable` が無いと `internal` が見えない。Dart は `lib/src/` を直接 import できる | [Package.swift](../../Package.swift)、[CommonTests.swift](../../core/Common/Tests/CommonTests.swift) |
| Xcode プロジェクトとローカルパッケージ参照 | ios/Runner.xcodeproj、pubspec の `path:` 依存 | Package.swift と、Xcode のリンクの 2 か所で管理する。pbxproj は Xcode が書き換える | [app/App.xcodeproj](../../app/App.xcodeproj) |
| テストプラン | 相当なし（`flutter test` が `test/` を自動で探す） | 走らせる target を明示する。足し忘れてもビルドは通る | [app/AllTests.xctestplan](../../app/AllTests.xctestplan) |
| `@main` と `App` | `main()` と `runApp` | 関数を書かず、属性で入口を作る。`body` は `Scene` を返す | [PokedexApp.swift](../../app/Pokedex/PokedexApp.swift) |
| `swift package describe` | `dart pub deps` | target ごとの依存まで出る | [scripts/check-dependencies.swift](../../scripts/check-dependencies.swift) |
| `swift x.swift` | `dart run tool/x.dart` | 先頭から順に実行され、`main()` は要らない | [scripts/check-dependencies.swift](../../scripts/check-dependencies.swift) |
