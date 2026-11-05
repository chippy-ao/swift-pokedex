# #6 NetworkClient と API の共通部分

- Issue: https://github.com/chippy-ao/swift-pokedex/issues/6
- PR: https://github.com/chippy-ao/swift-pokedex/pull/30

PokeAPI の一覧を取る共通部分（NetworkClient、デコード、エラー、HTTP キャッシュ、Repository）で初めて出てきた Swift の言語機能と Apple 標準の部品を、Dart / Flutter の同じ層のものと比べる学習ノートです。言語は言語どうし、標準は標準どうし、外部ライブラリは外部ライブラリどうしで比べます。Dart 側は普段のアプリ開発で使うものに合わせます。

モジュール構成、Package.swift、Lint、CI など、この Issue より前から出ていた話は [issue-02-package-structure.md](issue-02-package-structure.md)、[issue-03-lint.md](issue-03-lint.md)、[issue-04-ci.md](issue-04-ci.md) に書いてあります。ここでは繰り返さずリンクします。

## 項目

言語

1. [struct と入れ子の型](#struct-と入れ子の型)
2. [enum（エラーの種類を並べる）](#enumエラーの種類を並べる)
3. [extension](#extension)
4. [static let](#static-let)
5. [ジェネリクスと型を値で渡す（`Response.self`）](#ジェネリクスと型を値で渡すresponseself)
6. [Equatable / Hashable / Identifiable / Codable の自動準拠](#equatable--hashable--identifiable--codable-の自動準拠)
7. [Sendable と @Sendable](#sendable-と-sendable)
8. [public / internal / private と @testable import](#public--internal--private-と-testable-import)
9. [throws / try / any Error / do-catch とキャンセル](#throws--try--any-error--do-catch-とキャンセル)
10. [マクロ（@DependencyClient）と -skipMacroValidation](#マクロdependencyclientと--skipmacrovalidation)

Apple 標準

11. [JSONDecoder と convertFromSnakeCase](#jsondecoder-と-convertfromsnakecase)
12. [URLSession（2xx 以外でも投げない）](#urlsession2xx-以外でも投げない)
13. [URLCache](#urlcache)
14. [URLProtocol のスタブ](#urlprotocol-のスタブ)
15. [Mutex](#mutex)
16. [Swift Testing（#expect(throws:)、arguments、@Suite(.serialized)）](#swift-testingexpectthrowsargumentssuiteserialized)

Swift の外部ライブラリとツールチェーン

17. [swift-dependencies と swift-http-types](#swift-dependencies-と-swift-http-types)
18. [テスト target の依存](#テスト-target-の依存)

早見表は[末尾](#早見表)にあります。

---

## 言語

### struct と入れ子の型

**何の話か:** データをひとまとめにする入れ物の作り方と、その入れ物の中に別の入れ物を書く書き方です。

**意味:** `struct` は値型です。変数に入れたり関数に渡したりするたびに中身がコピーされるので、別の場所から勝手に書き換えられません。複数の場所で同じデータを触っても食い違わないので、通信で受け取ったデータの入れ物に向いています。入れ子の型は、その型の中でしか意味を持たない型（一覧の 1 行ぶんなど）を外に出さずに置く書き方です。例えるなら、書類を渡すときに必ずコピーを渡すイメージです。

**Swift のコード:** [PokemonListDTO.swift](../../core/NetworkClient/Sources/PokemonListDTO.swift)

```swift
public struct PokemonListDTO: Codable, Equatable, Sendable {
    public struct Entry: Codable, Equatable, Sendable {
        public var name: String
        public var url: String
    }

    public var count: Int
    public var next: String?
    public var results: [Entry]

    // previous と、public init（Entry にも）は省略
}
```

**Dart のコード:**

```dart
class PokemonListDto {
  const PokemonListDto({required this.count, this.next, required this.results});

  final int count;
  final String? next;
  final List<PokemonListEntry> results;
}

// Dart はクラスの中にクラスを書けないので、同じファイルの外に並べる
class PokemonListEntry {
  const PokemonListEntry({required this.name, required this.url});

  final String name;
  final String url;
}
```

**違いと間違えやすいところ:**

- Dart の `class` は参照型です。2 つの変数が同じ実体を指すので、片方で変えるともう片方にも見えます。Swift の `struct` は代入のたびにコピーされるので、この心配がありません。Swift にも参照型の `class` があり、そちらは Dart の `class` に近い動きです。
- Dart は `final` を付けないと変更できてしまいます。Swift は `let` で作った `struct` の `var` プロパティも書き換えられません（値全体が不変になります）。
- Dart にはクラスの入れ子がありません。Swift の入れ子は、外から `PokemonListDTO.Entry` のように参照します（`.init(name:url:)` と型名を省く書き方もできます）。
- `public struct` のメンバーワイズ初期化子は `internal` になります。モジュールの外から作れるようにするには、`public init` を自分で書く必要があります（このリポジトリの各 struct に `init` があるのはそのためです）。

**出典:**

- [Structures and Classes（The Swift Programming Language）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/classesandstructures/)
- [Nested Types](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/nestedtypes/)
- [Access Control（Default Memberwise Initializers for Structure Types）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/)
- [Dart の classes](https://dart.dev/language/classes)

### enum（エラーの種類を並べる）

**何の話か:** 「これらのどれか 1 つ」という選択肢を型として書く方法です。

**意味:** Swift の `enum` は case ごとに値を持てます（関連値）。エラーの種類を並べておくと、`switch` で書き漏らした case をコンパイラが教えてくれます。ここでは「ステータスが 2xx 以外だった」を `httpStatus(Int)` で表しています。例えるなら、窓口の「用件ごとの受付票」です。用件の種類は決まっていて、票ごとに必要な情報が付きます。

**Swift のコード:** [PokeAPIError.swift](../../core/NetworkClient/Sources/PokeAPIError.swift)、[LoadError.swift](../../core/Model/Sources/LoadError.swift)

```swift
public enum PokeAPIError: Error, Equatable {
    case httpStatus(Int)
}

public enum LoadError: Error, Equatable {
    case offline
    case unavailable
}
```

**Dart のコード:** Dart 3 の `sealed class` が一番近いです。

```dart
sealed class LoadError implements Exception {
  const LoadError();
}

final class Offline extends LoadError {
  const Offline();
}

final class Unavailable extends LoadError {
  const Unavailable();
}

String message(LoadError e) => switch (e) {
      Offline() => 'オフラインです',
      Unavailable() => '読み込めませんでした',
    };
```

**違いと間違えやすいところ:**

- Dart の `enum`（拡張 enum を含む）は、全 case が同じ形のフィールドを持つ定数で、case ごとに形の違うデータを、実行時に作って持たせることはできません。case ごとに持つデータが違うなら `sealed class` を使います。Swift の `enum` は関連値（`httpStatus(404)` のように実行時に値を入れる）を持てるので 1 つで済みます。
- Swift の `enum` を `Error` に準拠させると、そのまま `throw` できます。Dart は `Exception` を実装した class を投げるのが慣習です。
- `Equatable` を付けると `==` で比べられます（テストで `#expect(throws: PokeAPIError.httpStatus(404))` と書けるのはこのためです）。Dart の `sealed class` は `==` を自分で書くか、freezed などの外部ライブラリに任せる必要があります。

**出典:**

- [Enumerations（The Swift Programming Language）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations/)
- [Dart の enums](https://dart.dev/language/enums)
- [Dart の class modifiers（sealed）](https://dart.dev/language/class-modifiers#sealed)
- [Dart の patterns（switch 式）](https://dart.dev/language/patterns)

### extension

**何の話か:** すでにある型に、あとから機能を足す書き方です。

**意味:** `extension` は、型の定義を書き換えずに、メソッド、計算プロパティ、static な値、プロトコル準拠を足せます。定義と「DI に載せる」「ライブ実装を持つ」といった付け足しを、ファイルとモジュールで分けられます。このリポジトリでは `PokeAPIClient` の定義は NetworkClient、ライブ実装は NetworkClientURLSession に置き、後者が `extension PokeAPIClient: DependencyKey` で足しています。例えるなら、本体は同じまま、別売りのアタッチメントを付けるイメージです。

**Swift のコード:** [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift)

```swift
extension PokeAPIClient: DependencyKey {
    public static let liveValue = PokeAPIClient.live(session: .pokeAPI)
}
```

**Dart のコード:**

```dart
// あとから足せるのはメソッドなど。インターフェースの実装は足せない
extension PokeApiClientX on PokeApiClient {
  Future<PokemonListDto> fetchFirstPage() => fetchPokemonList(20, 0);
}

// 「ライブ実装を作る」ような足し方は、普通はトップレベル関数かコンストラクタで書く
PokeApiClient createLivePokeApiClient(http.Client client) => PokeApiClient(
      fetchPokemonList: (limit, offset) async { /* ... */ },
    );
```

**違いと間違えやすいところ:**

- Dart の extension methods は、メソッド、getter、setter、operator を足せますが、新しいインターフェースの実装を足すことはできません（`implements` は書けない）。Swift の `extension` は `: DependencyKey` のようにプロトコル準拠を足せます。ここが一番大きな違いです。
- どちらも、インスタンスごとの保存プロパティは足せません。
- Dart の extension に `static` を書いても、呼ぶときは拡張の名前から呼びます（元の型の名前では呼べません）。Swift の `static` は `PokeAPIClient.live(...)` のように型の名前で呼べます。そのため、このリポジトリの書き方は Dart では直訳できず、上のように別の形になります。
- Dart の extension は静的に解決されるので、型が `dynamic` のときは呼べません。

**出典:**

- [Extensions（The Swift Programming Language）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/extensions/)
- [Dart の extension methods](https://dart.dev/language/extension-methods)

### static let

**何の話か:** インスタンスではなく型そのものに 1 つだけ持たせる値の書き方です。

**意味:** `static let` は型に属する定数です。最初に使われるまで初期化されず、初期化は 1 回だけ行われます。DI のキーの値（`liveValue`）や、設定値のまとめ（`PokeAPICacheConfiguration.diskCapacity`）の置き場所になります。例えるなら、クラス全体で共有する掲示板です。

**Swift のコード:** [PokeAPISession.swift](../../core/NetworkClientURLSession/Sources/PokeAPISession.swift)

```swift
enum PokeAPICacheConfiguration {
    static let memoryCapacity = 20 * 1024 * 1024
    static let diskCapacity = 200 * 1024 * 1024
}

extension URLSession {
    static let pokeAPI: URLSession = {
        let configuration = URLSessionConfiguration.default
        // ...
        return URLSession(configuration: configuration)
    }()
}
```

**Dart のコード:**

```dart
abstract final class PokeApiCacheConfiguration {
  static const memoryCapacity = 20 * 1024 * 1024;
  static const diskCapacity = 200 * 1024 * 1024;
}

final pokeApiClient = http.Client(); // トップレベルの final は最初の参照時に初期化される
```

**違いと間違えやすいところ:**

- Dart の `static const` はコンパイル時定数ですが、Swift の `static let` は実行時に初期化されます。そのため `URLSession(...)` のように実行時にしか作れないものも入れられます（`= { ... }()` は、その場でクロージャを実行して値を作る書き方です）。Dart でこれに近いのは `static final` です。
- `static let` の初期化は遅延かつ 1 回だけで、複数スレッドから同時に初めて触られても 1 回しか実行されません（Swift の仕様）。Dart は isolate ごとに 1 本のスレッドで動くので、この心配が元から要りません。
- ケースを持たない `enum` を名前空間として使うのは Swift の定番です。インスタンスを作れないので、定数置き場に向いています。Dart の `abstract final class` が近い使い方です。

**出典:**

- [Properties（Type Properties）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/properties/#Type-Properties)
- [Dart の static variables and methods](https://dart.dev/language/classes#static-variables-and-methods)
- [Dart の final と const](https://dart.dev/language/variables#final-and-const)

### ジェネリクスと型を値で渡す（`Response.self`）

**何の話か:** 「どんな型でもデコードできる関数」を 1 つ書き、どの型かを引数で渡す方法です。

**意味:** `get<Response: Decodable>(_ type: Response.Type, ...)` は、`Decodable` に準拠した任意の型を返せる共通の GET です。型は `PokemonListDTO.self` のように「型そのもの」を値として渡します。`JSONDecoder.decode(_:from:)` も同じ形（型を値で受け取る）なので、それに合わせています。

**Swift のコード:** [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift)

```swift
private func get<Response: Decodable>(
    _ type: Response.Type, path: String, session: URLSession
) async throws -> Response {
    // ...
    return try pokeAPIDecoder.decode(Response.self, from: data)
}

try await get(PokemonListDTO.self, path: "...", session: session)
```

**Dart のコード:** JSON から作る処理は、関数として渡すのが普通です。

```dart
Future<T> get<T>(Uri uri, T Function(Map<String, Object?>) fromJson) async {
  final res = await client.get(uri);
  return fromJson(jsonDecode(res.body) as Map<String, Object?>);
}

await get(uri, PokemonListDto.fromJson);
```

**違いと間違えやすいところ:**

- Dart では `T.fromJson` のように、型引数から名前付きコンストラクタを呼べません。そのためコールバックを渡します。Swift は `Decodable` というプロトコルの要求（`init(from:)`）を型から呼べるので、型を渡すだけで済みます。
- Swift の `Response.self` は型を値として扱う書き方で、`Response.Type` がその型です。Dart の `Type` は実行時の型情報で、これを使って新しい値を作ることはできません。
- Swift のジェネリクスにも制約（`: Decodable`）を書けます。Dart の `T extends Object` に当たります。

**出典:**

- [Generics（The Swift Programming Language）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/generics/)
- [Metatype Type（Types）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/types/#Metatype-Type)
- [Dart の generics](https://dart.dev/language/generics)

### Equatable / Hashable / Identifiable / Codable の自動準拠

**何の話か:** 「同じかどうか比べる」「辞書のキーにする」「JSON と相互に変換する」といった機能を、ほとんど書かずに型に付ける仕組みです。

**意味:** プロトコルに準拠すると、その型でその機能が使えます。保存プロパティがすべて準拠済みの型なら、コンパイラが `==`、`hash(into:)`、JSON の変換コードを自動で書きます（合成された実装）。`Identifiable` は「`id` を持つ」という約束で、SwiftUI の `List` などが一意性の判定に使います。例えるなら、設計図に「この機能付き」と一行書くと、部品をコンパイラが組むイメージです。

**Swift のコード:** [PokemonSummary.swift](../../core/Model/Sources/PokemonSummary.swift)

```swift
public struct PokemonSummary: Equatable, Hashable, Sendable, Identifiable {
    public var id: Int
    public var name: String
    // == と hash は、上の宣言だけで揃う。Identifiable は id を持つだけで満たす
}
```

**Dart のコード:** 言語だけなら `==` と `hashCode` を手書きします。普段は外部ライブラリの freezed で生成します。

```dart
@freezed
abstract class PokemonSummary with _$PokemonSummary {
  const factory PokemonSummary({required int id, required String name}) = _PokemonSummary;
  // ==、hashCode、copyWith が build_runner で生成される
}
```

**違いと間違えやすいところ:**

- 層が違います。Swift は言語（コンパイラ）が合成し、Dart の freezed は外部ライブラリの生成です。Dart 3 の record（`(int, String)`）は言語機能として値の比較ができますが、名前付きの型にはなりません。
- Dart の `class` は既定で `==` が参照の比較です。値の比較にするには freezed などの生成か、手書きが要ります。Swift の `struct` は、準拠を宣言するだけで値の比較になります。生成ファイルも `build_runner` も要りません。
- 自動で合成されるのは、すべてのプロパティが同じプロトコルに準拠しているときだけです。準拠していない型のプロパティが 1 つでもあると、自分で実装を書かない限りコンパイルエラーになります。
- `Identifiable` は `id` プロパティが要るだけの約束で、合成されるものはありません（`id` は自分で宣言しています）。
- `Codable` は `Decodable & Encodable` の別名です。キーはプロパティ名から決まります（合成された `CodingKeys`）。キー名を変えたいときだけ `CodingKeys` を自分で書きます。詳しくは [JSONDecoder と convertFromSnakeCase](#jsondecoder-と-convertfromsnakecase) を参照してください。
- Swift の `struct` に `copyWith` に当たるものはありません。`var` なので、コピーを作って直接書き換えます（`var copy = value; copy.name = "x"`）。

**出典:**

- [Protocols（Adopting a Protocol Using a Synthesized Implementation）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/protocols/#Adopting-a-Protocol-Using-a-Synthesized-Implementation)
- [Encoding and Decoding Custom Types（Apple）](https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types)
- [Identifiable（Apple）](https://developer.apple.com/documentation/swift/identifiable)
- [freezed](https://pub.dev/packages/freezed)

### Sendable と @Sendable

**何の話か:** 「この値は、複数の処理が同時に触っても壊れない」という印です。

**意味:** Swift の `async` は、`await` のあとに別のスレッドで再開されることがあります。そのため、スレッドをまたいで渡す値やクロージャには `Sendable` の印が要り、満たさないものをまたがせるとコンパイルエラーになります（Swift 6 の言語モードで検査されます）。このリポジトリは `.v6` なので、`PokeAPIClient` の中のクロージャにも `@Sendable` が付いています。例えるなら、窓口をまたいで渡す書類に「同時に見ても安全」の判子を押すイメージです。

**Swift のコード:** [PokeAPIClient.swift](../../core/NetworkClient/Sources/PokeAPIClient.swift)

```swift
@DependencyClient
public struct PokeAPIClient: Sendable {
    public var fetchPokemonList:
        @Sendable (_ limit: Int, _ offset: Int) async throws -> PokemonListDTO
}
```

**Dart のコード:** 印はありません。

```dart
class PokeApiClient {
  PokeApiClient({required this.fetchPokemonList});

  final Future<PokemonListDto> Function(int limit, int offset) fetchPokemonList;
}
```

**違いと間違えやすいところ:**

- Dart のコードは、1 つの isolate の中では 1 本のスレッドで動き、他のコードが割り込めるのは `await` の地点だけです。そのため、普段の `async` / `await` では「同時に触って壊れる」ことが起きず、印が要りません。
- Swift は複数のスレッドで同時に動けるので、安全であることを型システムで示す必要があります。`struct` の中身がすべて `Sendable` なら、`struct` も `Sendable` になれます。`@Sendable` のクロージャがキャプチャする値も `Sendable` である必要があります。
- `@Sendable` は**クロージャ**に付ける属性で、`Sendable` は**型**に準拠させるプロトコルです。別物ですが、同じ「同時に使っても安全」を表します。
- 補足: Dart にも Isolate があり、Isolate 間はメモリを共有せず、メッセージを渡します。Swift の `Sendable` が守る問題は、Dart では「共有しない」ことで避けています。Isolate は普段のアプリ開発ではあまり使いません。

**出典:**

- [Concurrency（Sendable Types）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/#Sendable-Types)
- [SE-0302: Sendable and @Sendable closures](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)
- [Dart の concurrency（isolates）](https://dart.dev/language/concurrency)
- [Dart の asynchronous programming](https://dart.dev/libraries/async/async-await)

### public / internal / private と @testable import

**何の話か:** どのコードを外のモジュールに見せ、どのコードを隠すかの決め方です。

**意味:** Swift の既定は `internal` で、同じモジュール（target）の中だけで見えます。他のモジュールに見せるものにだけ `public` を付けます。`private` はさらに狭く、宣言を含むスコープ（ファイルのトップレベルならそのファイル）だけです。テストでは `@testable import` を使うと、`internal` なものにもテストから触れます。このリポジトリでは、`PokeAPIClient.live(session:)` や `PokeAPICacheConfiguration` を `internal` にして、テストだけが使えるようにしています。

**Swift のコード:** [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift)、[NetworkClientURLSessionTests.swift](../../core/NetworkClientURLSession/Tests/NetworkClientURLSessionTests.swift)

```swift
// Sources: 既定の internal。同じモジュールとテストだけが見える
static func live(session: URLSession) -> PokeAPIClient { /* ... */ }

// Tests
@testable import NetworkClientURLSession
```

**Dart のコード:**

```dart
// lib/src/ に実装を置き、lib/ のファイルから必要なものだけ export する
// lib/poke_api_client.dart
export 'src/poke_api_client.dart' show PokeApiClient;

// 同じファイル（ライブラリ）の中だけで使うものは _ を付ける
Future<T> _get<T>(/* ... */) async { /* ... */ }

// 公開はするが、テスト以外から使わせたくないもの
@visibleForTesting
PokeApiClient createClientForTest(http.Client client) => /* ... */;
```

**違いと間違えやすいところ:**

- 隠す単位が違います。Dart は**ファイル（ライブラリ）**単位で、`_` を付けたものがそのファイルの外から見えなくなります。Swift の既定の `internal` は**モジュール（target）**単位で、同じ target のほかのファイルからは見えます。
- Swift に `@visibleForTesting` に当たる属性はありません。`internal` にして `@testable import` で触るのが標準の形です。Dart の `@visibleForTesting` は analyzer の警告を出すだけで、使うこと自体は止めません。
- `@testable import` は、テスト用にビルドしたとき（testability が有効なとき）だけ使えます。Apple のドキュメントでは Debug 構成が前提です。
- `public struct` に `public init` を書かないと外から作れない点は、Swift 固有です。
- モジュールを分ける理由と、依存の向きの決まりは [issue-02-package-structure.md](issue-02-package-structure.md) を参照してください。

**出典:**

- [Access Control（Access Levels for Unit Test Targets）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/)
- [Dart のライブラリとプライバシー](https://dart.dev/language/libraries)
- [Dart の package layout（lib/src）](https://dart.dev/tools/pub/package-layout#implementation-files)
- [visibleForTesting（package:meta）](https://pub.dev/documentation/meta/latest/meta/visibleForTesting-constant.html)

### throws / try / any Error / do-catch とキャンセル

**何の話か:** 失敗を表す方法と、途中でやめる（キャンセルする）ときの扱いです。

**意味:** Swift は、失敗しうる関数に `throws` の印を付け、呼ぶ側に `try` を書かせます。どの呼び出しが失敗しうるかが目で見て分かります。エラーの型は `any Error`（`Error` に準拠した何か）で受け、`do-catch` で `as?` や `is` を使って種類を見分けます。キャンセルは失敗とは違うので、Repository は `CancellationError` と `URLError(.cancelled)` を変換せずに投げ直します。例えるなら、荷物に「割れ物注意」の札が付いていて、受け取る人が必ず気づくイメージです。

**Swift のコード:** [PokemonRepository.swift](../../core/Repository/Sources/PokemonRepository.swift)

```swift
do {
    let dto = try await client.fetchPokemonList(limit, offset)
    // ...
} catch {
    throw loadError(from: error)
}

private func loadError(from error: any Error) -> any Error {
    if error is CancellationError || error is LoadError {
        return error
    }
    if let urlError = error as? URLError {
        switch urlError.code {
        case .cancelled:
            return error
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return LoadError.offline
        default:
            return LoadError.unavailable
        }
    }
    return LoadError.unavailable
}
```

**Dart のコード:**

```dart
try {
  final dto = await client.fetchPokemonList(limit, offset);
  // ...
} on SocketException {
  // dart:io の例外。package:http が何に包んで投げるかは版で変わるので、実際は確かめて書く
  throw const Offline();
} on LoadError {
  rethrow;
} catch (_) {
  throw const Unavailable();
}
```

**違いと間違えやすいところ:**

- Dart の関数は、投げるかどうかを型に表しません。ドキュメントを読むか、実行して初めて分かります。Swift は `throws` が型に入っているので、`try` を書き忘れるとコンパイルエラーになります。
- Dart は何でも `throw` できますが、慣習では `Exception` か `Error` を投げます。Swift は `Error` に準拠した型だけを投げられます。
- Swift の `catch` は、パターンを書かないと `error` という名前で全部を受けます。`any Error` は「`Error` に準拠した何か」という型で、`as?` で具体的な型に戻して使います（Dart の `is` / `as` に近い）。
- キャンセルの仕組みが違います。Swift の `Task` は協調的キャンセルで、キャンセルされた `Task` の中で `CancellationError` が投げられたり、`URLSession` が `URLError(.cancelled)` を投げたりします。**投げ直さないと、キャンセルが「失敗」として画面に出てしまいます。** Dart の `Future` には標準のキャンセルがなく、止めたいときは `package:async` の `CancelableOperation` を使うか、結果を無視します。
- 補足: Swift の `Result` は、値か失敗かを持つ型で、`throws` と相互に変換できます。Dart の標準にはなく、近いのは `package:async` の `Result` か自前の sealed class です。

**出典:**

- [Error Handling（The Swift Programming Language）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/errorhandling/)
- [Concurrency（The Swift Programming Language）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [CancellationError（Apple）](https://developer.apple.com/documentation/swift/cancellationerror)
- [Dart の error handling](https://dart.dev/language/error-handling)
- [CancelableOperation（package:async）](https://pub.dev/documentation/async/latest/async/CancelableOperation-class.html)

### マクロ（@DependencyClient）と -skipMacroValidation

**何の話か:** コードを書く前に、コンパイラが別のコードを生成してくれる仕組みです。

**意味:** `@DependencyClient` を付けた struct は、マクロがイニシャライザと、未実装のときに失敗するクロージャを生成します。`PokeAPIClient()` だけでテスト用の「呼ばれたら失敗する」実装になるのはこのためです。マクロはコンパイル時に展開され、生成ファイルは残りません。外部パッケージのマクロは、`xcodebuild` では承認が要ります。このリポジトリは `xcodebuild test` に `-skipMacroValidation` を付けて承認を省いています。

**Swift のコード:** [PokeAPIClient.swift](../../core/NetworkClient/Sources/PokeAPIClient.swift)

```swift
@DependencyClient
public struct PokeAPIClient: Sendable {
    public var fetchPokemonList:
        @Sendable (_ limit: Int, _ offset: Int) async throws -> PokemonListDTO
}

extension PokeAPIClient: TestDependencyKey {
    // 呼ばれたらテストが失敗する（@DependencyClient が未実装のクロージャを作る）
    public static let testValue = PokeAPIClient()
}
```

**Dart のコード:** 同じ「差し替えられる入れ物」を、抽象クラスと手書きの偽物で書くのが普通です。

```dart
abstract interface class PokeApiClient {
  Future<PokemonListDto> fetchPokemonList(int limit, int offset);
}

class UnimplementedPokeApiClient implements PokeApiClient {
  @override
  Future<PokemonListDto> fetchPokemonList(int limit, int offset) =>
      throw UnimplementedError();
}
```

**違いと間違えやすいところ:**

- Dart のコード生成は `build_runner` が**ファイルを書き出す**方式で、生成物（`*.g.dart` など）が見えます。Swift のマクロは**コンパイル中に展開**され、ファイルは残りません（Xcode の「Expand Macro」で中身を見られます）。
- このリポジトリは interface を「抽象クラス」ではなく「クロージャを持つ struct」で書いています。差し替えは `withDependencies { $0.pokeAPIClient.fetchPokemonList = ... }` のように、クロージャ 1 つ単位でできます。
- マクロは外部パッケージのコードをビルド時に実行するため、Xcode は初回に承認を求めます。`-skipMacroValidation` は `xcodebuild` でその承認を省くオプションです。理由は [mise.toml](../../mise.toml) のコメントにあります。
- 層が違います。Swift のマクロは言語の機能です。Dart の `build_runner` は言語ではなく外部のコード生成ツールで、Dart 言語にマクロはありません（実験されていましたが、2025 年 1 月に中止されました）。

**出典:**

- [Macros（The Swift Programming Language）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/)
- [swift-dependencies](https://github.com/pointfreeco/swift-dependencies)
- [WWDC23 Expand on Swift macros](https://developer.apple.com/videos/play/wwdc2023/10167/)
- [build_runner](https://pub.dev/packages/build_runner)
- [dart-lang/macros（README に中止の記載）](https://dart.googlesource.com/macros/+/refs/heads/main/README.md)

---

## Apple 標準

### JSONDecoder と convertFromSnakeCase

**何の話か:** JSON の文字列を Swift の値に変えるときに、キーの名前の付け方を合わせる方法です。

**意味:** PokeAPI のキーは `snake_case` ですが、Swift のプロパティは `camelCase` です。`JSONDecoder` の `keyDecodingStrategy = .convertFromSnakeCase` を指定すると、デコード時に `front_default` が `frontDefault` に対応づけられます。デコーダーは 1 か所で作って使い回します。ハイフン入りのキー（`official-artwork`）は変換の対象外なので、そのキーだけ `CodingKeys` で名前を書きます。

**Swift のコード:** [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift)

```swift
private let pokeAPIDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()

return try pokeAPIDecoder.decode(Response.self, from: data)
```

**Dart のコード:** 標準（`dart:convert`）にはキー名の変換機能がなく、`fromJson` を手書きします。

```dart
class Sprites {
  const Sprites({this.frontDefault});

  final String? frontDefault;

  factory Sprites.fromJson(Map<String, Object?> json) =>
      Sprites(frontDefault: json['front_default'] as String?);
}
```

普段は外部ライブラリの json_serializable で生成します。

```dart
part 'sprites.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Sprites {
  const Sprites({this.frontDefault});

  final String? frontDefault; // front_default

  factory Sprites.fromJson(Map<String, dynamic> json) => _$SpritesFromJson(json);
}

@JsonSerializable()
class Other {
  const Other({this.officialArtwork});

  // ハイフン入りのキーは個別に指定する
  @JsonKey(name: 'official-artwork')
  final String? officialArtwork;

  factory Other.fromJson(Map<String, dynamic> json) => _$OtherFromJson(json);
}
```

**違いと間違えやすいところ:**

- 層が違う点に注意してください。Swift の `JSONDecoder` は Apple 標準で、Dart の標準（`dart:convert`）に当たる機能は手書きです。json_serializable は外部ライブラリで、ビルド時にコードを**生成**します。Swift は、`Decodable` の実装をコンパイラが合成し、キーの変換は**実行時**に `JSONDecoder` が行います。生成ファイルも `build_runner` もありません。
- 名前の変換ルールの置き場所が違います。json_serializable はクラス（または `build.yaml`）に書き、Swift は**デコーダー**に書きます。
- `convertFromSnakeCase` を使うときは、`CodingKeys` に `snake_case` の文字を書いてはいけません。変換後のキーと合わず `keyNotFound` になります。`CodingKeys` には変換**後**の名前（`frontDefault`）か、変換されないキー（ハイフン入り）だけを書きます。
- 現在の `PokemonListDTO` のキー（`count`、`next`、`previous`、`results`）には snake_case がないため、変換は今は効いていません。詳細取得（後の Issue）で使う前提です。
- json_serializable には `FieldRename.kebab` もあり、ハイフン入りを一括変換できます。Swift の `JSONDecoder` には、これに当たる組み込みの戦略がありません。

**出典:**

- [JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase（Apple）](https://developer.apple.com/documentation/foundation/jsondecoder/keydecodingstrategy/convertfromsnakecase)
- [JSONDecoder（Apple）](https://developer.apple.com/documentation/foundation/jsondecoder)
- [json_serializable](https://pub.dev/packages/json_serializable)
- [FieldRename（json_annotation）](https://pub.dev/documentation/json_annotation/latest/json_annotation/FieldRename.html)

### URLSession（2xx 以外でも投げない）

**何の話か:** HTTP で通信してレスポンスを受け取る、Apple 標準の部品です。

**意味:** `URLSession.data(for:)` は、サーバーが 404 や 500 を返しても**投げません**。`(Data, URLResponse)` を返すので、ステータスは自分で調べます。通信自体ができなかったとき（圏外など）だけ `URLError` を投げます。そこで共通の GET で、2xx 以外を `PokeAPIError.httpStatus` に変えています。リクエストの組み立てには、swift-http-types の `HTTPRequest` を使っています。

**Swift のコード:** [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift)

```swift
let request = HTTPRequest(method: .get, scheme: "https", authority: "pokeapi.co", path: path)
let (data, response) = try await session.data(for: request)
guard (200..<300).contains(response.status.code) else {
    throw PokeAPIError.httpStatus(response.status.code)
}
```

**Dart のコード:** 標準に近い層は `package:http`（`dart:io` の `HttpClient` の上の薄い層）です。

```dart
final response = await client.get(
  Uri.https('pokeapi.co', '/api/v2/pokemon', {'limit': '$limit', 'offset': '$offset'}),
);
if (response.statusCode < 200 || response.statusCode >= 300) {
  throw HttpStatusException(response.statusCode); // 自分で定義した例外
}
```

**違いと間違えやすいところ:**

- この点は Swift と Dart で同じです。`package:http` の `client.get` も `dart:io` の `HttpClient` も、404 や 500 では投げません。`http.read` のような一部の関数だけが `ClientException` を投げます。「2xx 以外で投げる」のは Dio の既定の挙動で、標準の挙動ではありません。
- `data(for:)` の返り値の `URLResponse` は、通常は `HTTPURLResponse` にキャストして `statusCode` を読みます。このリポジトリは swift-http-types の拡張を使い、`HTTPResponse`（`response.status.code`）で受け取っています。
- `URLSessionConfiguration.default` で作った session は、`URLSession.shared` とは別の設定とキャッシュを持てます。このリポジトリは API 専用の session を作り、`URLCache.shared` を書き換えていません。

**出典:**

- [URLSession（Apple）](https://developer.apple.com/documentation/foundation/urlsession)
- [swift-http-types](https://github.com/apple/swift-http-types)
- [package:http](https://pub.dev/packages/http)
- [http.read（ClientException）](https://pub.dev/documentation/http/latest/http/read.html)
- [HttpClient（dart:io）](https://api.dart.dev/stable/dart-io/HttpClient-class.html)

### URLCache

**何の話か:** 同じ通信をやり直さなくて済むように、レスポンスを覚えておく仕組みです。

**意味:** `URLCache` は `URLSession` に標準で付いています。`requestCachePolicy = .useProtocolCachePolicy` にすると、サーバーが返す `cache-control` や `etag` に従って、保持するか、サーバーに確かめ直すかを決めます。自分で期限を管理する必要がありません。メモリ 20 MB、ディスク 200 MB を指定していて、理由はコードのコメントにあります。

**Swift のコード:** [PokeAPISession.swift](../../core/NetworkClientURLSession/Sources/PokeAPISession.swift)

```swift
configuration.urlCache = URLCache(
    memoryCapacity: PokeAPICacheConfiguration.memoryCapacity,
    diskCapacity: PokeAPICacheConfiguration.diskCapacity
)
configuration.requestCachePolicy = .useProtocolCachePolicy
```

**Dart のコード:** 標準の層（`dart:io`、`package:http`）には、`cache-control` に従う HTTP キャッシュが見当たりません。相当するコードはありません。

**違いと間違えやすいところ:**

- 標準どうしでは「相当なし」です。Dart / Flutter で同じ役目を担うのは外部パッケージで、層が違うため、ここでは比べません。
- 1 件のレスポンスがディスク容量のおよそ 5% を超えるとキャッシュされない、という上限は、コードのコメントを根拠にしています。このノートでは Apple の公式ページから確認できていません。200 MB は、この条件に収まるように決めています。
- キャッシュは `Caches` ディレクトリに置かれ、OS が必要に応じて消します。「消えない保存先」ではないので、オフライン保存は別の仕組み（#18）です。
- Flutter の `Image.network` が持つ画像のキャッシュ（メモリ上の `ImageCache`）とは別物です。こちらは通信全般の HTTP レスポンスの層です。

**出典:**

- [URLCache（Apple）](https://developer.apple.com/documentation/foundation/urlcache)
- [NSURLRequest.CachePolicy.useProtocolCachePolicy](https://developer.apple.com/documentation/foundation/nsurlrequest/cachepolicy/useprotocolcachepolicy)
- [Accessing cached data（Apple）](https://developer.apple.com/documentation/foundation/accessing-cached-data)
- [ImageCache（Flutter）](https://api.flutter.dev/flutter/painting/ImageCache-class.html)

### URLProtocol のスタブ

**何の話か:** テストで、本物の通信をせずに決まったレスポンスを返す方法です。

**意味:** `URLProtocol` は、`URLSession` が通信を処理する部分を差し替えるための仕組みです。サブクラスを作って `URLSessionConfiguration.protocolClasses` に登録すると、その session のリクエストがそのクラスに流れてきます。そこでテストが用意したレスポンスや `URLError` を返せば、アプリ側のコードを変えずに本物の通信を避けられます。例えるなら、郵便局の窓口に偽の配達員を座らせるイメージです。

**Swift のコード:** [NetworkClientURLSessionTests.swift](../../core/NetworkClientURLSession/Tests/NetworkClientURLSessionTests.swift)

```swift
let configuration = URLSessionConfiguration.ephemeral
configuration.protocolClasses = [StubURLProtocol.self]
return PokeAPIClient.live(session: URLSession(configuration: configuration))
```

**Dart のコード:** `package:http` の `MockClient` が近いです。

```dart
final client = MockClient((request) async {
  return http.Response(listJson, 200);
});
final api = PokeApiClient.live(client);
```

**違いと間違えやすいところ:**

- `MockClient` は `http.Client` そのものを丸ごと差し替えます。`URLProtocol` は `URLSession` の**内側**の通信処理だけを差し替えるので、`URLSession` を通る部分は本物のまま動きます。
- `URLProtocol` は継承して複数のメソッド（`canInit`、`startLoading`、`stopLoading` など）を上書きします。`MockClient` は関数 1 つで済みます。
- session に登録するのはインスタンスではなく**クラス**で、インスタンスは `URLSession` が作ります。そのためテストごとのレスポンスは static な置き場に入れるしかなく、テストを並列に走らせると設定が競合します。このリポジトリは `@Suite(.serialized)` と `Mutex` で対処しています。
- このテストは `ephemeral` の設定（キャッシュなし）を使っているので、`URLCache` の動きは確かめていません。キャッシュの設定値は別のテスト（容量が 5% に収まるか）で確かめています。

**出典:**

- [URLProtocol（Apple）](https://developer.apple.com/documentation/foundation/urlprotocol)
- [URLSessionConfiguration.protocolClasses](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/protocolclasses)
- [MockClient（package:http）](https://pub.dev/documentation/http/latest/testing/MockClient-class.html)

### Mutex

**何の話か:** 複数の処理が同じ値を同時に触らないよう、順番待ちさせる鍵です。

**意味:** `Mutex<Value>` は値を鍵の中に閉じ込め、`withLock` のあいだだけ 1 つの処理が触れます。`Synchronization` モジュールにあり、`Sendable` です。ここでは、テストが共有する static なハンドラと、リクエスト URL の記録に使っています。例えるなら、1 人用の個室です。使っている間は他の人は待ちます。

**Swift のコード:** [NetworkClientURLSessionTests.swift](../../core/NetworkClientURLSession/Tests/NetworkClientURLSessionTests.swift)

```swift
private static let handler = Mutex<Handler?>(nil)

static func setHandler(_ newHandler: Handler?) {
    handler.withLock { $0 = newHandler }
}
```

**Dart のコード:** 普段は要りません。

```dart
Handler? handler; // 説明用。1 つの isolate の中では、普通に代入しても競合しない
void setHandler(Handler? newHandler) => handler = newHandler;
```

**違いと間違えやすいところ:**

- Dart は isolate 内で 1 本のスレッドなので、`await` をまたがない同期コードは他の処理に割り込まれません。値を共有して書き換えても競合しません。Swift はスレッドが同時に動くので、共有する可変な値には保護が要ります。
- 補足: Swift 6 の言語モードは、保護のない共有可変状態（static な `var` など）をコンパイルエラーにします。`Mutex` に入れると、`Sendable` として通ります。
- `withLock` の中は同期のコードだけです。`await` をまたぐ共有状態には `actor` を使いますが、この Issue では出てきません。
- `Mutex` は iOS 18 以降で使えます（このリポジトリの対象は iOS 26）。

**出典:**

- [Mutex（Apple、Synchronization）](https://developer.apple.com/documentation/synchronization/mutex)
- [Concurrency（The Swift Programming Language）](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Dart の concurrency](https://dart.dev/language/concurrency)

### Swift Testing（#expect(throws:)、arguments、@Suite(.serialized)）

**何の話か:** Swift のテストの書き方です。XCTest の代わりに、新しい Swift Testing を使っています。

**意味:** `@Test` を付けた関数がテストで、`#expect` が検証です。`#expect(throws:)` は「この処理が指定のエラーを投げること」を確かめます。`arguments:` を付けると、値ごとに同じテストを繰り返し、結果は値ごとに別々に表示されます。`@Suite(.serialized)` は、そのスイートのテストを 1 つずつ順番に走らせます（既定は並列）。

**Swift のコード:** [NetworkClientURLSessionTests.swift](../../core/NetworkClientURLSession/Tests/NetworkClientURLSessionTests.swift)

```swift
@Suite(.serialized)
struct NetworkClientURLSessionTests {
    @Test("成功以外のステータスはPokeAPIErrorになる", arguments: [404, 500])
    func nonSuccessStatusThrowsPokeAPIError(status: Int) async {
        let client = makeClient { request in
            (Self.response(for: request, status: status), Data("{}".utf8))
        }

        await #expect(throws: PokeAPIError.httpStatus(status)) {
            try await client.fetchPokemonList(20, 0)
        }
    }
}
```

**Dart のコード:**

```dart
void main() {
  for (final status in [404, 500]) {
    test('2xx 以外のステータスは HttpStatusException になる ($status)', () async {
      final client = makeClient((request) async => http.Response('{}', status));

      await expectLater(
        client.fetchPokemonList(20, 0),
        throwsA(isA<HttpStatusException>().having((e) => e.status, 'status', status)),
      );
    });
  }
}
```

**違いと間違えやすいところ:**

- 検証の書き方が違います。Dart は `expect(実際の値, マッチャー)` で、マッチャーを組み合わせます。Swift Testing は普通の Swift の式を `#expect(a == b)` と書きます。
- Dart のパラメータ化は、`for` で `test` を並べる書き方（自分で書く）です。Swift Testing の `arguments:` は機能として組み込まれています。
- 並列の単位に注意が要ります。Swift Testing は同じスイートの中のテストも既定で並列に走るので、static な共有状態（スタブのハンドラ）を使うスイートには `.serialized` が要ります。
- `#expect(throws:)` は、投げられたエラーを戻り値で受け取れます（`let error = await #expect(throws: URLError.self) {...}`）。種類を確かめたあと、中身（`code`）を別の `#expect` で確かめられます。
- `@Test("…")` の文字列は表示名で、日本語で書けます。

**出典:**

- [Swift Testing（Apple）](https://developer.apple.com/documentation/testing)
- [Expectations and confirmations](https://developer.apple.com/documentation/testing/expectations)
- [Implementing parameterized tests](https://developer.apple.com/documentation/testing/parameterizedtesting)
- [Trait.serialized](https://developer.apple.com/documentation/testing/trait/serialized)
- [package:test](https://pub.dev/packages/test)

---

## Swift の外部ライブラリとツールチェーン

### swift-dependencies と swift-http-types

**何の話か:** 「差し替えられる部品の渡し方」と「HTTP の共通の型」を、外部ライブラリどうしでそろえる話です。

**意味:** swift-dependencies は、`@Dependency` で部品を取り出し、`withDependencies` でテストごとに差し替えます。swift-http-types は Apple が出している `HTTPRequest` / `HTTPResponse` / `HTTPFields` の型で、HTTPTypesFoundation が `URLSession` との橋渡しを持ちます。

**Swift のコード:** [PokemonRepository.swift](../../core/Repository/Sources/PokemonRepository.swift)、[RepositoryTests.swift](../../core/Repository/Tests/RepositoryTests.swift)

```swift
// 使う側
@Dependency(\.pokeAPIClient) var client
let dto = try await client.fetchPokemonList(limit, offset)

// テスト側
try await withDependencies {
    $0.pokeAPIClient.fetchPokemonList = { _, _ in dto }
} operation: {
    try await PokemonRepository.liveValue.fetchList(limit: 20, offset: 0)
}
```

**Dart のコード:** Riverpod（外部ライブラリどうし）で書くと次の形です。

```dart
final pokeApiClientProvider = Provider<PokeApiClient>((ref) => PokeApiClient.live());

final container = ProviderContainer(overrides: [
  pokeApiClientProvider.overrideWithValue(FakePokeApiClient()),
]);
```

**違いと間違えやすいところ:**

- Riverpod は `ref` を通じて**コンテナ**から読みます。swift-dependencies は `ref` のようなものを持たず、`@Dependency` が**現在の実行の文脈（task-local）**から値を取ります。そのため、テストでは `withDependencies { ... } operation: { ... }` の範囲の中だけ差し替えが効きます。
- Riverpod の `Provider` は、値の寿命や再計算も管理します。swift-dependencies は値の取り出しと差し替えが役目で、状態の持ち方は別の仕組みです。
- swift-http-types は型だけを提供し、通信はしません。Dart で近い役目の型は `package:http` の `Request` / `Response` ですが、これらは通信ライブラリの一部で、型だけが単独で提供されるわけではない点が違います。
- 対応表は別のドキュメントにあります。[Flutter のよく使うパッケージとの対応](../package-dependencies.md#flutter-のよく使うパッケージとの対応)と、[採用ライブラリの一覧](../package-dependencies.md#採用)にあるので、ここには写しません。なお Dio は標準の層ではなく外部ライブラリなので、`URLSession` のような標準の比較には使いません。
- 依存の向きと DI の方針は [dependency-injection.md](../dependency-injection.md) を参照してください。

**出典:**

- [swift-dependencies](https://github.com/pointfreeco/swift-dependencies)
- [swift-http-types](https://github.com/apple/swift-http-types)
- [Riverpod（Testing）](https://riverpod.dev/docs/essentials/testing)

### テスト target の依存

**何の話か:** テストが使うモジュールを、Package.swift でどこまで書く必要があるかの話です。

**意味:** Swift のテスト target は、テスト対象のモジュールだけでなく、テストコードが `import` するものを、自分の `dependencies` に列挙します。このリポジトリの `RepositoryTests` は、`withDependencies` を使うために `Dependencies` を自分で加えています。

**Swift のコード:** [Package.swift](../../Package.swift)

```swift
.testTarget(
    name: "RepositoryTests",
    dependencies: [
        "Repository", "NetworkClient", "Model", "TestSupport",
        .product(name: "Dependencies", package: "swift-dependencies"),
    ],
    path: "core/Repository/Tests"
),
```

**Dart のコード:**

```yaml
# pubspec.yaml
dev_dependencies:
  test: ^1.25.0
```

**違いと間違えやすいところ:**

- Dart は 1 つのパッケージに `dependencies` と `dev_dependencies` の 2 つがあり、`test/` はパッケージ全体の依存を使えます。Swift は **target ごと**に依存を書くので、テスト target ごとに明示が要ります。
- 書き忘れると、`import` の行でモジュールが見つからないエラーになります。
- テスト target を足したときに `app/AllTests.xctestplan` へ登録する作業は、[issue-02-package-structure.md](issue-02-package-structure.md) を参照してください。
- 依存のルールは [package-dependencies.md](../package-dependencies.md) にあります。

**出典:**

- [Target（PackageDescription）](https://developer.apple.com/documentation/packagedescription/target)
- [Dart の dependencies（dev dependencies）](https://dart.dev/tools/pub/dependencies#dev-dependencies)

---

## 早見表

表の書き方は [README](README.md#表の書き方) に従います。

| Swift / iOS | Dart / Flutter での相当 | 違い | このリポジトリで使っている場所 |
| --- | --- | --- | --- |
| `struct`（値型）と入れ子の型 | `class`（参照型）。入れ子は書けないので外に並べる | コピーされるので別の場所から書き換わらない。`public struct` は `public init` を書く | [PokemonListDTO.swift](../../core/NetworkClient/Sources/PokemonListDTO.swift) |
| `enum`（関連値あり） | `sealed class` | Dart の `enum` は case ごとに別の値を持てない | [PokeAPIError.swift](../../core/NetworkClient/Sources/PokeAPIError.swift)、[LoadError.swift](../../core/Model/Sources/LoadError.swift) |
| `extension` | extension methods | Swift はプロトコル準拠も足せる。Dart はインターフェースの実装を足せない | [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift) |
| `static let` | `static final` / トップレベルの `final` | 実行時に 1 回だけ初期化される。`static const` はコンパイル時定数 | [PokeAPISession.swift](../../core/NetworkClientURLSession/Sources/PokeAPISession.swift) |
| `get<Response: Decodable>(_ type: Response.Type)` | `get<T>(fromJson)` | 型から `init(from:)` を呼べるので、型を渡すだけで済む | [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift) |
| `Equatable` / `Hashable` / `Identifiable` / `Codable` の自動準拠 | 言語では手書き。外部ライブラリなら freezed + json_serializable | 言語が合成するので生成ファイル不要。全プロパティが準拠済みのときだけ合成される | [PokemonSummary.swift](../../core/Model/Sources/PokemonSummary.swift) |
| `Sendable` / `@Sendable` | 相当なし（isolate 内は 1 本のスレッド） | 同時に触っても安全かをコンパイラが検査する | [PokeAPIClient.swift](../../core/NetworkClient/Sources/PokeAPIClient.swift) |
| `public` / `internal` / `private`、`@testable import` | `_`、`lib/src`、`@visibleForTesting` | 単位は Swift がモジュール、Dart がファイル。`@visibleForTesting` は警告だけ | [NetworkClientURLSessionTests.swift](../../core/NetworkClientURLSession/Tests/NetworkClientURLSessionTests.swift) |
| `throws` / `try` / `any Error` / `do-catch` | `throw` / `try-catch` | Swift は `throws` が型に入る。キャンセルは `CancellationError`、Dart の `Future` に標準のキャンセルはない | [PokemonRepository.swift](../../core/Repository/Sources/PokemonRepository.swift) |
| マクロ（`@DependencyClient`） | 言語には相当なし。外部ツールの build_runner が近い | マクロはコンパイル中に展開され、生成ファイルが残らない | [PokeAPIClient.swift](../../core/NetworkClient/Sources/PokeAPIClient.swift) |
| `JSONDecoder` + `.convertFromSnakeCase` | 標準（`dart:convert`）は手書き。外部ライブラリなら json_serializable の `fieldRename: snake` | 実行時にデコーダーが変換する。ハイフン入りのキーだけ `CodingKeys` | [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift) |
| `URLSession`（`data(for:)`） | `package:http`（`dart:io` の `HttpClient`） | どちらも 2xx 以外で投げない。Dio は投げる（層が違う） | [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift) |
| `URLCache` | 標準には相当なし | `cache-control` と `etag` に従う | [PokeAPISession.swift](../../core/NetworkClientURLSession/Sources/PokeAPISession.swift) |
| `URLProtocol` のスタブ | `MockClient`（package:http） | `URLSession` の内側だけを差し替える。static な設定が要るので並列に弱い | [NetworkClientURLSessionTests.swift](../../core/NetworkClientURLSession/Tests/NetworkClientURLSessionTests.swift) |
| `Mutex` | 相当なし（isolate 内は 1 本のスレッド） | 共有する可変な値を保護する。`withLock` の中で `await` できない | [NetworkClientURLSessionTests.swift](../../core/NetworkClientURLSession/Tests/NetworkClientURLSessionTests.swift) |
| Swift Testing（`#expect(throws:)`、`arguments:`、`.serialized`） | `package:test`（`expect`、`throwsA`、`for` で `test` を並べる） | `#expect` は普通の式を書く。同じスイートの中も既定で並列 | [NetworkClientURLSessionTests.swift](../../core/NetworkClientURLSession/Tests/NetworkClientURLSessionTests.swift) |
| swift-dependencies | Riverpod の overrides（外部どうし） | 現在の実行の文脈から値を取る。寿命は管理しない | [PokemonRepository.swift](../../core/Repository/Sources/PokemonRepository.swift) |
| swift-http-types | `package:http` の `Request` / `Response`（型の部分） | 型だけで通信はしない | [PokeAPIClient+Live.swift](../../core/NetworkClientURLSession/Sources/PokeAPIClient+Live.swift) |
| テスト target の `dependencies` | `dev_dependencies` | target ごとに自分で列挙する | [Package.swift](../../Package.swift) |
