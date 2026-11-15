# #53 ロジックのテストを macOS で回す

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/53
- 決めた経緯: https://github.com/chippy-ao/swift-pokedex/issues/55

ロジックのテストを、シミュレーターなしで Mac 上で回すようにした Issue です。ここでは、テストが「どこで動くか」が Flutter と違う点と、それを選ぶ Xcode の部品（scheme、`-destination`）を比べます。mise のタスクや CI のジョブの分け方は言語に依らないので扱いません。

## 目次

- [テストはどの OS で動くか（ホストで動くテストと、iOS で動くテスト）](#テストはどの-os-で動くかホストで動くテストと-ios-で動くテスト)
- [画面の絵を撮るテスト（golden とスナップショット）](#画面の絵を撮るテストgolden-とスナップショット)
- [何を動かすかを選ぶ（scheme と `-destination`）](#何を動かすかを選ぶscheme-と--destination)
- [早見表](#早見表)

### テストはどの OS で動くか（ホストで動くテストと、iOS で動くテスト）

何の話か: 同じ「単体テスト」でも、Dart ではいつも自分の Mac の上で動きますが、Swift では「どの OS 向けにビルドしたか」で動く場所が決まる、という話です。

意味:

- Swift は、ビルドするときに、その OS 向けの機械語に変えます。iOS 向けにビルドしたテストは、iOS の上（シミュレーターか実機）でしか動きません。
- 同じコードを macOS 向けにもビルドできるなら、そのテストは Mac でそのまま動きます。シミュレーターを起動する必要がありません。
- このリポジトリでは、ロジックのモジュール（Domain、Repository、NetworkClient など）が UIKit に頼っていないので、macOS 向けにもビルドできます。UI のモジュール（DesignSystem、SharedUI、各 Feature）は SwiftUI の部品を使うため、iOS でしか動かしません。
- 「macOS 向けにもビルドする」は、`Package.swift` の `platforms` に書きます。

Swift 側（このリポジトリ）:

[Package.swift](../../Package.swift) の 11 行目:

```swift
platforms: [.iOS(.v26), .macOS(.v26)],
```

テストを Mac で動かすコマンドは、[mise.toml](../../mise.toml) の `tasks.test-logic` にあります。

```sh
xcodebuild test -scheme LogicTests -destination platform=macOS
```

Dart 側（普段の Flutter で同じことをする書き方）:

```sh
dart test            # 純 Dart のパッケージ
flutter test         # Flutter のアプリ。ウィジェットのテストも含む
```

違いと間違えやすいところ:

- `dart test` と `flutter test` は、Mac 上の Dart VM（または Flutter のテスト用のエンジン）で動きます。`flutter test` が iOS のシミュレーターを使うことはありません。
- Swift には、この「ホストの VM で動かす」仕組みがありません。macOS 向けにビルドできるモジュールだけが Mac で動き、それ以外は iOS の上で動かします。
- そのため、ロジックのモジュールに UIKit などの iOS 専用の API を `import` すると、macOS 向けのビルドが止まります。Dart で `dart:ui` を使うと純 Dart のテストが動かなくなるのと、起きることは似ています。このリポジトリでは、これをモジュールの境界を守る仕組みとして使っています（`#if canImport(UIKit)` で囲って逃がす案は、囲い忘れで壊れるため採りませんでした）。
- `Package.swift` に `.macOS(.v26)` を足しても、UI のモジュールが macOS でビルドできるようにはなりません。UI のモジュールを macOS でビルドしないのは、scheme に入れないことで実現しています（次の項目）。

出典:

- [Supporting multiple platforms in Swift packages（Apple）](https://developer.apple.com/documentation/xcode/supporting-multiple-platforms-in-your-package)
- [xcodebuild(1)](https://keith.github.io/xcode-man-pages/xcodebuild.1.html)（`-destination`）
- [Testing Flutter apps（Flutter）](https://docs.flutter.dev/testing/overview)

### 画面の絵を撮るテスト（golden とスナップショット）

何の話か: 画面を画像にして、参照画像と比べるテストが、どこで撮れるかの違いです。

意味:

- Flutter の golden テスト（`matchesGoldenFile`）は、Flutter 自身の描画エンジンで画面を描くので、Mac の上で撮れます。
- SwiftUI の画面は、iOS の部品（UIKit や Core Animation）で描かれます。そのため、iOS の絵は iOS の上でしか撮れません。このリポジトリのスナップショットテストは、固定したシミュレーターの上で撮ります（[ADR 0020](../adr/0020-snapshot-tests-with-host-app.md)）。

Swift 側（このリポジトリ）:

[AssertScreenSnapshots.swift](../../core/SnapshotTestSupport/Sources/AssertScreenSnapshots.swift) の 46 行目の `drawHierarchyInKeyWindow: true` は、実際に画面に出した View を iOS の仕組みで描いて撮る指定です。撮る環境（端末、OS）を固定する理由もここにあります。

Dart 側（普段の Flutter で同じことをする書き方）:

```dart
await expectLater(find.byType(DetailPage), matchesGoldenFile('detail.png'));
```

違いと間違えやすいところ:

- Flutter の golden は、OS が違っても同じエンジンが描くので、原理的には同じ絵になります（フォントなどで差が出ることはあります）。SwiftUI は OS の部品が描くので、OS や端末が違えば絵が変わります。
- そのため、スナップショットのテストは `mise run test-ui`（iOS Simulator）に残し、`LogicTests` には入れません。

出典:

- [Testing Flutter apps（Flutter）](https://docs.flutter.dev/testing/overview)（golden テスト）
- [swift-snapshot-testing（Point-Free）](https://github.com/pointfreeco/swift-snapshot-testing)

### 何を動かすかを選ぶ（scheme と `-destination`）

何の話か: `xcodebuild test` に「どのテストを、どの OS 向けにビルドして動かすか」を伝える 2 つの指定です。

意味:

- scheme は、「どの target をビルドして、どのテストを動かすか」を書いた設定ファイルです。このリポジトリでは、ロジックのテスト target だけを並べた scheme `LogicTests` を [LogicTests.xcscheme](../../.swiftpm/xcode/xcshareddata/xcschemes/LogicTests.xcscheme) に置いています（`BlueprintIdentifier` がテスト target の名前）。
- `-destination` は、「どの OS・端末向けにビルドして動かすか」です。`platform=macOS` なら Mac、`platform=iOS Simulator,...` ならシミュレーターです。
- この 2 つで、同じ `Package.swift` のコードを「Mac で動かす部分」と「iOS で動かす部分」に分けています。

Swift 側（このリポジトリ）:

```sh
# Mac で、ロジックのテストだけ
xcodebuild test -scheme LogicTests -destination platform=macOS
# シミュレーターで、それ以外（ロジックのテストは外す）
xcodebuild test -project app/App.xcodeproj -scheme Pokedex -testPlan AllTests \
  -destination "platform=iOS Simulator,name=iPhone 17,OS=27.2" -skip-testing:CommonTests ...
```

[mise.toml](../../mise.toml) の `tasks.test-logic` と `tasks.test-ui` にあります。`-skip-testing` に渡す名前は、scheme から読んでいます。

Dart 側（普段の Flutter で同じことをする書き方）:

```sh
flutter test test/domain      # パスで範囲を絞る
```

違いと間違えやすいところ:

- scheme や `-destination` にそのまま当たるものは、Flutter にありません。`flutter test` は `test/` を自分で探し、動かす場所はいつもホストだからです。範囲はパスで絞ります。
- scheme は、`.xcscheme` という XML のファイルです。`Package.swift` のルートに置く場合は `.swiftpm/xcode/xcshareddata/xcschemes/` に置くと、Xcode と `xcodebuild` が共有 scheme として見つけます。このリポジトリでは、`.gitignore` で `.swiftpm/` のうちこの場所だけを追跡しています。
- テスト target を足したら、scheme にも足す必要があります。足さないと Mac では動きません。Flutter の `test/` に足したファイルが自動で見つかるのとは違います。

出典:

- [Customizing the build schemes for a project（Apple）](https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project)
- [xcodebuild(1)](https://keith.github.io/xcode-man-pages/xcodebuild.1.html)（`-scheme`、`-destination`、`-skip-testing`）

## 早見表

| Swift / iOS | Dart / Flutter での相当 | 違い | このリポジトリで使っている場所 |
| --- | --- | --- | --- |
| `platforms` に `.macOS` を足す | 相当なし（`flutter test` はいつもホストで動く） | OS 向けにビルドするので、動く場所がビルドで決まる | [Package.swift](../../Package.swift) |
| macOS 向けにビルドしたテスト | `dart test` / `flutter test` | Flutter はホストの VM で動く。Swift はビルドできるモジュールだけ Mac で動く | [mise.toml](../../mise.toml) の `tasks.test-logic` |
| スナップショットのテスト | golden テスト | Flutter は自前のエンジンでホストでも撮れる。SwiftUI は iOS の上でしか撮れない | [AssertScreenSnapshots.swift](../../core/SnapshotTestSupport/Sources/AssertScreenSnapshots.swift) |
| scheme と `-destination` | 相当なし（`test/` のパスで絞る） | scheme が target を、`-destination` が動かす OS を選ぶ | [LogicTests.xcscheme](../../.swiftpm/xcode/xcshareddata/xcschemes/LogicTests.xcscheme) |
