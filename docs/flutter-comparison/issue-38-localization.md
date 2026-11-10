# #38 文字列の多言語対応（String Catalog）

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/38

画面の文字列を ja / en に出し分ける仕組みを、Dart / Flutter の `flutter_localizations` と `gen-l10n` と比べる学習ノートです。このリポジトリのルールは [docs/localization.md](../localization.md) にあります。

## Apple 標準

### String Catalog（1 ファイルに全言語）

**何の話か:** 画面に出す文字列と、その訳を置くファイルの形です。

**意味:** String Catalog（`Localizable.xcstrings`）は、1 つのファイルにキーと全言語の訳が入ります。Flutter の ARB は言語ごとにファイルが分かれます。

```json
"listRetryButton" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Retry" } },
    "ja" : { "stringUnit" : { "state" : "translated", "value" : "再試行" } }
  }
}
```

```json
// app_en.arb
{ "listRetryButton": "Retry" }
// app_ja.arb
{ "listRetryButton": "再試行" }
```

**違いと間違えやすいところ:** 新しい言語を足すとき、ARB はファイルを 1 つ増やし、String Catalog は同じファイルの中に訳を足します。String Catalog は 1 つのキーの全言語の訳を並べて見られ、ARB は言語ごとの差分が別ファイルになります。

**出典:** [Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)、[Internationalizing and localizing apps（Flutter）](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization)

### パッケージごとのカタログと bundle の落とし穴

**何の話か:** パッケージ（SwiftPM の target）に置いたカタログの訳を、どう引くかです。

**意味:** Swift では target ごとに String Catalog を持てます。Flutter でも package ごとに ARB と `l10n.yaml` を持てるので、パッケージごとに文言を持てること自体は同じです。違うのは、使う側の登録です。Flutter は `MaterialApp` の `localizationsDelegates` にそのパッケージの delegate を登録します。Swift に登録は要りません。代わりに、`Text("...")` は bundle を指定しないと `Bundle.main` を探すので、パッケージのカタログの訳が出ません。

```swift
// 訳が出ない（Bundle.main を探す）
Text("listNavigationTitle")
// 訳が出る（記号が target の bundle を持っている）
Text(.listNavigationTitle)
```

```dart
MaterialApp(
  localizationsDelegates: const [
    PokedexLocalizations.delegate, // パッケージごとに登録する
    GlobalMaterialLocalizations.delegate,
  ],
  supportedLocales: PokedexLocalizations.supportedLocales,
);
```

**違いと間違えやすいところ:** Flutter は登録を忘れると `Localizations.of` が null になって実行時に落ちるので気づけます。Swift の `bundle:` の付け忘れは、落ちずにキーがそのまま画面に出るだけなので気づきにくいです。

**出典:** [LocalizedStringResource](https://developer.apple.com/documentation/foundation/localizedstringresource)、[WWDC25 Code-along: Explore localization with Xcode](https://developer.apple.com/videos/play/wwdc2025/225/)

### 生成された記号（Xcode）と gen-l10n（Flutter）

**何の話か:** キーを文字列で書かずに、コードから型のあるものとして呼ぶ仕組みです。

**意味:** Xcode はビルドのたびに、カタログのキーから `LocalizedStringResource` の静的プロパティ（`.listRetryButton`）を作ります。Flutter の `flutter gen-l10n` は ARB から `AppLocalizations` クラスと、キーごとの getter を作ります。どちらもキーの打ち間違いをビルドで見つけられます。

```swift
Button(.listRetryButton) { store.send(.retryTapped) }
```

```dart
ElevatedButton(
  onPressed: retry,
  child: Text(AppLocalizations.of(context)!.listRetryButton),
);
```

**違いと間違えやすいところ:** `gen-l10n` は ARB の全キーにメソッドを作りますが、Xcode は `"extractionState" : "manual"` の印のあるキーだけに記号を作ります（詳細は [docs/localization.md](../localization.md#新しいキーの足し方)）。また、`gen-l10n` の生成ファイルの出力先は `l10n.yaml` の設定で変わります。Xcode の記号はビルドの中間ファイルにしか残りません。

**出典:** [WWDC25 Code-along: Explore localization with Xcode](https://developer.apple.com/videos/play/wwdc2025/225/)、[flutter gen-l10n](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization#setting-up)
