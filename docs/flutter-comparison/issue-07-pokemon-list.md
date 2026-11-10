# #7 ポケモン一覧

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/7

一覧画面で初めて出てきた Apple 標準（SwiftUI の `List`、`.task`、`@State` と `@Observable`、`@ViewBuilder`）と外部ライブラリ（Nuke）を、Dart / Flutter の同じ層のものと比べる学習ノートです。前の Issue で説明した言葉（`@DependencyClient`、Swift Testing など）は [issue-06-network-client.md](issue-06-network-client.md) を見てください。

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

### @ViewBuilder と let（body の中で分岐する）

**何の話か:** 状態によって出す View を切り替える書き方です。

**意味:** `body` や `@ViewBuilder` の中では、`if` や `switch` がそのまま View の分岐になり、`let` で値を置けます。一覧では、items が空なら全面表示、あれば `List` と切り替え、`phase` で末尾の表示を `switch` で選んでいます。

```swift
@ViewBuilder
private func footer(_ state: State) -> some View {
    switch state.phase {
    case .loading: ProgressView()
    case .failed(let error): Text(message(for: error))
    case .idle, .loaded: EmptyView()
    }
}
```

```dart
Widget footer(State state) => switch (state.phase) {
  Loading() => const CircularProgressIndicator(),
  Failed(:final error) => Text(message(error)),
  _ => const SizedBox.shrink(),
};
```

**違いと間違えやすいところ:** 何も出さないときは `EmptyView()` を返します。Dart の `SizedBox.shrink()` に近い使い方です。`switch` は全ケースを書かないとコンパイルが通らないので、`phase` に状態を足すと View の直しもれに気づけます。

**出典:** [ViewBuilder](https://developer.apple.com/documentation/swiftui/viewbuilder)

### @MainActor と @Observable の Store

**何の話か:** 画面の状態を 1 か所に持ち、画面だけが読む入れ物です。

**意味:** Store は `@MainActor @Observable final class` で、`send(_ action:)` だけが状態を変えます。画面の更新はメインスレッドで行うので `@MainActor` を付け、`await` のあとに戻っても状態を書き換えられます。`@Dependency` のようにプロパティラッパーで持つ値は `@ObservationIgnored` を付けて監視から外します。

```swift
@MainActor @Observable
final class PokemonListStore {
    private(set) var state = State()
    @ObservationIgnored @Dependency(\.fetchPokemonPage) private var fetchPokemonPage
}
```

```dart
class PokemonListNotifier extends Notifier<State> {
  @override
  State build() => const State();
  Future<void> load(int offset) async { /* state = ... */ }
}
```

**違いと間違えやすいところ:** Riverpod の `Notifier` は `state` に代入すると購読者へ通知されます。`@Observable` は View が読んだプロパティだけを追跡します。Dart は 1 スレッドで動くので、`@MainActor` に当たる指定はありません。

**出典:** [MainActor](https://developer.apple.com/documentation/swift/mainactor)、[Observation](https://developer.apple.com/documentation/observation)

### @discardableResult

**何の話か:** 戻り値を使わなくても警告が出ない関数にする指定です。

**意味:** `send` は読み込みを始めたときだけ `Task` を返し、テストはそれを `await` して完了を待ちます。View は戻り値を使わないので `@discardableResult` を付けています。

```swift
@discardableResult
func send(_ action: Action) -> Task<Void, Never>? { ... }
```

```dart
Future<void>? send(Action action) { ... } // 呼び出し側が await しなくてもよい
```

**違いと間違えやすいところ:** Swift は戻り値を捨てると警告が出ます。Dart は `unawaited_futures` の lint を入れたときだけ似た警告が出ます。

**出典:** [Attributes（discardableResult）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/attributes/)

### アクセス修飾子（private / package / public と final class）

**何の話か:** 宣言を「どこから使わせるか」で段階的に隠す仕組みです。

**意味:** Swift は `private`、`fileprivate`、`internal`、`package`、`public` の 5 段階です。このアプリでは、App から呼ぶ入口だけを `public`、パッケージ内のモジュール間は `package` にしています。使い分けは [architecture.md](../architecture.md#アクセス修飾子) を見てください。

```swift
// PokedexFeature: App が使うのは PokemonListView と init() だけ
public struct PokemonListView: View {
    public init() { self.init(store: PokemonListStore()) }
    init(store: PokemonListStore) { ... } // internal。Preview とテスト用
}

// SharedUI: 兄弟モジュール（PokedexFeature）には見せ、App には見せない
package struct PokemonRow: View { ... }
```

```dart
// Dart の隠し方は「_ を付ける（ライブラリ = ファイル単位で private）」しかない
class _Helper {}

// 兄弟パッケージには見せたいがアプリには見せたくないものは、
// lib/src/ に置いて export しない、という約束事で守る
// melos のモノレポでは pkg_a の src/ を pkg_b が import すると
// lint（implementation_imports）に怒られるだけで、コンパイルは通る
import 'package:pkg_a/src/row.dart';
```

**違いと間違えやすいところ:** Dart の `_` はライブラリ単位の private だけで、「同じパッケージの中だけ」「同じモジュールの中だけ」は書けません。melos のモノレポで共通パッケージの部品を、兄弟パッケージには使わせてアプリには見せない、という場面では `src/` と `export` の約束事で工夫するしかありませんでした。`package` はこれを言語の機能で書けます。App から `PokemonRow` を使うとコンパイルエラーになります。`final class` は Dart 3 の `final class`（外から継承できない）と似ていますが、Swift の `class` は既定で継承できるので、`final` を付けて閉じる点が逆です。

**出典:** [Access Control](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/)、[SE-0386](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0386-package-access-modifier.md)、[Dart の class modifiers](https://dart.dev/language/class-modifiers)

### #Preview と withDependencies

**何の話か:** 画面を実機なしで確かめる仕組みと、そのときだけ通信を偽物に差し替える方法です。

**意味:** `#Preview` は View のソースファイルの中に書き、Xcode の Canvas にその場で描画されます。「読み込み済み」「読み込み中」「オフラインのエラー」のように、状態ごとに 1 つずつ置きます。swift-dependencies の `withDependencies` で `fetchPokemonPage` だけを差し替えた Store を Preview ごとに作り、View に渡すので、本物の通信は走りません。`prepareDependencies` は「A dependency key can be prepared at most a single time」とドキュメントコメントにあるとおり、アプリ全体で 1 回しか使えません。同じファイルの Preview は 1 つのプロセスで動くため、2 つ目以降の差し替えが効かず、全部同じ画面になります。

```swift
#Preview("初回のエラー（オフライン）") {
    let store = withDependencies {
        $0.fetchPokemonPage.execute = { _ in throw LoadError.offline }
    } operation: {
        PokemonListStore()
    }
    NavigationStack { PokemonListView(store: store) }
}
```

```dart
// Widgetbook: 別のアプリ（catalog）に use case を登録する
@UseCase(name: 'offline', type: PokemonListScreen)
Widget offline(BuildContext context) => ProviderScope(
  overrides: [
    fetchPokemonPageProvider.overrideWith((ref) => throw const OfflineError()),
  ],
  child: const PokemonListScreen(),
);
```

**違いと間違えやすいところ:** `prepareDependencies` は、アプリの一番外側に `ProviderScope(overrides:)` を 1 つ置くようなものです。`withDependencies` は、Widgetbook の use case ごとに `ProviderScope` で包むのに当たります。Preview を状態ごとに分けたいときは後者を使います。Widgetbook は別のカタログアプリを作って起動しますが、Swift の Preview は View と同じファイルにあり、Xcode の Canvas に描画されます。「読み込み中」を確かめるために 3600 秒待つ関数を渡す、といった作りは、ボタンを押して試す手間なく、その状態を固定して見るための工夫です。

**出典:** [Previews in Xcode](https://developer.apple.com/documentation/swiftui/previews-in-xcode)、[prepareDependencies](https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/preparedependencies(isolation:_:))、[withDependencies](https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/withdependencies(_:operation:))、[Widgetbook](https://docs.widgetbook.io/)

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
