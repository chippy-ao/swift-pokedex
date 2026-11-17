# #10 名前で検索する

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/10

一覧の名前検索の画面で初めて出てきたもの（`.searchable`、`Binding(get:set:)`、`ContentUnavailableView.search`）を、Dart / Flutter の同じ層のものと比べる学習ノートです。前の Issue で説明した言葉は [issue-07-pokemon-list.md](issue-07-pokemon-list.md) を見てください。

## Apple 標準

### .searchable と SearchBar

**何の話か:** 一覧の上に検索欄を出して、入力した文字を受け取る方法です。

**意味:** `.searchable(text:placement:)` は、画面（`NavigationStack` の中の View）に付けると、ナビゲーションバーに検索欄を足します。欄の見た目、キーボード、キャンセルボタンはシステムが作ります。`PokemonListView` は、`displayMode: .always` で、スクロールしても欄が消えないようにしています。Flutter の Material 3 には `SearchBar` があります。ただし置く場所は自分で決めます（`AppBar` の下に `PreferredSize` で入れる、`ListView` の先頭に置く、など）。

```swift
// PokemonListView.body
content
    .searchable(
        text: Binding(
            get: { store.state.query },
            set: { store.send(.queryChanged($0)) }),
        placement: .navigationBarDrawer(displayMode: .always))
```

```dart
Scaffold(
  appBar: AppBar(
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: SearchBar(onChanged: (text) => store.send(QueryChanged(text))),
    ),
  ),
  body: content,
);
```

**違いと間違えやすいところ:** `.searchable` は画面の中に欄を置く部品ではなく、ナビゲーションバーに付ける修飾子です。`NavigationStack` の外の View に付けても欄は出ません。Flutter の `SearchBar` はふつうの Widget なので、置いた場所に出ます。

**出典:** [searchable(text:placement:prompt:)（Apple）](https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:))、[SearchBar（Flutter）](https://api.flutter.dev/flutter/material/SearchBar-class.html)

### Binding(get:set:) と TextField の onChanged

**何の話か:** Store が持つ文字を、検索欄に読み書きさせる橋渡しです。

**意味:** `.searchable` の `text:` は `Binding<String>`（読み書きできる参照）を求めます。このアプリの文字は Store の `state.query` にあり、書き換えは Action 経由だけです。そこで、`get` で State を読み、`set` で Action を送る `Binding` をその場で作ります。Flutter で同じ形にするなら、`TextField` の `controller.text` を State から出し、`onChanged` で Action を送ります。

**違いと間違えやすいところ:** `Binding` は 1 つの値で「読む」と「書く」を両方持ちます。Flutter の `TextField` は読み（`controller`）と書き（`onChanged`）が別々の引数です。

**出典:** [Binding（Apple）](https://developer.apple.com/documentation/swiftui/binding)、[TextField（Flutter）](https://api.flutter.dev/flutter/material/TextField-class.html)

### ContentUnavailableView.search と空の表示

**何の話か:** 検索の結果が 0 件のときに出す表示です。

**意味:** `ContentUnavailableView.search(text:)` は、虫眼鏡のアイコンと「"〇〇" の検索結果なし」のような文を、システムの言語で出す部品です。このアプリは、文言もボタンも足さずにそのまま使います（[README](../../feature/PokedexFeature/README.md) の「空」の行）。Flutter の標準には、これに当たる部品は見つかりません。`Center` と `Column` で、アイコンと `Text` を自分で並べるのがふつうです。文言の翻訳も自分で持ちます。

```swift
if results.isEmpty {
    ContentUnavailableView.search(text: query)
}
```

```dart
if (results.isEmpty) {
  Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.search_off, size: 48),
      Text(l10n.noResults(query)), // 文言と翻訳は自分で用意する
    ]),
  );
}
```

**違いと間違えやすいところ:** `.search(text:)` の文は、システムが翻訳を持っているので、このアプリの `Localizable.xcstrings` には入っていません。文言を変えたいときは、`ContentUnavailableView` の別の init（ラベルと説明を自分で渡す形）に替えます。

**出典:** [ContentUnavailableView（Apple）](https://developer.apple.com/documentation/swiftui/contentunavailableview)
