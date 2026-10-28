# PokedexFeature

> このドキュメントは生きた仕様書です。コードを変更する PR と同じ PR で更新します。

## 概要と責務

図鑑ドメインの画面をまとめる feature モジュールです。一覧、詳細、お気に入りを担当します。お気に入りは図鑑ドメインなので、独立した feature にせずここに含めています。

- 画面の State / Action / Store / View を持つ
- 図鑑内の画面遷移(Route と `navigationDestination`)を提供する
- データ取得は必ず [Domain](../../docs/architecture.md) の UseCase 経由で行う

全体の設計は [docs/architecture.md](../../docs/architecture.md)、依存ルールは [docs/package-dependencies.md](../../docs/package-dependencies.md)、DI の書き方は [docs/dependency-injection.md](../../docs/dependency-injection.md) を参照してください。

## 依存してよいモジュール

| 依存先 | 用途 |
| --- | --- |
| Domain | UseCase の呼び出し |
| SharedUI | PokemonCard、PokemonRow など |
| DesignSystem | テーマ、タイプバッジ、RemoteImage |
| Model | Entity |
| Common | 共通ユーティリティ、エラー型 |
| Dependencies | `@Dependency` で UseCase を受け取る |

依存してはいけないもの。

- Repository / NetworkClient / Database / Datastore(必ず UseCase 経由)
- 実装モジュール(NetworkClientURLSession、DatabaseSwiftData、DatastoreUserDefaults)
- 他の feature(SettingsFeature を含む)

テーマ色は SettingsFeature に依存せず、Environment から読むだけです。

## 画面一覧とフォルダ構成

| 画面 | フォルダ | 概要 |
| --- | --- | --- |
| List | `Sources/List` | 一覧、無限スクロール、検索、タイプフィルタ |
| Detail | `Sources/Detail` | 画像、タイプ、ステータス、説明文、進化チェーン、お気に入り切り替え |
| Favorites | `Sources/Favorites` | お気に入り一覧 |

```text
feature/PokedexFeature/
├─ README.md
├─ Sources/
│   ├─ List/
│   ├─ Detail/
│   ├─ Favorites/
│   └─ PokedexRoute.swift    … feature 内の Route(配置は実装時に決める)
└─ Tests/
```

画面ごとに State(struct)、Action(enum)、Store(`@MainActor @Observable final class`)、View を持ちます。MVI の基本形は [docs/architecture.md](../../docs/architecture.md) を参照してください。

## 画面遷移

遷移は feature 内で完結します。AppShared がタブごとに持つ NavigationStack と Router(path を保持)に対し、PokedexFeature が Route と `navigationDestination` を提供します。

```mermaid
flowchart LR
    List -->|"Route.detail(id)"| Detail
    Favorites -->|"Route.detail(id)"| Detail
    Detail -->|"進化チェーンのタップ(Phase 5)"| Detail
```

Route の例です(名前は仮)。

```swift
enum PokedexRoute: Hashable {
    case detail(id: Int)
}
```

feature をまたぐ遷移は現時点ではありません。必要になったら delegate Action(例: `.delegate(.selectPokemon(id))`)を AppShared の Router が受け取ります。

## 画面仕様

以降の State / Action / UseCase 名は案です。実装しながら見直します。

### List

| 項目 | 内容 |
| --- | --- |
| 表示項目 | 画像、ID、名前、タイプ(取得できる範囲) |
| 操作 | 末尾付近までスクロールで次ページ取得、行タップで Detail へ、検索欄への入力、タイプフィルタの選択 |
| PokeAPI | `GET /pokemon?limit=&offset=`(ページング)、`GET /pokemon/{id or name}`(行にタイプ等を出す場合)、`GET /type/{name}`(タイプフィルタ) |
| UseCase 案 | `FetchPokemonPageUseCase`、`FetchAllPokemonNamesUseCase`、`FetchPokemonByTypeUseCase` |

ページングは limit / offset 方式で、1ページのデフォルトは 20 件です。ID は `results` の url 末尾から取り出します。名前検索の API は無いため、全件の名前リスト(limit を count 以上にして1回取得)をキャッシュし、ローカルで絞り込みます。

State / Action の案です。

```swift
struct PokemonListState: Equatable {
    var items: [PokemonSummary] = []
    var phase: Phase = .idle          // idle / loading / loaded / failed
    var hasNext = true
    var query = ""
    var selectedType: PokemonType?
}

enum PokemonListAction {
    case onAppear
    case reachedBottom
    case pageResponse(Result<PokemonPage, any Error>)
    case queryChanged(String)
    case typeSelected(PokemonType?)
    case retryTapped
    case rowTapped(id: Int)
    case delegate(Delegate)
    enum Delegate { case selectPokemon(id: Int) }
}
```

検索の debounce は Store が Task を保持して cancel します(`Task.sleep` を使用)。

| 状態 | 表示 |
| --- | --- |
| 読み込み中(初回) | 全面の ProgressView |
| 読み込み中(次ページ) | リスト末尾に ProgressView |
| 空(検索・フィルタの結果なし) | 「該当するポケモンがいません」と条件のクリア導線 |
| エラー(初回) | エラーメッセージと再試行ボタン |
| エラー(次ページ) | 末尾に再試行行。取得済みの一覧は維持する |

### Detail

| 項目 | 内容 |
| --- | --- |
| 表示項目 | 公式アートワーク、ID、名前、タイプ、ステータス、説明文(Phase 5)、進化チェーン(Phase 5) |
| 操作 | お気に入りの追加・削除(Phase 3)、進化チェーンのタップで別のポケモンの Detail へ(Phase 5) |
| PokeAPI | `GET /pokemon/{id or name}`(types、stats、sprites)、`GET /pokemon-species/{id}`(names、flavor_text_entries、evolution_chain.url)、`GET /evolution-chain/{id}` |
| UseCase 案 | `FetchPokemonDetailUseCase`、`FetchPokemonSpeciesUseCase`、`FetchEvolutionChainUseCase`、`ToggleFavoriteUseCase`、`ObserveIsFavoriteUseCase` |

公式アートワークは `sprites.other["official-artwork"].front_default` から取得します。ID が 10000 を超えるものはフォーム違いなどの pokemon です。species は Phase 5 まで取得しません。

```swift
struct PokemonDetailState: Equatable {
    var detail: PokemonDetail?
    var phase: Phase = .idle
    var isFavorite = false
}

enum PokemonDetailAction {
    case onAppear
    case detailResponse(Result<PokemonDetail, any Error>)
    case favoriteTapped
    case favoriteChanged(Bool)
    case retryTapped
}
```

| 状態 | 表示 |
| --- | --- |
| 読み込み中 | 全面の ProgressView |
| エラー | エラーメッセージと再試行ボタン |
| 説明文・進化チェーンが無い、または取得失敗 | そのセクションだけ非表示にし、画面全体は表示する(方針案) |

### Favorites

| 項目 | 内容 |
| --- | --- |
| 表示項目 | お気に入りに追加したポケモンの一覧(画像、ID、名前) |
| 操作 | 行タップで Detail へ、スワイプまたは Detail 内でお気に入り解除 |
| PokeAPI | 保存済みの情報で足りない分は `GET /pokemon/{id}`(HTTP キャッシュが効く) |
| UseCase 案 | `ObserveFavoritesUseCase`(AsyncStream)、`ToggleFavoriteUseCase` |

View で `@Query` は使いません。Database interface 経由で fetch 関数または AsyncStream として受け取ります([docs/data-layer.md](../../docs/data-layer.md) 参照)。

```swift
struct FavoritesState: Equatable {
    var items: [PokemonSummary] = []
    var phase: Phase = .idle
}

enum FavoritesAction {
    case onAppear
    case favoritesChanged([PokemonSummary])
    case removeTapped(id: Int)
    case rowTapped(id: Int)
}
```

| 状態 | 表示 |
| --- | --- |
| 読み込み中 | ProgressView |
| 空 | 「お気に入りはまだありません」と図鑑タブへの案内 |
| エラー | エラーメッセージと再試行ボタン |

## 実装フェーズ

フェーズ一覧と進捗は [GitHub Milestones](https://github.com/chippy-ao/swift-pokedex/milestones) で管理します。この feature に関わる範囲は次のとおりです。

| フェーズ | この feature の内容 |
| --- | --- |
| Phase 1 | List と Detail の基本(ページング、無限スクロール、画像、タイプ、ステータス) |
| Phase 2 | 検索(名前、ローカル絞り込み)とタイプフィルタ |
| Phase 3 | お気に入り(Detail での切り替え、Favorites 画面) |
| Phase 5 | ローカライズ名、説明文、進化チェーン、オフラインキャッシュ対応 |

Phase 5 のローカライズでは、`Bundle.main.preferredLocalizations.first` を PokeAPI の言語コード(ja は ja-hrkt、en は en)に変換し、該当言語の名前が無ければ en にフォールバックします。この処理は Domain の UseCase で行い、feature 側は変換済みの Model を受け取ります。

## 未決事項

- 日本語名での検索方式。全 species の名前が必要になるため、Phase 5 で方式を検討する(要調査)
- 一覧での日本語名表示のタイミング。一覧の `results` には名前(英語の識別子)しか無く、ローカライズ名には species の取得が必要。一覧で表示するか、Detail のみにするかは実装時に決める
- 一覧の行にタイプを出すか。出す場合は行ごとに詳細取得が必要になり、リクエスト数が増える。PokeAPI の Fair Use Policy を踏まえて決める
- タイプフィルタと名前検索を同時に使ったときの組み合わせ(AND にする想定だが実装時に確認する)
- Detail の説明文に使う flavor_text のバージョン選択
- フォーム違い(ID 10000 超)を一覧に含めるか
