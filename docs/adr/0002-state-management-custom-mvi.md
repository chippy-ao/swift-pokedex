# ADR-0002: 状態管理に自作 MVI を採用する

- ステータス: 承認済み
- 日付: 2026-10-27

## コンテキスト

学習目的は、モダン Swift(Swift 6 strict concurrency、Observation、SwiftData、Swift Testing、NavigationStack)の総復習です。開発者は Flutter(BLoC、Riverpod)、React の useReducer、Kotlin の MVI で単方向データフローに慣れています。iOS では `@Observable` を使った MVVM が事実上の主流で、TCA(The Composable Architecture)は中〜大規模で一定の採用があります(国内では Ameba の事例)。

## 決定

自作の MVI を採用します。TCA は採用しません。

- 画面ごとに `State`(struct)、`Action`(関連値つき enum)、`Store`(`@MainActor @Observable final class`)を用意します。
- `Store` は `private(set) var state` と `func send(_ action:)` を持ち、`send` の中で `switch` して state を更新します。
- 非同期処理は `send` の中で `Task` を起動し、結果を `.response(...)` のような Action として `send` し直します。
- 親に伝えるイベントは `.delegate(...)` ケースにまとめます。
- 依存は `@Dependency` で受け取ります([ADR-0004](0004-dependency-injection.md))。

```swift
// 例(方針を示すための抜粋)
@MainActor @Observable
final class CounterStore {
    struct State: Equatable { var count = 0 }
    enum Action { case increment, decrement }

    private(set) var state = State()

    func send(_ action: Action) {
        switch action {
        case .increment: state.count += 1
        case .decrement: state.count -= 1
        }
    }
}
```

Flutter / Kotlin / React との対応は次のとおりです。

| 他の世界 | このプロジェクト |
| --- | --- |
| BLoC の Event / MVI の Intent / useReducer の action | Action |
| BLoC の State / Kotlin の data class | State(値型の struct なので直接書き換えてよい) |
| reducer / BLoC の `on<Event>` | `send` 内の `switch` |
| SideEffect | `Task` で起動する非同期処理 |

## 理由

- TCA は 2026 年 10 月時点で 1.26.x で、2.0 への移行期です。1.25〜1.26 で 2.0 準備のための deprecation が多数入っており、書き方が変わるリスクがあります。
- 素の Swift(Concurrency / Observation)を学ぶ目的に対して、TCA は抽象化が厚いです。
- 単方向データフローに慣れているため、ViewModel にメソッドを生やす MVVM より MVI が合います。
- 自作 MVI は見た目が `send(action)` を持つ ViewModel なので MVVM の開発者にも通じます。考え方は TCA と同じなので、将来 TCA へ移るのも容易です。

## 検討した代替案

| 案 | 不採用理由 |
| --- | --- |
| MVVM(`@Observable` の ViewModel にメソッドを生やす) | 主流で手堅いが、状態遷移が分散する。単方向データフローに慣れた開発者には MVI の方が追いやすい |
| TCA | 上記のとおり 2.0 移行期で書き方が変わるリスクがあり、学習目的に対して抽象化が厚い |
| 自作 Store(採用) | 学習目的に合い、TCA への移行も容易 |

## 影響

### 良い点

- 状態遷移が `send` の `switch` に集約され、テストしやすい。
- Observation の追跡(読んだプロパティだけ再描画)を直接学べる。

### 悪い点・注意点

- 検索の debounce やキャンセルは Store が `Task` を保持して `cancel` する必要があり、自前で書く。
- `send` が `Task<Void, Never>?` を返してテストで `await store.send(.onAppear)?.value` と待つ形は初期方針で、実装しながら見直す。
- 任意で、後から 1 画面だけ TCA で書き直して比較する(Phase 6)。

## 参考リンク

- [TCA releases](https://github.com/pointfreeco/swift-composable-architecture/releases)
- [Apple Observation](https://developer.apple.com/documentation/observation)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
