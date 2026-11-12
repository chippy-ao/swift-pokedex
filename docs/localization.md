# 文字列の多言語対応

画面に出す文字列を、端末の言語に合わせて ja / en に出し分けるための書き方です。言語の切り替え方針は [ADR-0007](adr/0007-localization.md)、ポケモン名など PokeAPI のデータの言語は [data-layer.md](data-layer.md#言語コードと変換ルール) を見てください。ここでは UI の文字列だけを扱います。

## 基本のルール

- String Catalog（`Localizable.xcstrings`）は target ごとに 1 つ持ち、その target の `Sources/` の直下に置きます。1 つのファイルに全言語の訳が入ります。
  - 今は [PokedexFeature](../feature/PokedexFeature/Sources/Localizable.xcstrings) だけが持っています。
  - アプリ本体（`app/Pokedex`）には別に [InfoPlist.xcstrings](../app/Pokedex/InfoPlist.xcstrings) があります（理由は[アプリ本体にも言語を持たせる](#アプリ本体にも言語を持たせる)）。
- 画面に出す文字列は、ベタ書きせずにカタログのキーから、Xcode が生成する記号で呼びます。

```swift
.navigationTitle(Text(.listNavigationTitle))
Button(.listRetryButton) { ... }
```

- 基準の言語（`sourceLanguage` と `Package.swift` の `defaultLocalization`）は英語です。

## キーの付け方

- キーは文言ではなく意味で付け、頭に画面の名前を付けます。例は `listNavigationTitle`、`listRetryButton`、`listErrorOffline` です。
- 画面名を付ける理由は、同じ target に一覧、詳細、お気に入りの画面があり、画面名が無いと `title` や `retry` のようなキーがぶつかるからです。

## 記号で呼ぶ理由

- 打ち間違いがビルドで分かります。`Text("listNavigationTitle")` のように文字列で書くと、間違えても実行時にキーがそのまま画面に出るだけです。
- パッケージ（SwiftPM の target）では、`Text("...")` に `bundle:` を付け忘れると `Bundle.main`（アプリ本体）を探すため、パッケージ側のカタログの訳が出ません。生成された記号は、その target の bundle を持っているので、この付け忘れが起きません。

## 基準の言語が英語の理由

- Xcode プロジェクトの `developmentRegion` が `en` です。
- 対応していない言語の端末では、基準の言語が表示されます。日本語でも英語でもない端末の持ち主には、英語のほうが読める見込みが高いです。
- `app/App.xcodeproj` の `knownRegions` には `ja` も足してあります。

## 新しいキーの足し方

1. 対応する target の `Localizable.xcstrings` に、キーと en / ja の訳を足します。Xcode のカタログエディタで足しても、JSON を直接編集してもかまいません。
2. 手で足したキーには `"extractionState" : "manual"` を付けます。WWDC25 のセッションで、Xcode は「手で足した文字列（manually added strings）」に対して記号を生成すると説明されています。`"extractionState" : "manual"` は、カタログ上で「手で足した」ことを示す印で、これが無いキーは生成の対象になりません。付けないと記号が 1 つも生成されない（生成ファイルが空になる）ことは、Xcode 27.2 で確かめています。
3. View では `Text(.キー名)` のように記号で呼びます。記号は `LocalizedStringResource` の静的プロパティで、ビルドのたびに Xcode が作ります。
4. 訳が言語ごとに引けることを、[ListStringsTests](../feature/PokedexFeature/Tests/ListStringsTests.swift) のように、言語を指定して `String(localized:)` で確かめるテストを足します。

## アプリ本体にも言語を持たせる

パッケージの String Catalog に ja / en の訳があるだけでは足りません。アプリ本体（`Pokedex.app`）自身にも ja / en を持たせます。

- `Bundle.main.preferredLocalizations` は、Apple のドキュメントでは「ユーザーの言語の設定と、bundle にある localization から決まる順序つきの一覧」です。WWDC19 のセッションでも「ユーザーの言語と、アプリの bundle が対応している言語の両方を見る」と説明されています。つまり、本体の bundle に言語が無ければ、ユーザーが日本語でも `ja` は返りません。
- このアプリでは、本体に言語が 1 つも入っていない状態で、一覧のポケモン名（[PreferredLocalization](../core/Domain/Sources/PreferredLocalization.swift) が `Bundle.main.preferredLocalizations.first` を読む）が日本語になりませんでした。ビルドした `Pokedex.app` を `ls` すると `en.lproj` も `ja.lproj` も無く、`app/App.xcodeproj` の `knownRegions` に `ja` を足してあるだけでは lproj はできませんでした（Xcode 27.2 で確認）。
- UI の文字はパッケージ（PokedexFeature）の bundle の訳を引くので、本体が言語を持っていなくても日本語で見えます。そのため、名前だけが英語のままという形で表に出ました。

持たせ方は、[InfoPlist.xcstrings](../app/Pokedex/InfoPlist.xcstrings) です。

- `sourceLanguage` は `en` で、キーは `CFBundleDisplayName`（ホーム画面のアプリ名）だけです。en は `Pokedex`、ja は `ポケモン図鑑` にしています。
- `app/Pokedex` は Xcode の同期フォルダ（`PBXFileSystemSynchronizedRootGroup`）なので、フォルダに置くだけで target に入ります。ビルドすると `Pokedex.app` に `en.lproj/InfoPlist.strings` と `ja.lproj/InfoPlist.strings` ができ、`Bundle.main.preferredLocalizations` が ja を返すようになります（UI テストで確認。[development.md](development.md#ui-テスト)）。
- Info.plist に `CFBundleLocalizations` は足していません。lproj があれば足りたためです。

アプリごとの言語の設定は、アプリが自分で言語を切り替えるのではなく、設定アプリの項目を使うのが Apple の推奨です（WWDC19 403）。設定アプリにアプリ別の項目が出る条件は、このアプリでは確かめていません。

## 出典

- WWDC25「Code-along: Explore localization with Xcode」: https://developer.apple.com/videos/play/wwdc2025/225/
- WWDC19 セッション 403: https://developer.apple.com/wwdc19/403 （アプリごとの言語の設定、`Bundle.main.preferredLocalizations` と `Locale.preferredLanguages` の違い）
- `preferredLocalizations`（Apple）: https://developer.apple.com/documentation/foundation/bundle/preferredlocalizations
