# #9 スナップショットテスト

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/9
- 決めた経緯: [ADR 0020](../adr/0020-snapshot-tests-with-host-app.md)

画面を画像にして、コミットした参照画像と比べるテスト（スナップショットテスト）を入れた Issue です。Swift は外部ライブラリの swift-snapshot-testing（Point-Free）、Flutter は標準の `flutter_test` の golden テスト（`matchesGoldenFile`）で、層が違います。画像の比較を足す別のパッケージ（`golden_toolkit` など）は、確かめていないので扱いません。

[#53 のノート](issue-53-logic-tests-on-macos.md#画面の絵を撮るテストgolden-とスナップショット)で、「golden は Mac 上で撮れるが、SwiftUI は iOS の上でしか撮れない」ことは書きました。ここでは、その先の使い方の違いを書きます。

## 目次

- [参照画像と比べる（assertSnapshot と matchesGoldenFile）](#参照画像と比べるassertsnapshot-と-matchesgoldenfile)
- [参照画像を撮り直す（記録のモードと --update-goldens）](#参照画像を撮り直す記録のモードと---update-goldens)
- [描画の違いと環境の固定（Ahem フォントと実機の描画）](#描画の違いと環境の固定ahem-フォントと実機の描画)
- [比べ方の許容（precision と perceptualPrecision）](#比べ方の許容precision-と-perceptualprecision)
- [参照画像の置き場所](#参照画像の置き場所)
- [場面を Preview と共有する](#場面を-preview-と共有する)
- [早見表](#早見表)

### 参照画像と比べる（assertSnapshot と matchesGoldenFile）

何の話か: 画面を画像にして、前にコミットした画像と同じかを調べるテストの書き方です。

意味:

- 初めて撮ったときは、画像をファイルに書き出します。次からは、撮った画像とそのファイルを比べ、違えばテストが失敗します。
- このリポジトリでは、`assertSnapshot`（swift-snapshot-testing）を直接呼ばず、ライトとダークの両方で撮る自作の関数 `assertScreenSnapshots` を通しています。

Swift 側（このリポジトリ）:

[PokemonListSnapshotTests.swift](../../app/PokedexSnapshotTests/PokemonListSnapshotTests.swift) の `scenarios()`:

```swift
let screens = await SnapshotScreens.pokemonList()
#expect(screens.map(\.name).sorted() == ["errorOffline", "loaded"])
for screen in screens {
    assertScreenSnapshots(of: screen.view, testName: screen.name)
}
```

`assertScreenSnapshots` は [AssertScreenSnapshots.swift](../../core/SnapshotTestSupport/Sources/AssertScreenSnapshots.swift) にあり、中で `verifySnapshot`（`assertSnapshot` の、失敗を値で返す版）を呼びます。

Dart 側（普段の Flutter で同じことをする書き方）:

```dart
testWidgets('list', (tester) async {
  await tester.pumpWidget(const ListPage());
  await expectLater(find.byType(ListPage), matchesGoldenFile('list.png'));
});
```

違いと間違えやすいところ:

- `matchesGoldenFile` は、`Finder` か画像（`ui.Image`）を受け取るマッチャーで、`expectLater` で await します（[matchesGoldenFile（Flutter API）](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)）。Swift 側は、描く対象を「撮る戦略（`.image(...)`）」と一緒に渡します。同じ値を、画像だけでなく文字列の構造などでも比べられる作りです。このリポジトリでは画像しか使いません。
- Swift 側は、1 回の呼び出しが 1 枚です。ライトとダークの 2 枚を撮るために、自作の関数で包んでいます。
- 参照画像が無いときの扱いは、ライブラリの記録のモード（次の項目）で決まります。CI では、無いこと自体を失敗にしています。

出典:

- [swift-snapshot-testing（Point-Free）](https://github.com/pointfreeco/swift-snapshot-testing)
- [matchesGoldenFile（Flutter API）](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)

### 参照画像を撮り直す（記録のモードと --update-goldens）

何の話か: 画面を意図して変えたとき、参照画像を新しいものに置き換える方法です。

意味:

- swift-snapshot-testing は、記録のモード（`all` / `failed` / `missing` / `never`）で動きを切り替えます。`all` は何があっても書き出し、`missing` は無い画像だけ書き出し、`never` は書き出さず、無ければ失敗にします（ライブラリの `SnapshotTestingConfiguration` のコメント）。
- このリポジトリでは、環境変数 `SNAPSHOT_TESTING_RECORD` で指定します。撮り直しは `mise run snapshot-record`（`all`）、CI は `never` です。
- 記録のモードでは、画像を書いたテストは「記録した」という失敗で終わります。それは想定どおりなので、`snapshot-record` は終了コード 0 にしています。

Swift 側（このリポジトリ）:

[mise.toml](../../mise.toml) の `tasks.snapshot-record`:

```sh
TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all xcodebuild test ... -only-testing:PokedexSnapshotTests
```

Dart 側（普段の Flutter で同じことをする書き方）:

```sh
flutter test --update-goldens
```

違いと間違えやすいところ:

- Flutter は、実行時のフラグ `--update-goldens` の 1 つで「作る・更新する」を切り替えます（[matchesGoldenFile（Flutter API）](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)）。Swift 側は 4 つのモードがあり、「失敗した画像だけ書き換える（`failed`）」のような使い分けができます。
- Flutter の更新のフラグは、`flutter test` が受け取るものです。Swift は `xcodebuild` を経由するので、環境変数を `TEST_RUNNER_` 付きで渡す必要があります（xcodebuild が、テストのプロセスへ渡す決まり）。
- 撮り直した画像は、期待値を書き換えたことになります。どちらも、画像を見て意図した差だけかを確かめてからコミットします。

出典:

- [swift-snapshot-testing（Point-Free）](https://github.com/pointfreeco/swift-snapshot-testing)（`SnapshotTestingConfiguration` のコメント）
- [matchesGoldenFile（Flutter API）](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)

### 描画の違いと環境の固定（Ahem フォントと実機の描画）

何の話か: 撮った画像がどれだけ本物の見た目に近いかと、そのために固定するものです。

- Flutter の golden は、既定ではテスト用のフォント Ahem で文字を描きます。Ahem は文字の代わりに四角を描くフォントです（[matchesGoldenFile（Flutter API）](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)）。
- このリポジトリは、ホストアプリ付きのテストでシミュレーターの本物の描画を撮ります（[ADR 0020](../adr/0020-snapshot-tests-with-host-app.md)）。文字も Liquid Glass のボタンも実機に近い絵になるかわりに、端末・OS・言語・文字サイズで絵が変わります。そこで iPhone 17・iOS 27.2・英語・既定の文字サイズに固定し、違う環境では撮らずに失敗にします（[SnapshotEnvironment](../../core/SnapshotTestSupport/Sources/SnapshotEnvironment.swift)。値は [mise.toml](../../mise.toml) と同じにそろえる）。
- ここで比べているのは Flutter の既定（Ahem）の構成です。実際のフォントで撮る構成の環境差は、確かめていないので書きません。
- Liquid Glass は標準の撮り方（`layer.render`）では白紙になるので、実際に画面へ出して描く `drawHierarchyInKeyWindow: true` が要ります。Flutter に相当する悩みはありません（[Issue #1029](https://github.com/pointfreeco/swift-snapshot-testing/issues/1029)）。

### 比べ方の許容（precision と perceptualPrecision）

何の話か: 画像が少しだけ違うときに、失敗にするか通すかの指定です。

- `precision` は一致すべきピクセルの割合、`perceptualPrecision` は 1 ピクセルの色がどれだけ近ければ同じとみなすかです（ライブラリのコメント。98〜99% が人の目の精度）。このリポジトリは `precision: 1`、`perceptualPrecision: 0.98` で、アンチエイリアスなど目に見えない揺れだけを許します。指定は [AssertScreenSnapshots.swift](../../core/SnapshotTestSupport/Sources/AssertScreenSnapshots.swift) の `.image(...)` にあります。
- Flutter の標準の `LocalFileComparator` は、デコードした PNG をピクセルごとに比べ、完全一致のときだけ通します。ドキュメントに許容の記述はありません（[LocalFileComparator（Flutter API）](https://api.flutter.dev/flutter/flutter_test/LocalFileComparator-class.html)）。Swift 側は呼び出しごとに許容を渡せます。
- `perceptualPrecision` を下げすぎると、本当に変わった色も通ります。誤検知が出たときに見直す値です。

### 参照画像の置き場所

何の話か: 参照画像のファイルをどこに置くかです。このリポジトリでは Xcode の都合で、既定から変えました。

- 既定は、テストのファイルの隣の `__Snapshots__/<テストのファイル名>/` です。このリポジトリでは、画面の持ち主の `feature/<feature 名>/Tests/__Snapshots__/<テストのファイル名>/` に置きます。テストのファイルは `app/` の Xcode のテスト target（フォルダ同期）にあり、その中に PNG があると、Xcode が成果物へコピーして名前がぶつかるためです。詳しい理由と求め方は [SnapshotDirectory.swift](../../core/SnapshotTestSupport/Sources/SnapshotDirectory.swift) のコメントにあります。
- Flutter の golden は、キーを「テストのファイルのフォルダからの相対パス」として読むので、`test/` の下に置けます（[LocalFileComparator（Flutter API）](https://api.flutter.dev/flutter/flutter_test/LocalFileComparator-class.html)）。ここでも画像は feature の `Tests` の下で、同じ形です。違いは 2 つあります。Xcode はテストを 1 つの成果物（`.xctest`）にまとめ、同期フォルダの中のファイルを取り込むので、テストの隣には置けず、呼ぶ側が `feature:` で名前を渡します。また、`Tests` は SwiftPM のテスト target の path なので、`Package.swift` の `exclude` で画像のフォルダを外します。この指定に当たるものは、Flutter の側では確認した範囲で見当たりません。
- `snapshotDirectory:` の引数があるのは `verifySnapshot` だけで、`assertSnapshot` にはありません。そのため `verifySnapshot` を呼び、失敗を自分で `Issue.record` に渡しています（[AssertSnapshot.swift](https://github.com/pointfreeco/swift-snapshot-testing/blob/main/Sources/SnapshotTesting/AssertSnapshot.swift)）。

### 場面を Preview と共有する

何の話か: テストで撮る画面の状態（読み込み済み、エラーなど）を、Xcode の Preview と同じ定義で使う話です。

意味:

- 場面を `enum PokemonListScenario: CaseIterable` で 1 か所に定義し、`#Preview` もスナップショットもそれを使います。場面を足すと、Preview もスナップショットも自動で増えます。
- スナップショットのテストは、Package.swift の外（Xcode プロジェクト側）にあるため、場面を `public` にし、Release に入らないよう `#if DEBUG` で囲んでいます。

Swift 側（このリポジトリ）:

[PokemonListView.swift](../../feature/PokedexFeature/Sources/List/PokemonListView.swift) の末尾:

```swift
#if DEBUG
    #Preview("読み込み済み") { PokemonListScenario.loaded.makeView() }
#endif
```

[SnapshotScreens.swift](../../app/Pokedex/SnapshotScreens.swift) の `pokemonList()` は、同じ `PokemonListScenario.allCases` を使います。

Dart 側:

相当する標準の仕組みは、確認した範囲では見つかりませんでした。

違いと間違えやすいところ:

- `#Preview` は、Xcode が画面をその場で描く、Apple 標準の仕組みです。Flutter には、確認した範囲では、標準で同じ場面を Preview とテストで共有する仕組みがありません。別のパッケージで作れるかは確かめていないので扱いません。
- Swift 側の共有は、言語の仕組み（`CaseIterable`、`#if DEBUG`）と、Xcode の Preview を組み合わせたものです。`CaseIterable` は、場面を足したときにテストの側を直さなくてよくする役目です。
- ただし、テストが撮る場面の名前の一覧は、テストに書き写しています（`["errorOffline", "loaded"]`）。`loading` は ProgressView が回り続けて毎回違う画像になるので撮りません。場面が空になって何も撮らずに通る事故を防ぐための確認です。

出典:

- [Previews in Xcode（Apple）](https://developer.apple.com/documentation/swiftui/previews-in-xcode)
- [ADR 0020](../adr/0020-snapshot-tests-with-host-app.md)

## 早見表

| Swift / iOS | Dart / Flutter での相当 | 違い | このリポジトリで使っている場所 |
| --- | --- | --- | --- |
| `assertSnapshot` / `verifySnapshot`（外部ライブラリ） | `matchesGoldenFile`（標準の `flutter_test`） | 層が違う。Swift は外部ライブラリ、Flutter は標準 | [AssertScreenSnapshots.swift](../../core/SnapshotTestSupport/Sources/AssertScreenSnapshots.swift) |
| 記録のモード（`SNAPSHOT_TESTING_RECORD`） | `flutter test --update-goldens` | Swift は 4 つのモード。Flutter は更新のフラグ 1 つ | [mise.toml](../../mise.toml) の `tasks.snapshot-record` |
| シミュレーターの本物の描画 | 既定は Ahem フォント | Swift は環境を固定する必要がある | `SnapshotEnvironment` |
| `precision` / `perceptualPrecision` | `LocalFileComparator`（完全一致、許容の記述なし） | Swift は呼び出しごとに許容を渡せる | [AssertScreenSnapshots.swift](../../core/SnapshotTestSupport/Sources/AssertScreenSnapshots.swift) |
| `feature/<feature 名>/Tests/__Snapshots__/`（同期フォルダの外） | テストの隣の相対パス | Xcode は同期フォルダの PNG を成果物へコピーする | [SnapshotDirectory.swift](../../core/SnapshotTestSupport/Sources/SnapshotDirectory.swift) |
| `PokemonListScenario`（Preview と共有） | 標準の相当なし | `CaseIterable` と `#Preview` の組み合わせ | [PokemonListScenario.swift](../../feature/PokedexFeature/Sources/List/PokemonListScenario.swift) |
