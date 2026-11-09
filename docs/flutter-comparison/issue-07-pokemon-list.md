# #7 ポケモン一覧

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/7

一覧画面で初めて出てきた Apple 標準（SwiftUI の `List`、`.task`、`@State` と `@Observable`）と外部ライブラリ（Nuke）を、Dart / Flutter の同じ層のものと比べる学習ノートです。前の Issue で説明した言葉（`@DependencyClient`、Swift Testing など）は [issue-06-network-client.md](issue-06-network-client.md) を見てください。

## Apple 標準

### List と onAppear（無限スクロール）

**何の話か:** 長い一覧を、画面に出た行だけ作って表示する部品と、行が画面に出た瞬間に処理を走らせる方法です。

**意味:** `List` は `UITableView` 相当で、行は画面に近づいたときに作られます。行の `onAppear` は、その行が画面に出たときに呼ばれます。最後の行の `onAppear` で次ページを読めば、無限スクロールになります。

```swift
ForEach(items) { item in
    PokemonRow(pokemon: item)
        .onAppear { if item.id == items.last?.id { store.send(.reachedBottom) } }
}
```

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, i) {
    if (i == items.length - 1) loadNext();
    return PokemonRow(items[i]);
  },
);
```

**違いと間違えやすいところ:** `onAppear` はスクロールで行が出入りするたびに何度も呼ばれます。Dart の `itemBuilder` も何度も呼ばれるので同じ注意が要り、どちらも「読み込み中は無視する」判定を状態側に持ちます。

**出典:** [onAppear(perform:)](https://developer.apple.com/documentation/swiftui/view/onappear(perform:))、[List](https://developer.apple.com/documentation/swiftui/list)

### task と Task（View から非同期処理を始める）

**何の話か:** 画面が出たときに非同期の読み込みを始める書き方です。

**意味:** `.task { }` は View が出たときに非同期処理を始め、View が消えると自動でキャンセルします。Store の `send` は `Task` を返し、テストはその `value` を `await` して完了を待てます。

```swift
.task { store.send(.onAppear) }
```

```dart
@override
void initState() {
  super.initState();
  controller.onAppear();
}
```

**違いと間違えやすいところ:** Dart の `Future` は作った時点で動き始めますが、Swift の `Task` も作った時点で動き始めます。違いは、`.task` が View の寿命に合わせて自動キャンセルする点です。Flutter では `dispose` で自分でキャンセルします。

**出典:** [task(priority:_:)](https://developer.apple.com/documentation/swiftui/view/task(priority:_:))

### @Observable と @State

**何の話か:** 状態が変わったら画面を作り直す仕組みです。

**意味:** `@Observable` を付けたクラスは、View が読んだプロパティが変わったときだけ、その View を更新します。View が自分でそのクラスを持つときは `@State` で持ちます。

```swift
@State private var store: PokemonListStore
```

```dart
final controller = ref.watch(pokemonListProvider); // Riverpod の例
```

**違いと間違えやすいところ:** Flutter の `ChangeNotifier` は `notifyListeners()` を自分で呼びますが、`@Observable` は読み取りを自動で追跡します。`@State` に入れないと、View が作り直されるたびに Store も作り直されます。

**出典:** [Observation](https://developer.apple.com/documentation/observation)、[State](https://developer.apple.com/documentation/swiftui/state)

## 外部ライブラリ

### Nuke（NukeUI の LazyImage）

**何の話か:** ネットの画像を表示して、メモリとディスクにキャッシュするライブラリです。

**意味:** `LazyImage(url:)` が読み込みとキャッシュを受け持ちます。このアプリでは DesignSystem の `RemoteImage` で包み、他のモジュールは Nuke を知りません（[ADR-0005](../adr/0005-external-libraries.md)）。

```swift
LazyImage(url: url) { state in
    if let image = state.image { image.resizable() } else { Color.clear }
}
```

```dart
CachedNetworkImage(
  imageUrl: url,
  placeholder: (_, __) => const SizedBox.shrink(),
  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
);
```

**違いと間違えやすいところ:** 役割は `cached_network_image` と同じです。ドット絵は拡大でぼけないよう `.interpolation(.none)` を付けています。

**出典:** [Nuke](https://github.com/kean/Nuke)
