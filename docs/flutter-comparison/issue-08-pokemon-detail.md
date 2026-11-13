# #8 詳細画面を作る

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/8

詳細画面で初めて出てきたもの（`enum` の `rawValue`、`switch` の網羅チェック、`async let`、`NavigationStack(path:)`、`navigationDestination`、`NavigationLink(value:)`）を、Dart / Flutter の同じ層のものと比べる学習ノートです。前の Issue で説明した言葉は、[issue-07-pokemon-list.md](issue-07-pokemon-list.md) と [issue-44-list-localized-names.md](issue-44-list-localized-names.md) を見てください。

## Swift の言語機能

### enum の rawValue と init?(rawValue:) と Dart の values.byName

**何の話か:** API が返す文字列（`"grass"`）を、アプリの型（`PokemonType.grass`）に変える書き方です。知らない文字列が来たときの扱いが、Swift と Dart で違います。

**意味:** `enum PokemonType: String` と書くと、各 case に文字列の `rawValue` を付けられ、`init?(rawValue:)` が自動で付きます。この init は、知らない文字列なら `nil` を返します。このアプリは `compactMap` で、知らない識別子をその 1 つだけ落とします（取得の失敗にはしません。[ADR-0019](../adr/0019-type-and-stat-names-and-colors-in-app.md)）。

Dart の `values.byName("grass")` は、知らない名前なら `ArgumentError` を投げます。`nil` を返したいなら、`values` から自分で探します。

```swift
// core/Model の PokemonType（抜粋）
public enum PokemonType: String, Sendable {
    case grass, poison, fire  // 省略。実際は 18 種類
}

// core/Repository: 知らない識別子は nil になり、compactMap が落とす
let types = pokemon.types.compactMap { PokemonType(rawValue: $0) }
```

```dart
enum PokemonType { grass, poison, fire } // 省略

// byName は知らない名前で ArgumentError を投げる
final one = PokemonType.values.byName('grass');

// nil 相当を返したいなら自分で探す。
// firstWhereOrNull は package:collection の拡張
final types = names
    .map((n) => PokemonType.values.firstWhereOrNull((t) => t.name == n))
    .nonNulls
    .toList();
```

**違いと間違えやすいところ:** Swift の `rawValue` は、case の名前とは別に決められます（`specialAttack = "special-attack"`）。Dart の `name` は case の名前そのもので、`special-attack` のようなハイフン入りの文字列は case の名前にできません。別の文字列と対応させるには、フィールドを持つ enhanced enum を自分で書きます。

**出典:** [Enumerations の Raw Values（Swift）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations/#Raw-Values)、[EnumByName.byName（Dart）](https://api.dart.dev/dart-core/EnumByName/byName.html)

### switch の網羅チェックと Dart 3

**何の話か:** enum のすべての case を `switch` で扱わないと、コンパイルが通らない仕組みです。タイプの色や名前の書き忘れが、コンパイルエラーで分かります。

**意味:** Swift の `switch` は、すべての case を書くか `default` を付けないとコンパイルエラーです。`default` を付けると、あとで case を足してもエラーにならないので、`PokemonType+Appearance.swift` では `default` を使っていません。Dart 3 の `switch`（式も文も）も、enum や sealed class で同じ網羅チェックをします。

```swift
// feature/PokedexFeature の PokemonType+Appearance.swift の形（抜粋）
var badgeColorHex: UInt32 {
    switch self {
    case .grass: 0x2E7D32
    case .poison: 0x7B3FA0
    case .fire: 0xC2410C
    // 省略。case を 1 つ足すと、ここがコンパイルエラーになる
    }
}
```

```dart
int badgeColorHex(PokemonType t) => switch (t) {
      PokemonType.grass => 0x2E7D32,
      PokemonType.poison => 0x7B3FA0,
      PokemonType.fire => 0xC2410C,
      // 省略。case を 1 つ足すと、ここがコンパイルエラーになる
    };
```

**違いと間違えやすいところ:** Dart 3 より前の `switch` 文には網羅チェックが無く、`default` で逃げる書き方が普通でした。Dart 3 でも、`default` や `_` を書くと網羅チェックは効かなくなります。この点は Swift と同じです。

**出典:** [Control Flow の Switch（Swift）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/controlflow/#Switch)、[Branches の Exhaustiveness checking（Dart）](https://dart.dev/language/branches#exhaustiveness-checking)

### async let と Dart の Future.wait

**何の話か:** 互いに待たなくてよい 2 つの通信を、同時に始める書き方です。

**意味:** `async let` は、右辺の処理を子の Task としてすぐ始め、結果は `await` で受け取る時に待ちます。一覧は、一覧の API と名前の表を `async let` で同時に取ります（`PokemonRepository.fetchList`）。片方が失敗すると、`try await` した時点で投げられ、もう片方の子 Task はキャンセルされます。

詳細は、同時に取りません。species の ID は pokemon の返事の `species.url` に入っているので、pokemon を取ってから species を取る直列です。

```swift
// core/Repository の fetchList（抜粋）
async let list = fetchPokemonList(limit, offset)
async let namesByID = fetchSpeciesNames()
let (dto, names) = try await (list, namesByID)
```

```dart
// 同じことを Dart で書くと
final (dto, names) = await (fetchPokemonList(limit, offset), fetchSpeciesNames()).wait;
// 型の違う 2 つなら、Record の wait が Future.wait の型付き版
```

**違いと間違えやすいところ:** Dart の `Future` は作った時点で動き始めます。Swift は `async let` と書いた行で動き始めますが、関数を呼んだだけでは動きません（`await` で呼ぶか、`async let` か `Task` に入れたとき）。また、Dart の `Future.wait` は、`eagerError: true` でなければ、1 つが失敗しても残りの完了を待ちます。Swift の `async let` は、失敗を `await` したときに、まだ終わっていない子 Task をキャンセルして抜けます。キャンセルは協調的で、Dart の `Future` にはキャンセルの仕組みがありません。

**出典:** [Concurrency の Calling Asynchronous Functions in Parallel（Swift）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/#Calling-Asynchronous-Functions-in-Parallel)、[Future.wait（Dart）](https://api.dart.dev/dart-async/Future/wait.html)、[Record の wait（Dart）](https://api.dart.dev/dart-async/FutureRecord2/wait.html)

## Apple 標準

### NavigationStack(path:) と Navigator の pages

**何の話か:** 「今どの画面まで進んでいるか」を、値の並びとして持つ仕組みです。

**意味:** `NavigationStack(path:)` は、`path`（このアプリでは `[PokedexRoute]`）に値を足すと画面が進み、末尾を消すと戻ります。画面を作るのはスタックで、`path` が持つのは Route の値だけです。

```swift
// app/Pokedex/PokedexApp.swift
@Observable final class Router { var path: [PokedexRoute] = [] }

NavigationStack(path: $router.path) {
    PokemonListView().pokedexDestinations()
}
```

Flutter の近いものは、`Navigator` の `pages`（Navigator 2.0）です。`pages` に `Page` の並びを渡すと、その並びのとおりに画面が積まれます。

```dart
Navigator(
  pages: [
    const MaterialPage(child: PokemonListPage()),
    for (final id in detailIds) MaterialPage(child: PokemonDetailPage(id: id)),
  ],
  onDidRemovePage: (page) => /* path から消す */ null,
)
```

**違いと間違えやすいところ:** Swift の `path` は値型の並びで、Widget も画面も持ちません。Flutter の `pages` は、1 つ 1 つが `Page`（画面の作り方を持つオブジェクト）です。Swift では、値から画面への対応は、次の `navigationDestination` が別に持ちます。

**出典:** [NavigationStack（Apple）](https://developer.apple.com/documentation/swiftui/navigationstack)、[Navigator.pages（Flutter）](https://api.flutter.dev/flutter/widgets/Navigator/pages.html)

### navigationDestination と onGenerateRoute

**何の話か:** Route の値から、画面を作る対応表です。

**意味:** `navigationDestination(for:)` は、`PokedexRoute` 型の値が `path` に入ったときに作る画面を `switch` で返します。PokedexFeature がこの対応表（`pokedexDestinations()`）を持ち、Router を知りません。Router は `path` を持つだけです。Flutter の `onGenerateRoute` は、名前（と引数）から `Route` を作る関数で、役割は近いです。

```swift
// feature/PokedexFeature の PokedexRoute.swift
navigationDestination(for: PokedexRoute.self) { route in
    switch route {
    case .detail(let id): PokemonDetailView(id: id)
    }
}
```

```dart
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  if (settings.name == '/detail') {
    final id = settings.arguments as int;
    return MaterialPageRoute(builder: (_) => PokemonDetailPage(id: id));
  }
  return null;
}
```

**違いと間違えやすいところ:** `onGenerateRoute` は名前が文字列で、引数は `Object?` なので、キャストが要ります（上の `as int`）。Swift は Route が enum で、引数（`id`）に型が付いており、`switch` の網羅チェックが効きます。知らない Route は、そもそも作れません。

**出典:** [navigationDestination(for:destination:)（Apple）](https://developer.apple.com/documentation/swiftui/view/navigationdestination(for:destination:))、[Navigator.onGenerateRoute（Flutter）](https://api.flutter.dev/flutter/widgets/Navigator/onGenerateRoute.html)

### NavigationLink(value:)

**何の話か:** タップしたら、`path` に値を足すだけのリンクです。

**意味:** `NavigationLink(value:)` は、タップで `path` に値を足します。画面そのものは渡しません。一覧の行（`PokemonListView`）がこれです。行タップは Store の Action にしません。Flutter では、行の `onTap` で `Navigator.pushNamed(context, '/detail', arguments: id)` を呼ぶ形が近いです。

```swift
NavigationLink(value: PokedexRoute.detail(id: pokemon.id)) {
    PokemonRow(pokemon: pokemon)
}
```

```dart
ListTile(
  onTap: () => Navigator.pushNamed(context, '/detail', arguments: pokemon.id),
  title: PokemonRow(pokemon: pokemon),
)
```

**違いと間違えやすいところ:** Swift のリンクは、タップで何かを実行するのではなく、「この値に進む」という宣言です。対応する `navigationDestination` が上の階層に無いと、タップしても何も起きません（実行時に警告が出るだけで、コンパイルでは分かりません）。

**出典:** [NavigationLink（Apple）](https://developer.apple.com/documentation/swiftui/navigationlink)、[Navigator.pushNamed（Flutter）](https://api.flutter.dev/flutter/widgets/Navigator/pushNamed.html)
